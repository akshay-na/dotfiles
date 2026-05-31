#!/usr/bin/env bash
# Apply pre-migrate quarantine manifest: quarantine nodes, append quarantine.index.jsonl.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

SLUG=""
MODE="dry-run"
MANIFEST=""

usage() {
  cat <<EOF >&2
usage: $(basename "$0") [--dry-run|--apply] --slug SLUG --manifest PATH
  --dry-run   show planned quarantine actions (default)
  --apply     move nodes to quarantine/ and append quarantine.index.jsonl
  --slug SLUG project kb-identity slug
  --manifest PATH  pre-migrate-quarantine YAML from triage or human edit
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
    --manifest)
      MANIFEST="${2:-}"
      [[ -n "$MANIFEST" ]] || { usage; exit 2; }
      shift
      ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
  shift
done

[[ -n "$SLUG" && -n "$MANIFEST" && -f "$MANIFEST" ]] || { usage; exit 2; }

POLICY="$(resolve_policy_path)"
export BRAIN_ROOT
APPLY_FLAG="dry-run"
[[ "$MODE" == "apply" ]] && APPLY_FLAG="apply"

brain_python "$POLICY" quarantine-apply "$SLUG" "$MANIFEST" "$APPLY_FLAG"
