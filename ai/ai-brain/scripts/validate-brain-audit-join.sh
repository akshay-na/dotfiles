#!/usr/bin/env bash
# G2 brain-audit jq join validator — fixture default; optional live ledger.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FIXTURE="$ROOT/projects/dotfiles/observability/fixtures/brain-audit-join-sample.jsonl"
LEDGER=""
CHECK_FIXTURE=1

usage() {
  echo "usage: $(basename "$0") [--fixture PATH] [--ledger PATH] [--ledger-only]" >&2
  echo "  Validates jq group_by(.task_id) join returns non-empty groups." >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --fixture)
      FIXTURE="$2"
      shift 2
      ;;
    --ledger)
      LEDGER="$2"
      shift 2
      ;;
    --ledger-only)
      CHECK_FIXTURE=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "validate-brain-audit-join: unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "validate-brain-audit-join: jq required" >&2
  exit 1
fi

joinable_count() {
  local file="$1"
  jq -s 'group_by(.task_id) | map(select(length >= 2)) | length' "$file"
}

validate_file() {
  local file="$1"
  local label="$2"
  if [ ! -f "$file" ]; then
    echo "validate-brain-audit-join: missing $label: $file" >&2
    return 1
  fi
  if ! jq -e . "$file" >/dev/null 2>&1; then
    echo "validate-brain-audit-join: invalid JSONL in $label: $file" >&2
    return 1
  fi
  local count
  count="$(joinable_count "$file")"
  if [ "$count" -eq 0 ]; then
    echo "validate-brain-audit-join: no joinable task_id groups in $label ($file)" >&2
    return 1
  fi
  echo "validate-brain-audit-join: ok $label joinable_groups=$count ($file)"
}

rc=0
if [ "$CHECK_FIXTURE" -eq 1 ]; then
  validate_file "$FIXTURE" "fixture" || rc=1
fi
if [ -n "$LEDGER" ]; then
  validate_file "$LEDGER" "ledger" || rc=1
fi
if [ "$CHECK_FIXTURE" -eq 0 ] && [ -z "$LEDGER" ]; then
  echo "validate-brain-audit-join: --ledger PATH required with --ledger-only" >&2
  exit 2
fi

exit "$rc"
