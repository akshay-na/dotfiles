#!/usr/bin/env bash
# Rebuild projects/<slug>/_index.md — active and superseded nodes only.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

SLUG=""
MODE="dry-run"

usage() {
  cat <<EOF >&2
usage: $(basename "$0") [--dry-run|--apply] --slug SLUG
  --dry-run  print planned _index.md (default)
  --apply    write projects/<slug>/_index.md
  --slug SLUG project kb-identity slug
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
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
  shift
done

[[ -n "$SLUG" ]] || { usage; exit 2; }

POLICY="$(resolve_policy_path)"
export BRAIN_ROOT
APPLY_FLAG="dry-run"
[[ "$MODE" == "apply" ]] && APPLY_FLAG="apply"

brain_python "$POLICY" rebuild-l1 "$SLUG" "$APPLY_FLAG"
