#!/usr/bin/env bash
# telemetry-post-tool-failure.sh
#
# postToolUseFailure audit hook. Logs a tool-call failure event and clears the
# pending duration entry seeded by preToolUse.
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

pending="$(telemetry_pop_pending_tool "$session_id" "$tool_call_id" "$tool_name")"
duration_ms=0
recovered_call_id=""
if [ -n "$pending" ]; then
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

err_msg="$(printf '%s' "$input" | jq -r '
  .error.message //
  .error_message //
  .tool_response.error.message //
  .toolResponse.error.message //
  .errorString //
  .error //
  empty
' 2>/dev/null)"
err_class="$(printf '%s' "$input" | jq -r '
  .error.type //
  .error.code //
  .error_class //
  .tool_response.error.type //
  .toolResponse.error.type //
  empty
' 2>/dev/null)"

err_msg_san="$(telemetry_truncate "$err_msg" "$TELEMETRY_FIELD_CAP_CHARS")"
err_msg_san="$(printf '%s' "$err_msg_san" | telemetry_redact)"
[ -z "$err_msg_san" ] && err_msg_san="tool=$tool_name failed (no error message)"

extra="$(jq -nc \
  --arg tool_name "$tool_name" \
  --arg tool_call_id "$tool_call_id" \
  --arg outcome "failure" \
  --arg err_class "$err_class" \
  --arg ws "$ws_san" \
  --arg summary "$err_msg_san" \
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

[ -n "$extra" ] && telemetry_emit_event "postToolUseFailure" "$session_id" "$extra"
exit 0
