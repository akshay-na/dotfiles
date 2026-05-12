#!/usr/bin/env bash
# telemetry-session-end.sh
#
# sessionEnd hook. Emits a session summary:
#   - reads the session manifest
#   - counts events recorded for this session
#   - writes a sessionEnd JSONL event with duration + counts
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
session_id="$(printf '%s' "$input" | telemetry_extract_session_id)"
[ -z "$session_id" ] && session_id="nosession"

telemetry_ensure_dirs

manifest="$TELEMETRY_SESSIONS_DIR/$session_id.json"
started_at=""
if [ -s "$manifest" ]; then
  started_at="$(jq -r '.started_at // empty' "$manifest" 2>/dev/null)"
fi

# Count events for this session in the active rolling file.
events=0
if [ -s "$TELEMETRY_EVENTS_FILE" ] && command -v jq >/dev/null 2>&1; then
  events="$(jq -rc --arg sid "$session_id" 'select(.session_id == $sid) | 1' "$TELEMETRY_EVENTS_FILE" 2>/dev/null | wc -l | tr -d ' ')"
  [ -z "$events" ] && events=0
fi

now_ts="$(telemetry_iso8601_utc)"
duration_ms=0
if [ -n "$started_at" ] && command -v python3 >/dev/null 2>&1; then
  duration_ms="$(python3 -c "
import sys
from datetime import datetime, timezone
def parse(s):
    s=s.replace('Z','+00:00')
    return datetime.fromisoformat(s)
try:
    a=parse('$started_at'); b=parse('$now_ts')
    print(int((b-a).total_seconds()*1000))
except Exception:
    print(0)
" 2>/dev/null || echo 0)"
fi

# Refresh manifest's last_seen_at + ended_at without overwriting other fields.
if [ -s "$manifest" ]; then
  tmp="$(mktemp -t cursor-telem.XXXXXX 2>/dev/null || mktemp 2>/dev/null)"
  if [ -n "$tmp" ]; then
    jq --arg now "$now_ts" --argjson dur "$duration_ms" --argjson ev "$events" \
      '. + { ended_at: $now, last_seen_at: $now, duration_ms: $dur, event_count: $ev }' \
      "$manifest" > "$tmp" 2>/dev/null && mv "$tmp" "$manifest" 2>/dev/null
    rm -f "$tmp" 2>/dev/null || true
  fi
fi

extra="$(jq -nc \
  --arg outcome "n/a" \
  --argjson dur "$duration_ms" \
  --argjson events "$events" \
  --arg summary "session ended" \
  '{
    outcome: $outcome,
    duration_ms: $dur,
    summary: $summary,
    counters: { events_in_session: $events }
  }' 2>/dev/null)"
[ -n "$extra" ] && telemetry_emit_event "sessionEnd" "$session_id" "$extra"

exit 0
