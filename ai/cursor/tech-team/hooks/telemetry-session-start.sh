#!/usr/bin/env bash
# telemetry-session-start.sh
#
# sessionStart hook. Initialises the telemetry pipeline for this session:
#   - ensures the log/cache dirs exist
#   - rotates yesterday's events.jsonl if needed and prunes anything past
#     retention
#   - mints a per-session trace_id (cached for the rest of the session)
#   - writes a session manifest under ~/.cursor/logs/telemetry/sessions/
#   - emits the sessionStart JSONL event
#
# Fail-open. Any error -> silent exit 0.
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

# Honour the master kill switch before doing any work or writes.
[ "$TELEMETRY_ENABLED" = "1" ] || exit 0

session_id="$(printf '%s' "$input" | telemetry_extract_session_id)"
[ -z "$session_id" ] && session_id="nosession"
workspace_root="$(printf '%s' "$input" | telemetry_extract_workspace_root)"
ws_san="$(telemetry_sanitize_path "$workspace_root")"

telemetry_ensure_dirs
telemetry_rotate_if_needed

# Bind a stable trace_id for this session.
trace_id="$(telemetry_get_or_create_trace_id "$session_id")"

# Persist a session manifest. Idempotent: if we already wrote one, just bump
# the last_seen_at.
manifest="$TELEMETRY_SESSIONS_DIR/$session_id.json"
now_ts="$(telemetry_iso8601_utc)"
if [ ! -s "$manifest" ]; then
  jq -nc \
    --arg session_id "$session_id" \
    --arg trace_id "$trace_id" \
    --arg started_at "$now_ts" \
    --arg workspace_root "$ws_san" \
    --arg pack "$TELEMETRY_PACK_ID" \
    '{
      schema_version: 1,
      session_id: $session_id,
      trace_id: $trace_id,
      started_at: $started_at,
      last_seen_at: $started_at,
      workspace_root: $workspace_root,
      hooks_pack: $pack
    }' > "$manifest" 2>/dev/null || true
  chmod 640 "$manifest" 2>/dev/null || true
fi

extra="$(jq -nc \
  --arg workspace_root "$ws_san" \
  --arg outcome "n/a" \
  --arg summary "session started; telemetry initialised" \
  '{
    outcome: $outcome,
    actor: { workspace_root: $workspace_root },
    summary: $summary
  }' 2>/dev/null)"
[ -n "$extra" ] && telemetry_emit_event "sessionStart" "$session_id" "$extra"

# sessionStart has no permission semantics; nothing to print.
exit 0
