#!/usr/bin/env bash
# telemetry-mcp-before.sh
#
# beforeMCPExecution audit hook. Records that an MCP tool is about to run.
# Captures: server name, tool name, redacted compact arg summary. Never logs
# raw arguments or credentials.
#
# Always returns `permission: allow`.
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

server="$(printf '%s' "$input" | jq -r '.server // .server_name // .mcp_server // empty' 2>/dev/null)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // .toolName // .tool // empty' 2>/dev/null)"

# Args summary: top-level keys only (NEVER values), to avoid secret leakage.
args_keys="$(printf '%s' "$input" | jq -rc '
  (.arguments // .args // .tool_input // {}) as $a
  | (if ($a|type) == "object" then ($a | keys) else [] end)
' 2>/dev/null)"
[ -z "$args_keys" ] && args_keys="[]"

now_ms="$(telemetry_now_ms)"
mcp_id="$server::$tool"
telemetry_register_pending_tool "$session_id" "" "MCP:$mcp_id" "$now_ms"

extra="$(jq -nc \
  --arg server "$server" \
  --arg tool "$tool" \
  --arg ws "$ws_san" \
  --argjson keys "$args_keys" \
  --arg outcome "started" \
  --arg summary "mcp server=$server tool=$tool" \
  '{
    outcome: $outcome,
    tool_name: ("MCP:" + $server + ":" + $tool),
    mcp: { server: $server, tool: $tool, arg_keys: $keys },
    actor: { workspace_root: $ws },
    summary: $summary
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "beforeMCPExecution" "$session_id" "$extra"

telemetry_emit_allow
exit 0
