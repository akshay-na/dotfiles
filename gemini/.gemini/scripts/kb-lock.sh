#!/usr/bin/env bash
# Acquire / release repo sync lock (used with kb-sync and multi-step agent writes).
set -euo pipefail
REPO="${CONTENT_KB_REPO:-$HOME/content-knowledge-base}"
LOCK_DIR="$REPO/.git/kb-sync.lock.dir"
TIMEOUT="${KB_SYNC_LOCK_TIMEOUT:-30}"

acquire() {
  local end=$((SECONDS + TIMEOUT))
  while true; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      echo "$$" >"$LOCK_DIR/pid"
      return 0
    fi
    if (( SECONDS >= end )); then
      echo "kb-lock: timeout waiting for lock" >&2
      return 40
    fi
    sleep 0.25
  done
}

release() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}

case "${1:-}" in
acquire) acquire ;;
release) release ;;
with)
  shift
  acquire
  trap release EXIT
  "$@"
  ;;
*)
  echo "usage: kb-lock.sh acquire|release|with <command> [args...]" >&2
  exit 2
  ;;
esac
