#!/usr/bin/env bash
# telemetry-mcp-after.sh
#
# afterMCPExecution audit hook. Records duration, outcome, and bounded byte
# counters of the MCP response. NEVER logs raw response bodies.
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

server="$(printf '%s' "$input" | jq -r '.server // .server_name // .mcp_server // empty' 2>/dev/null)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // .toolName // .tool // empty' 2>/dev/null)"

mcp_id="$server::$tool"
pending="$(telemetry_pop_pending_tool "$session_id" "" "MCP:$mcp_id")"
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

# Detect error.
outcome="success"
err_class=""
if printf '%s' "$input" | jq -e '.error // .response.error // .result.is_error // empty' >/dev/null 2>&1; then
  if [ "$(printf '%s' "$input" | jq -r '(.error // .response.error // .result.is_error // false)')" != "false" ]; then
    outcome="failure"
    err_class="$(printf '%s' "$input" | jq -r '(.error.type // .error.code // .response.error.type // empty)' 2>/dev/null)"
  fi
fi

response_bytes="$(printf '%s' "$input" | jq -rc '
  ((.response // .result // .updated_mcp_tool_output // {}) | tostring | length)
' 2>/dev/null)"
[ -z "$response_bytes" ] && response_bytes=0

extra="$(jq -nc \
  --arg server "$server" \
  --arg tool "$tool" \
  --arg outcome "$outcome" \
  --arg err_class "$err_class" \
  --arg ws "$ws_san" \
  --argjson duration_ms "$duration_ms" \
  --argjson response_bytes "$response_bytes" \
  '{
    outcome: $outcome,
    tool_name: ("MCP:" + $server + ":" + $tool),
    mcp: { server: $server, tool: $tool },
    duration_ms: $duration_ms,
    error_class: (if ($err_class|length) > 0 then $err_class else null end),
    counters: { response_bytes: $response_bytes },
    actor: { workspace_root: $ws },
    summary: ("mcp " + $server + ":" + $tool + " " + $outcome)
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "afterMCPExecution" "$session_id" "$extra"
exit 0
