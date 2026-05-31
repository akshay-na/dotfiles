#!/usr/bin/env bash
# Rebuild session/<task-id>/memory.index.yaml per memory-index schema + read_policy.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

TASK_ID=""
SLUG=""
MODE="dry-run"

usage() {
  cat <<EOF >&2
usage: $(basename "$0") <task-id> <slug> [--dry-run|--apply]
  --dry-run  print planned memory.index.yaml (default)
  --apply    write ~/ai-brain/session/<task-id>/memory.index.yaml
EOF
}

positional=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) MODE="dry-run" ;;
    --apply) MODE="apply" ;;
    -h|--help) usage; exit 0 ;;
    --*) usage; exit 2 ;;
    *) positional+=("$1") ;;
  esac
  shift
done

if [[ ${#positional[@]} -ge 1 ]]; then
  TASK_ID="${positional[0]}"
fi
if [[ ${#positional[@]} -ge 2 ]]; then
  SLUG="${positional[1]}"
fi

[[ -n "$TASK_ID" && -n "$SLUG" ]] || { usage; exit 2; }

POLICY="$(resolve_policy_path)"
export BRAIN_ROOT
APPLY_FLAG="dry-run"
[[ "$MODE" == "apply" ]] && APPLY_FLAG="apply"

brain_python "$POLICY" rebuild-session "$TASK_ID" "$SLUG" "$APPLY_FLAG"
