#!/usr/bin/env bash
# telemetry-subagent-start.sh
#
# subagentStart audit hook. Records that a Task subagent dispatch is starting,
# captures parent/child correlation, and seeds a pending entry so
# subagentStop can compute duration_ms.
#
# Always returns `permission: allow` (gating belongs to the existing
# subagent-task-antidup-preflight + subagent-protocol-inject hooks).
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
workspace_root="$(printf '%s' "$input" | telemetry_extract_workspace_root)"
ws_san="$(telemetry_sanitize_path "$workspace_root")"

subagent_type="$(printf '%s' "$input" | jq -r '
  .subagent_type //
  .subagentType //
  .agent //
  .tool_input.subagent_type //
  empty
' 2>/dev/null)"
description="$(printf '%s' "$input" | jq -r '
  .description //
  .tool_input.description //
  empty
' 2>/dev/null)"
parent_run_id="$(printf '%s' "$input" | jq -r '
  .parent_run_id //
  .parentRunId //
  .parent_subagent_run_id //
  empty
' 2>/dev/null)"
agent_run_id="$(printf '%s' "$input" | jq -r '
  .run_id //
  .runId //
  .subagent_run_id //
  empty
' 2>/dev/null)"
[ -z "$agent_run_id" ] && agent_run_id="$(telemetry_uuid)"

now_ms="$(telemetry_now_ms)"
telemetry_register_pending_tool "$session_id" "$agent_run_id" "Task:$subagent_type" "$now_ms"

# Persist a session-scoped agent_run lookup for subagentStop, in case Cursor
# doesn't echo run_id back on stop.
dir="$(telemetry_session_cache_dir "$session_id")"
mkdir -p "$dir/runs" 2>/dev/null || true
[ -n "$subagent_type" ] && echo "$agent_run_id" > "$dir/runs/last-$subagent_type" 2>/dev/null || true
chmod 600 "$dir/runs/last-$subagent_type" 2>/dev/null || true

description_san="$(telemetry_truncate "$description" "$TELEMETRY_FIELD_CAP_CHARS")"
description_san="$(printf '%s' "$description_san" | telemetry_redact)"

extra="$(jq -nc \
  --arg subagent_type "$subagent_type" \
  --arg agent_run_id "$agent_run_id" \
  --arg parent_run_id "$parent_run_id" \
  --arg description "$description_san" \
  --arg ws "$ws_san" \
  --arg outcome "dispatched" \
  '{
    outcome: $outcome,
    tool_name: "Task",
    subagent_type: (if ($subagent_type|length) > 0 then $subagent_type else null end),
    subagent_run_id: $agent_run_id,
    parent_subagent_run_id: (if ($parent_run_id|length) > 0 then $parent_run_id else null end),
    actor: { workspace_root: $ws },
    summary: ("subagent dispatch type=" + $subagent_type + " desc=" + $description)
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "subagentStart" "$session_id" "$extra"

telemetry_emit_allow
exit 0
