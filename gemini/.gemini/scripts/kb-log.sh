#!/usr/bin/env bash
# Append structured line to kb-sync log; rotate when >10MB.
set -euo pipefail
LOG="${KB_SYNC_LOG:-$HOME/Library/Logs/kb-sync.log}"
MAX_BYTES=$((10 * 1024 * 1024))
level="${1:-INFO}"
shift || true
msg="$*"
ts="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
mkdir -p "$(dirname "$LOG")"
if [[ -f "$LOG" ]] && [[ "$(wc -c <"$LOG" | tr -d ' ')" -gt $MAX_BYTES ]]; then
  mv "$LOG" "${LOG}.1"
fi
printf 'ts=%s level=%s %s\n' "$ts" "$level" "$msg" >>"$LOG"
