#!/usr/bin/env bash

# Cross-platform pinentry wrapper for macOS, Windows (MINGW), and Linux.
# 1. On macOS, use pinentry-mac (if installed).
# 2. On Windows/MSYS2 (uname contains "MINGW"), use pinentry.exe (if on PATH).
# 3. On Linux, prefer pinentry-gtk-2, then fallback to pinentry-curses.
# 4. If none found, print an error.

case "$(uname)" in
Darwin)
  if command -v pinentry-mac >/dev/null 2>&1; then
    exec pinentry-mac "$@"
  fi
  ;;
MINGW* | MSYS* | CYGWIN*)
  # This covers Git Bash, MSYS2, Cygwin environments on Windows.
  # Make sure Gpg4win's bin dir (where pinentry.exe lives) is in your PATH.
  if command -v pinentry.exe >/dev/null 2>&1; then
    exec pinentry.exe "$@"
  fi
  ;;
esac

# If not macOS or Windows (or if the above checks failed), assume Linux/Unix:
if command -v pinentry-gtk-2 >/dev/null 2>&1; then
  exec pinentry-gtk-2 "$@"
elif command -v pinentry-curses >/dev/null 2>&1; then
  exec pinentry-curses "$@"
fi

echo "No suitable pinentry found for your system!" >&2
exit 1
