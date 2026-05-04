#!/usr/bin/env bash
# Keychain get/set — never log secret values.
set -euo pipefail
svc="${2:?usage: keychain-helper.sh get|set <service> [value-for-set]}"
case "${1:?}" in
get)
  if [[ ! -t 1 ]]; then
    echo "keychain-helper: refusing to print secret to non-TTY stdout" >&2
    exit 1
  fi
  security find-generic-password -s "$svc" -w 2>/dev/null || exit 1
  ;;
set)
  val="${3:?usage: keychain-helper.sh set <service> <value>}"
  security delete-generic-password -s "$svc" &>/dev/null || true
  security add-generic-password -s "$svc" -a "${USER:-user}" -w "$val" -U
  echo "keychain-helper: stored service=$svc (value not echoed)" >&2
  ;;
*)
  echo "usage: keychain-helper.sh get|set <service> [value]" >&2
  exit 2
  ;;
esac
