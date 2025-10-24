#!/bin/sh

# Cross-platform pinentry wrapper for macOS, Windows (MINGW), and Linux.
# Falls back to curses mode in headless/SSH.
# Optional: enable debug output with DEBUG_PINENTRY=1

log() { [[ -n "$DEBUG_PINENTRY" ]] && echo "[pinentry-wrapper] $*" >&2; }

platform=$(uname)
log "Detected platform: $platform"

case "$platform" in
Darwin)
  if command -v pinentry-mac >/dev/null 2>&1; then
    log "Using pinentry-mac"
    exec -- pinentry-mac "$@"
  fi
  ;;
MINGW* | MSYS* | CYGWIN*)
  if command -v pinentry.exe >/dev/null 2>&1; then
    log "Using pinentry.exe"
    exec -- pinentry.exe "$@"
  fi
  ;;
esac

# Headless (e.g., SSH) fallback
if [[ -z "$DISPLAY" ]] && command -v pinentry-curses >/dev/null 2>&1; then
  log "Headless detected, using pinentry-curses"
  exec -- pinentry-curses "$@"
fi

# Standard Linux/Unix fallback chain
if command -v pinentry-gtk-2 >/dev/null 2>&1; then
  log "Using pinentry-gtk-2"
  exec -- pinentry-gtk-2 "$@"
elif command -v pinentry-curses >/dev/null 2>&1; then
  log "Using pinentry-curses"
  exec -- pinentry-curses "$@"
fi

log "No suitable pinentry found for your system!"
echo "ERROR: No suitable pinentry found!" >&2
exit 1
