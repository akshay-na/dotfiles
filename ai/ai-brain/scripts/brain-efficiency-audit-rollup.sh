#!/usr/bin/env bash
# Append TSV rollup row to brain-efficiency-audit.md (7d window proxy for L0/L1 SLO).
set -euo pipefail

WINDOW_HOURS="${WINDOW_HOURS:-168}"
TELEMETRY="${TELEMETRY:-${HOME:?}/.cursor/logs/telemetry/events.jsonl}"
SINK="${SINK:-${HOME:?}/ai-brain/org/global/orchestration/brain-efficiency-audit.md}"
BRAIN_ROOT="${BRAIN_ROOT:-${HOME:?}/ai-brain}"

HEADER="ts_utc | window_hours | entrypoint_episodes | l0l1_before_mutation_pct | bootstrap_degraded_pct | kb_query_events | slo_l0l1_met | slo_bootstrap_met"

ensure_header() {
  mkdir -p "$(dirname "$SINK")"
  if [ ! -f "$SINK" ]; then
    {
      echo "# brain-efficiency-audit"
      echo ""
      echo "$HEADER"
    } > "$SINK"
    return
  fi
  if ! grep -q 'window_hours' "$SINK" 2>/dev/null; then
    {
      echo "# brain-efficiency-audit"
      echo ""
      echo "$HEADER"
      echo ""
      cat "$SINK"
    } > "${SINK}.tmp"
    mv "${SINK}.tmp" "$SINK"
  fi
}

compute_row() {
  python3 - "$WINDOW_HOURS" "$TELEMETRY" "$BRAIN_ROOT" <<'PY'
import json
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

window_hours = int(sys.argv[1])
telemetry_path = Path(sys.argv[2])
brain_root = Path(sys.argv[3])
cutoff = datetime.now(timezone.utc) - timedelta(hours=window_hours)

def parse_ts(raw):
    if not raw:
        return None
    s = raw.replace("Z", "+00:00")
    try:
        dt = datetime.fromisoformat(s)
    except ValueError:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)

def in_window(ts_raw):
    dt = parse_ts(ts_raw)
    return dt is not None and dt >= cutoff

session_starts = 0
bootstrap_degraded = 0
bootstrap_total = 0

if telemetry_path.is_file():
    for line in telemetry_path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        ts = ev.get("ts")
        if not in_window(ts):
            continue
        et = ev.get("event_type")
        summary = str(ev.get("summary") or "")
        if et == "sessionStart":
            session_starts += 1
        if "brainBootstrap" in summary:
            bootstrap_total += 1
            if "outcome: ok" not in summary and "outcome:ok" not in summary.replace(" ", ""):
                bootstrap_degraded += 1

kb_query_events = 0
l0l1_queries = 0
for ledger in brain_root.glob("projects/*/.meta/brain-audit-log.jsonl"):
    if not ledger.is_file():
        continue
    for line in ledger.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not in_window(ev.get("ts")):
            continue
        if ev.get("event_type") == "kb_query":
            kb_query_events += 1
            depth = str(ev.get("ladder_depth") or "")
            if depth in ("L0", "L1"):
                l0l1_queries += 1

entrypoint_episodes = max(session_starts, 1)
l0l1_pct = round(100.0 * l0l1_queries / entrypoint_episodes, 1)
if session_starts == 0:
    l0l1_pct = 0.0 if l0l1_queries == 0 else 100.0

bootstrap_den = max(bootstrap_total, session_starts, 1)
bootstrap_degraded_pct = round(100.0 * bootstrap_degraded / bootstrap_den, 2)
if bootstrap_total == 0:
    bootstrap_degraded_pct = 0.0

slo_l0l1 = "yes" if l0l1_pct >= 80.0 else "no"
slo_bootstrap = "yes" if bootstrap_degraded_pct < 1.0 else "no"

ts_utc = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
print(
    f"{ts_utc} | {window_hours} | {session_starts} | {l0l1_pct} | "
    f"{bootstrap_degraded_pct} | {kb_query_events} | {slo_l0l1} | {slo_bootstrap}"
)
PY
}

ensure_header
ROW="$(compute_row)"
printf '%s\n' "$ROW" >> "$SINK"
echo "brain-efficiency-audit-rollup: appended row to $SINK"
echo "$ROW"
