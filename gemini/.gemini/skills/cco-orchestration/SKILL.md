---
name: cco-orchestration
description: Executable checklist for one cco pipeline run (parallel groups, METRICS_READ, audit NDJSON, n8n gates).
---

# cco orchestration checklist

Read `rules/orchestration.md`, `rules/repo-hygiene.md`, and `rules/cco-single-invocation.md` first.

## Start of run

1. Parse inbound JSON; validate `run_id`, `action`, `event_id` idempotency.
2. **Git pull** on content repo per `rules/repo-hygiene.md` (before any read/write — not optional).
3. **METRICS_READ** — load `kb/90-Analytics/metrics-current.json`, `memory/org/metrics-latest.md`; append `metrics_snapshot_read` to `memory/observability/events.jsonl`.
4. Load pipeline state (`memory/pipelines/current-state.md`); align FSM with `action`.
5. Append `phase_enter` audit for current phase.

## Per phase

- Execute **parallel group** personas (see orchestration table); internal comms: caveman `ultra` except security-autoclarity.
- After each handoff between personas: append `handoff` audit (hashes not bodies).
- On phase completion: `phase_exit` audit.

## Human gate

- When drafts + QA complete: set FSM `awaiting_user`; emit **`cco.run.awaiting_user`** with `CcoRunReport` JSON only.

## Continue / revise

- `continue`: METRICS_READ if policy says so; archivist when publish metadata present; `phase_*` audits.
- `revise`: jump to `last_checkpoint` from run record; re-run downstream; emit `cco.run.revision_applied` when done.

## End

- Success: `cco.run.completed`, ledger consistent, then **`bash ~/.gemini/scripts/kb-sync.sh sync`** (diff-driven; see `rules/repo-hygiene.md`).
- Failure: `memory/pipelines/failures/<run_id>-<ts>.md`, `cco.run.failed`, FSM `failed`, then still run **`kb-sync.sh sync`** so failures and logs reach remote when push works.

## Forbidden

Third production external agent; caveman in outbound JSON; skipping QA before `awaiting_user`.
