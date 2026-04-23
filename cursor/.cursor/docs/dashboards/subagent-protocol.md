# Dashboard — Subagent Response Protocol

Three widgets (D23). Refresh on demand via the one-liners below. Data source:
`~/.cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl`.

## 1. Schema-valid rate (last 7 days)

Target: ≥ 95 % rolling over any 20-response window (plan §10).

```bash
python3 - <<'PY'
import json, pathlib, datetime
p = pathlib.Path.home()/".cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl"
rows = [json.loads(l) for l in p.read_text().splitlines() if l and not l.startswith('#')]
cutoff = (datetime.datetime.utcnow() - datetime.timedelta(days=7)).strftime("%Y-%m-%d")
recent = [r for r in rows if r.get('ts','')[:10] >= cutoff]
total = len(recent)
valid = sum(1 for r in recent if r.get('schema_valid'))
pct = (valid/total*100) if total else 0.0
print(f"n={total}  schema_valid={valid}  rate={pct:.1f}%")
# tiny sparkline per day
by_day = {}
for r in recent:
    d = r.get('ts','')[:10]
    by_day.setdefault(d, [0,0])
    by_day[d][0] += 1
    by_day[d][1] += 1 if r.get('schema_valid') else 0
for d in sorted(by_day):
    n, v = by_day[d]
    print(f"  {d}  {v}/{n}  {'#' * int(v/max(1,n)*20)}")
PY
```

## 2. Token / byte reduction trend (prose baseline vs enforce)

Target: ≥ 60 % median reduction on subagent → parent payloads (plan §10).

```bash
python3 - <<'PY'
import json, pathlib, statistics
p = pathlib.Path.home()/".cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl"
rows = [json.loads(l) for l in p.read_text().splitlines() if l and not l.startswith('#')]
buckets = {}
for r in rows:
    key = r.get('stage') or 'unknown'
    buckets.setdefault(key, []).append(r.get('out_bytes') or 0)
for k, v in buckets.items():
    if not v: continue
    print(f"{k:14} n={len(v)} median_out_bytes={statistics.median(v):.0f} p95={sorted(v)[int(len(v)*0.95)-1]}")
# reduction
if 'observe_warn' in buckets and 'enforce' in buckets:
    b_med = statistics.median(buckets['observe_warn'])
    e_med = statistics.median(buckets['enforce'])
    red = (1 - e_med/max(1,b_med)) * 100
    print(f"reduction_observe_to_enforce={red:.1f}%")
PY
```

Baseline numbers (prose-mode, pre-protocol) live in
`~/.cursor/memory/projects/dotfiles/observability/experiments/token-baseline.md`.

## 3. Top-5 recent failing responses

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home()/".cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl"
rows = [json.loads(l) for l in p.read_text().splitlines() if l and not l.startswith('#')]
fails = [r for r in rows if not r.get('schema_valid')][-5:]
print(f"{'ts':20} {'agent':20} {'stage':14} {'errors'}")
for r in fails:
    errs = '|'.join((r.get('errors') or [])[:2])[:60]
    print(f"{r.get('ts',''):20} {r.get('agent',''):20} {r.get('stage',''):14} {errs}")
PY
```

## Notes

- Per-agent bar and caveman-mix pie intentionally dropped (D23). Regenerate
  on-demand via ad-hoc one-liners.
- Dashboard values go stale between refreshes; rely on alerts in the runbook
  for real-time signals.
