#!/usr/bin/env bash
# telemetry-subagent-stop.sh
#
# subagentStop audit hook. Records that a Task subagent finished and pairs it
# back to the subagentStart entry to compute duration_ms.
#
# subagentStop supports `followup_message`; we never use it — telemetry must
# stay decision-neutral.
#
# shellcheck disable=SC1091

set -u

__self="${BASH_SOURCE[0]}"
__real="$(realpath -q "$__self" 2>/dev/null || printf '%s' "$__self")"
__hooks_dir="$(dirname "$__real")"
# shellcheck source=./telemetry-common.sh
. "$__hooks_dir/telemetry-common.sh" 2>/dev/null || exit 0

trap 'exit 0' ERR

input="$(cat 2>/dev/null || true)"

session_id="$(printf '%s' "$input" | telemetry_extract_session_id)"
[ -z "$session_id" ] && session_id="nosession"
workspace_root="$(printf '%s' "$input" | telemetry_extract_workspace_root)"
ws_san="$(telemetry_sanitize_path "$workspace_root")"

subagent_type="$(printf '%s' "$input" | jq -r '
  .subagent_type //
  .subagentType //
  .agent //
  empty
' 2>/dev/null)"
agent_run_id="$(printf '%s' "$input" | jq -r '
  .run_id //
  .runId //
  .subagent_run_id //
  empty
' 2>/dev/null)"

# Recover agent_run_id from session cache when Cursor doesn't echo it back.
if [ -z "$agent_run_id" ] && [ -n "$subagent_type" ]; then
  dir="$(telemetry_session_cache_dir "$session_id")"
  cache_file="$dir/runs/last-$subagent_type"
  if [ -s "$cache_file" ]; then
    agent_run_id="$(cat "$cache_file" 2>/dev/null || true)"
  fi
fi

pending="$(telemetry_pop_pending_tool "$session_id" "$agent_run_id" "Task:$subagent_type")"
duration_ms=0
if [ -n "$pending" ]; then
  rest="${pending#*|}"
  started_ms="${rest%%|*}"
  if [ -n "$started_ms" ]; then
    now_ms="$(telemetry_now_ms)"
    duration_ms=$((now_ms - started_ms))
    [ "$duration_ms" -lt 0 ] && duration_ms=0
  fi
fi

# Outcome detection.
outcome="success"
err_class=""
if printf '%s' "$input" | jq -e '.error // .result.error // .stop_reason // empty' >/dev/null 2>&1; then
  stop_reason="$(printf '%s' "$input" | jq -r '(.stop_reason // empty)' 2>/dev/null)"
  case "$stop_reason" in
    error | cancelled | timeout | failure)
      outcome="failure"
      err_class="$stop_reason"
      ;;
  esac
fi

# Bounded byte counter for any final response length signal.
response_bytes="$(printf '%s' "$input" | jq -rc '
  ((.response // .final_message // .result // "") | tostring | length)
' 2>/dev/null)"
[ -z "$response_bytes" ] && response_bytes=0

extra="$(jq -nc \
  --arg subagent_type "$subagent_type" \
  --arg agent_run_id "$agent_run_id" \
  --arg outcome "$outcome" \
  --arg err_class "$err_class" \
  --arg ws "$ws_san" \
  --argjson duration_ms "$duration_ms" \
  --argjson response_bytes "$response_bytes" \
  '{
    outcome: $outcome,
    tool_name: "Task",
    subagent_type: (if ($subagent_type|length) > 0 then $subagent_type else null end),
    subagent_run_id: (if ($agent_run_id|length) > 0 then $agent_run_id else null end),
    duration_ms: $duration_ms,
    error_class: (if ($err_class|length) > 0 then $err_class else null end),
    counters: { response_bytes: $response_bytes },
    actor: { workspace_root: $ws },
    summary: ("subagent stop type=" + $subagent_type + " outcome=" + $outcome)
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "subagentStop" "$session_id" "$extra"
exit 0
