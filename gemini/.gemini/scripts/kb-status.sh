#!/usr/bin/env bash
# Print sync health; exit non-zero if last push older than threshold.
set -euo pipefail
REPO="${CONTENT_KB_REPO:-$HOME/content-knowledge-base}"
STATE="$REPO/.git/kb-sync-state.json"
THRESHOLD="${KB_STATUS_PUSH_MAX_AGE:-3600}"

if [[ ! -d "$REPO/.git" ]]; then
  echo "kb-status: repo missing or not a git clone: $REPO" >&2
  exit 1
fi

last_ok=""
last_err=""
dirty=0
if [[ -f "$STATE" ]]; then
  last_ok="$(sed -n 's/.*"last_successful_push_at"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE" | head -1)"
  last_err="$(sed -n 's/.*"last_error"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE" | head -1)"
fi

if [[ -d "$REPO" ]]; then
  dirty="$(cd "$REPO" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
fi

echo "repo=$REPO"
echo "last_successful_push_at=${last_ok:-unknown}"
echo "last_error=${last_err:-none}"
echo "dirty_paths_count=$dirty"

if [[ -z "$last_ok" || "$last_ok" == "null" ]]; then
  echo "kb-status: no successful push recorded yet" >&2
  exit 2
fi

if [[ "$OSTYPE" == darwin* ]]; then
  last_epoch="$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$last_ok" "+%s" 2>/dev/null || echo 0)"
else
  last_epoch="$(date -d "$last_ok" "+%s" 2>/dev/null || echo 0)"
fi
now="$(date -u +"%s")"
age=$((now - last_epoch))
echo "seconds_since_last_push=$age"
if (( age > THRESHOLD )); then
  echo "kb-status: last push older than ${THRESHOLD}s" >&2
  exit 3
fi
exit 0
