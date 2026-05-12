#!/usr/bin/env bash
# telemetry-shell-before.sh
#
# beforeShellExecution audit hook. Logs that a shell command is about to run.
# Captures only the first command token (sanitized) and a redacted compact
# summary — never the full command string.
#
# Always returns `permission: allow`. Gating belongs to safe-shell.sh.
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
cmd="$(printf '%s' "$input" | jq -r '.command // empty' 2>/dev/null)"
cwd="$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null)"
cwd_san="$(telemetry_sanitize_path "$cwd")"

# First token only.
first=""
if [ -n "$cmd" ]; then
  first="$(printf '%s' "$cmd" | awk 'BEGIN{FS="[[:space:]]"} {print $1; exit}')"
fi

# Compact, redacted summary capped to N chars.
summary_raw="$(telemetry_truncate "$cmd" "$TELEMETRY_FIELD_CAP_CHARS")"
summary_san="$(printf '%s' "$summary_raw" | telemetry_redact)"
[ -z "$summary_san" ] && summary_san="cmd=$first"

now_ms="$(telemetry_now_ms)"
# Stack-based pairing — shell-after pops by tool="Shell:<first_token>". Cursor
# does not provide a stable shell call id we can re-derive on the after-side.
telemetry_register_pending_tool "$session_id" "" "Shell:$first" "$now_ms"

extra="$(jq -nc \
  --arg first "$first" \
  --arg cwd "$cwd_san" \
  --arg ws "$ws_san" \
  --arg outcome "started" \
  --arg summary "$summary_san" \
  '{
    outcome: $outcome,
    tool_name: "Shell",
    shell_first_token: (if ($first|length) > 0 then $first else null end),
    actor: { workspace_root: $ws, cwd: $cwd },
    summary: $summary
  }' 2>/dev/null)"

[ -n "$extra" ] && telemetry_emit_event "beforeShellExecution" "$session_id" "$extra"

telemetry_emit_allow
exit 0
