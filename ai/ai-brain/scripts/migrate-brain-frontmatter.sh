#!/usr/bin/env bash
# Migrate legacy status frontmatter → lifecycle_state + retrieval_weight.
# Default: --dry-run. --apply requires signed pre-migrate quarantine manifest (cro-013).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

SLUG=""
MODE="dry-run"
CHECK_ONLY=0

usage() {
  cat <<EOF >&2
usage: $(basename "$0") [--dry-run|--apply|--check-slug SLUG] [--slug SLUG]
  --dry-run          report planned changes (default)
  --apply            patch nodes; strip legacy status; requires signed quarantine manifest
  --check-slug SLUG  exit 0 iff zero unmigrated KB nodes for slug
  --slug SLUG        project kb-identity slug (required except alone with --check-slug)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run" ;;
    --apply) MODE="apply" ;;
    --check-slug)
      CHECK_ONLY=1
      SLUG="${2:-}"
      [[ -n "$SLUG" ]] || { usage; exit 2; }
      shift
      ;;
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

if [[ "$CHECK_ONLY" -eq 1 ]]; then
  POLICY="$(resolve_policy_path)"
  export BRAIN_ROOT
  brain_python "$POLICY" check-slug "$SLUG"
fi

[[ -n "$SLUG" ]] || { usage; exit 2; }

if ! command -v python3 >/dev/null 2>&1; then
  echo "migrate-brain-frontmatter: python3 required" >&2
  exit 1
fi

POLICY="$(resolve_policy_path)"
META="$BRAIN_ROOT/projects/$SLUG/.meta"
mkdir -p "$META"
DATE="$(date -u +%Y-%m-%d)"
REPORT="$META/migration-${DATE}.jsonl"
MANIFEST_PATH=""

if [[ "$MODE" == "apply" ]]; then
  if ! MANIFEST_PATH="$(find_signed_quarantine_manifest "$SLUG")"; then
    echo "migrate-brain-frontmatter: --apply requires signed manifest at" >&2
    echo "  $BRAIN_ROOT/projects/$SLUG/.meta/pre-migrate-quarantine-<date>.yaml" >&2
    echo "  with signed_off: true" >&2
    exit 1
  fi
  echo "migrate-brain-frontmatter: using quarantine manifest $MANIFEST_PATH"
fi

export BRAIN_ROOT
APPLY_FLAG="dry-run"
[[ "$MODE" == "apply" ]] && APPLY_FLAG="apply"

set +e
brain_python "$POLICY" migrate "$SLUG" "$APPLY_FLAG" "$REPORT" "${MANIFEST_PATH:-}"
RC=$?
set -e

echo "migrate-brain-frontmatter: report=$REPORT mode=$MODE exit=$RC"
exit "$RC"
