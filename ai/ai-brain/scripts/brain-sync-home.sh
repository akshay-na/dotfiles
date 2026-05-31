#!/usr/bin/env bash
# Regenerate ~/ai-brain/Home.md from projects/*/manifest.json or directory scan.
# Idempotent: stable sort, deterministic blurbs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

MODE="dry-run"

usage() {
  cat <<EOF >&2
usage: $(basename "$0") [--dry-run|--apply]
  --dry-run  print planned Home.md (default)
  --apply    write \$BRAIN_ROOT/Home.md
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run" ;;
    --apply) MODE="apply" ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
  shift
done

APPLY_FLAG="dry-run"
[[ "$MODE" == "apply" ]] && APPLY_FLAG="apply"

POLICY="$(resolve_policy_path)"
export BRAIN_ROOT
brain_python "$POLICY" sync-home "$APPLY_FLAG"
