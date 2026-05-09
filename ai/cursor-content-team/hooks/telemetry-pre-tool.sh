#!/usr/bin/env bash
# telemetry-pre-tool.sh
#
# preToolUse audit hook. Records a tool-call start event and seeds a pending
# entry that postToolUse / postToolUseFailure use to compute duration_ms.
#
# Permission: always returns `permission: allow`. The hook is audit-only and
# never gates tool execution.
#
# shellcheck disable=SC1091

set -u

__self="${BASH_SOURCE[0]}"
__real="$(realpath -q "$__self" 2>/dev/null || printf '%s' "$__self")"
__hooks_dir="$(dirname "$__real")"
# shellcheck source=./telemetry-common.sh
. "$__hooks_dir/telemetry-common.sh" 2>/dev/null || { telemetry_emit_allow 2>/dev/null; exit 0; }

trap 'telemetry_emit_allow 2>/dev/null; exit 0' ERR

input="$(cat 2>/dev/null || true)"

session_id="$(printf '%s' "$input" | telemetry_extract_session_id)"
[ -z "$session_id" ] && session_id="nosession"
tool_name="$(printf '%s' "$input" | telemetry_extract_tool_name)"
tool_call_id="$(printf '%s' "$input" | telemetry_extract_tool_call_id)"
workspace_root="$(printf '%s' "$input" | telemetry_extract_workspace_root)"
ws_san="$(telemetry_sanitize_path "$workspace_root")"

# Path field, when the tool is a file op.
target_path="$(printf '%s' "$input" | jq -r '
  .tool_input.path //
  .tool_input.file_path //
  .tool_input.target_file //
  .tool_input.filePath //
  .tool_input.filename //
  empty
' 2>/dev/null)"
target_short=""
if [ -n "$target_path" ]; then
  target_short="$(telemetry_short_basename "$target_path")"
fi

# Subagent type, when tool == Task.
subagent_type=""
if [ "$tool_name" = "Task" ]; then
  subagent_type="$(printf '%s' "$input" | jq -r '.tool_input.subagent_type // .tool_input.agent // empty' 2>/dev/null)"
fi

now_ms="$(telemetry_now_ms)"
# Pairing strategy:
#   - If Cursor provides a tool_call_id, register against it so post can look
#     up by ID directly.
#   - Otherwise, push to the per-tool stack and let post pop the most-recent
#     matching tool. This is best-effort but works in single-threaded agent
#     execution where pre/post pairs are interleaved 1:1.
if [ -n "$tool_call_id" ]; then
  telemetry_register_pending_tool "$session_id" "$tool_call_id" "$tool_name" "$now_ms"
else
  telemetry_register_pending_tool "$session_id" "" "$tool_name" "$now_ms"
fi

summary="$(telemetry_truncate "tool=$tool_name path=$target_short subagent=$subagent_type" "$TELEMETRY_SUMMARY_CAP_CHARS")"
summary="$(printf '%s' "$summary" | telemetry_redact)"

extra="$(jq -nc \
  --arg tool_name "$tool_name" \
  --arg tool_call_id "$tool_call_id" \
  --arg subagent_type "$subagent_type" \
  --arg target "$(telemetry_truncate "$target_short" "$TELEMETRY_FIELD_CAP_CHARS")" \
  --arg ws "$ws_san" \
  --arg outcome "started" \
  --arg summary "$summary" \
  '{
    outcome: $outcome,
    tool_name: (if ($tool_name|length) > 0 then $tool_name else null end),
    tool_call_id: (if ($tool_call_id|length) > 0 then $tool_call_id else null end),
    subagent_type: (if ($subagent_type|length) > 0 then $subagent_type else null end),
    target: (if ($target|length) > 0 then $target else null end),
    actor: { workspace_root: $ws },
    summary: $summary
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "preToolUse" "$session_id" "$extra"

telemetry_emit_allow
exit 0
