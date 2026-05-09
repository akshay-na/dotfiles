#!/usr/bin/env bash
# telemetry-post-tool.sh
#
# postToolUse audit hook. Records a tool-call completion event with
# duration_ms (computed against the pending entry seeded by preToolUse).
#
# Returns no permission/output fields; postToolUse only supports
# `additional_context`, which we don't need.
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
tool_name="$(printf '%s' "$input" | telemetry_extract_tool_name)"
tool_call_id="$(printf '%s' "$input" | telemetry_extract_tool_call_id)"
workspace_root="$(printf '%s' "$input" | telemetry_extract_workspace_root)"
ws_san="$(telemetry_sanitize_path "$workspace_root")"

# Try to recover the pending entry to compute duration_ms.
pending="$(telemetry_pop_pending_tool "$session_id" "$tool_call_id" "$tool_name")"
duration_ms=0
recovered_tool=""
recovered_call_id=""
if [ -n "$pending" ]; then
  recovered_tool="${pending%%|*}"
  rest="${pending#*|}"
  started_ms="${rest%%|*}"
  recovered_call_id="${rest#*|}"
  if [ -n "$started_ms" ]; then
    now_ms="$(telemetry_now_ms)"
    duration_ms=$((now_ms - started_ms))
    [ "$duration_ms" -lt 0 ] && duration_ms=0
  fi
fi
[ -z "$tool_call_id" ] && tool_call_id="$recovered_call_id"
[ -z "$tool_name" ] && tool_name="$recovered_tool"

# Detect basic outcome from postToolUse input. Cursor versions vary:
# .tool_response.success, .toolResult.is_error, .result.error, etc.
outcome="success"
err_class=""
if printf '%s' "$input" | jq -e '.tool_response.error // .toolResponse.error // .tool_response.is_error // .toolResult.is_error // empty' >/dev/null 2>&1; then
  if [ "$(printf '%s' "$input" | jq -r '(.tool_response.error // .toolResponse.error // .tool_response.is_error // .toolResult.is_error // false)')" != "false" ]; then
    outcome="failure"
    err_class="$(printf '%s' "$input" | jq -r '(.tool_response.error.type // .toolResponse.error.type // .tool_response.error_type // empty)' 2>/dev/null)"
  fi
fi

summary_raw="$(printf '%s' "$input" | jq -r '(.tool_response.summary // .toolResponse.summary // .summary // empty)' 2>/dev/null)"
summary_san="$(telemetry_truncate "$summary_raw" "$TELEMETRY_SUMMARY_CAP_CHARS")"
summary_san="$(printf '%s' "$summary_san" | telemetry_redact)"
[ -z "$summary_san" ] && summary_san="tool=$tool_name outcome=$outcome"

extra="$(jq -nc \
  --arg tool_name "$tool_name" \
  --arg tool_call_id "$tool_call_id" \
  --arg outcome "$outcome" \
  --arg err_class "$err_class" \
  --arg ws "$ws_san" \
  --arg summary "$summary_san" \
  --argjson duration_ms "$duration_ms" \
  '{
    outcome: $outcome,
    tool_name: (if ($tool_name|length) > 0 then $tool_name else null end),
    tool_call_id: (if ($tool_call_id|length) > 0 then $tool_call_id else null end),
    duration_ms: $duration_ms,
    error_class: (if ($err_class|length) > 0 then $err_class else null end),
    actor: { workspace_root: $ws },
    summary: $summary
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "postToolUse" "$session_id" "$extra"
exit 0
