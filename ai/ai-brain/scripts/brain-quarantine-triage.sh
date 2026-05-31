#!/usr/bin/env bash
# Triage KB nodes for pre-migrate quarantine (stale_trap, injection_suspect, dual-field drift).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

SLUG=""
MODE="dry-run"
OUT=""

usage() {
  cat <<EOF >&2
usage: $(basename "$0") [--dry-run|--apply] --slug SLUG [--out PATH]
  --dry-run   emit manifest candidate YAML (default)
  --apply     write manifest to .meta/pre-migrate-quarantine-<date>.yaml
  --slug SLUG project kb-identity slug
  --out PATH  optional output path (default stdout or .meta on --apply)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run" ;;
    --apply) MODE="apply" ;;
    --slug)
      SLUG="${2:-}"
      [[ -n "$SLUG" ]] || { usage; exit 2; }
      shift
      ;;
    --out)
      OUT="${2:-}"
      [[ -n "$OUT" ]] || { usage; exit 2; }
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
  shift
done

[[ -n "$SLUG" ]] || { usage; exit 2; }

POLICY="$(resolve_policy_path)"
DATE="$(date -u +%Y-%m-%d)"
if [[ -z "$OUT" && "$MODE" == "apply" ]]; then
  OUT="$BRAIN_ROOT/projects/$SLUG/.meta/pre-migrate-quarantine-${DATE}.yaml"
fi

export BRAIN_ROOT
if [[ -n "$OUT" ]]; then
  brain_python "$POLICY" triage "$SLUG" "$OUT"
else
  brain_python "$POLICY" triage "$SLUG" ""
fi
