#!/usr/bin/env bash
# telemetry-shell-after.sh
#
# afterShellExecution audit hook. Logs that a shell command finished and what
# its exit code looked like. Captures only first token + redacted compact
# summary; no stdout/stderr is persisted.
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
cmd="$(printf '%s' "$input" | jq -r '.command // empty' 2>/dev/null)"
exit_code="$(printf '%s' "$input" | jq -r '.exit_code // .exitCode // .status // empty' 2>/dev/null)"

first=""
if [ -n "$cmd" ]; then
  first="$(printf '%s' "$cmd" | awk 'BEGIN{FS="[[:space:]]"} {print $1; exit}')"
fi

# Pop pending shell-before entry to compute duration.
pending="$(telemetry_pop_pending_tool "$session_id" "" "Shell:$first")"
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

outcome="success"
case "$exit_code" in
  '' | 0) outcome="success" ;;
  *) outcome="failure" ;;
esac

# Sanitize stdout/stderr length signals only (we never log the bodies).
stdout_bytes="$(printf '%s' "$input" | jq -r '(.stdout // "") | length' 2>/dev/null)"
stderr_bytes="$(printf '%s' "$input" | jq -r '(.stderr // "") | length' 2>/dev/null)"
[ -z "$stdout_bytes" ] && stdout_bytes=0
[ -z "$stderr_bytes" ] && stderr_bytes=0

summary_san="$(telemetry_truncate "$cmd" "$TELEMETRY_FIELD_CAP_CHARS")"
summary_san="$(printf '%s' "$summary_san" | telemetry_redact)"
[ -z "$summary_san" ] && summary_san="cmd=$first exit=$exit_code"

extra="$(jq -nc \
  --arg first "$first" \
  --arg ws "$ws_san" \
  --arg outcome "$outcome" \
  --arg summary "$summary_san" \
  --argjson duration_ms "$duration_ms" \
  --argjson stdout_bytes "$stdout_bytes" \
  --argjson stderr_bytes "$stderr_bytes" \
  --arg exit_code "$exit_code" \
  '{
    outcome: $outcome,
    tool_name: "Shell",
    shell_first_token: (if ($first|length) > 0 then $first else null end),
    duration_ms: $duration_ms,
    exit_code: (if ($exit_code|length) > 0 then ($exit_code|tonumber? // null) else null end),
    counters: { stdout_bytes: $stdout_bytes, stderr_bytes: $stderr_bytes },
    actor: { workspace_root: $ws },
    summary: $summary
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "afterShellExecution" "$session_id" "$extra"
exit 0
