#!/usr/bin/env bash
# Deterministic G2 synthetic episode: kb_query (L1) + kb_demote (L2) with shared trace_id/task_id.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRAIN_PACK_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURE="$BRAIN_PACK_ROOT/projects/dotfiles/observability/fixtures/brain-audit-join-sample.jsonl"
SLUG="dotfiles"
LEDGER=""
TASK_ID=""
TRACE_ID=""
DRY_RUN=0
FIXTURE_ONLY=0

usage() {
  echo "usage: $(basename "$0") [--slug SLUG] [--ledger PATH] [--task-id ID] [--trace-id ID]" >&2
  echo "       [--dry-run] [--fixture-only]" >&2
}

while [ $# -gt 0 ]; do
  case "$1" in
    --slug)
      SLUG="$2"
      shift 2
      ;;
    --ledger)
      LEDGER="$2"
      shift 2
      ;;
    --task-id)
      TASK_ID="$2"
      shift 2
      ;;
    --trace-id)
      TRACE_ID="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --fixture-only)
      FIXTURE_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "brain-audit-synthetic-episode: unknown arg: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [ "$FIXTURE_ONLY" -eq 1 ]; then
  exec "$SCRIPT_DIR/validate-brain-audit-join.sh" --fixture "$FIXTURE"
fi

if [ -z "$LEDGER" ]; then
  LEDGER="${HOME:?}/ai-brain/projects/${SLUG}/.meta/brain-audit-log.jsonl"
fi

if [ -z "$TASK_ID" ]; then
  TASK_ID="g2-synthetic-$(date -u +%Y%m%dT%H%M%SZ)"
fi
if [ -z "$TRACE_ID" ]; then
  TRACE_ID="${TASK_ID}-exec"
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "brain-audit-synthetic-episode: jq required" >&2
  exit 1
fi

TS_QUERY="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
if date -u -v+1S +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
  TS_DEMOTE="$(date -u -v+1S +%Y-%m-%dT%H:%M:%SZ)"
elif date -u -d '+1 second' +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
  TS_DEMOTE="$(date -u -d '+1 second' +%Y-%m-%dT%H:%M:%SZ)"
else
  TS_DEMOTE="$TS_QUERY"
fi

QUERY_JSON="$(jq -nc \
  --arg trace_id "$TRACE_ID" \
  --arg task_id "$TASK_ID" \
  --arg ts "$TS_QUERY" \
  '{trace_id:$trace_id, task_id:$task_id, event_type:"kb_query", ladder_depth:"L1", ts:$ts}')"
DEMOTE_JSON="$(jq -nc \
  --arg trace_id "$TRACE_ID" \
  --arg task_id "$TASK_ID" \
  --arg ts "$TS_DEMOTE" \
  '{trace_id:$trace_id, task_id:$task_id, event_type:"kb_demote", ladder_depth:"L2", ts:$ts}')"

echo "brain-audit-synthetic-episode: slug=$SLUG ledger=$LEDGER"
echo "brain-audit-synthetic-episode: task_id=$TASK_ID trace_id=$TRACE_ID"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "brain-audit-synthetic-episode: dry-run (no ledger write)"
  printf '%s\n' "$QUERY_JSON" "$DEMOTE_JSON"
  "$SCRIPT_DIR/validate-brain-audit-join.sh" --fixture "$FIXTURE"
  exit 0
fi

mkdir -p "$(dirname "$LEDGER")"
touch "$LEDGER"
printf '%s\n' "$QUERY_JSON" "$DEMOTE_JSON" >> "$LEDGER"

echo "brain-audit-synthetic-episode: appended kb_query + kb_demote"
"$SCRIPT_DIR/validate-brain-audit-join.sh" --ledger "$LEDGER" --ledger-only
