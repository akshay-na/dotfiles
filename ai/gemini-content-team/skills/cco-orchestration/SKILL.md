---
name: cco-orchestration
description: Executable checklist for one cco pipeline run (parallel groups, METRICS_READ, audit NDJSON, n8n gates).
---

# cco orchestration checklist

Read `rules/orchestration.md`, `rules/repo-hygiene.md`, `rules/project-identity.md`, `skills/project-identity/SKILL.md`, `rules/brain-paths.md`, `rules/brain-conventions.md`, and `rules/cco-single-invocation.md` first.

## Start of run

0. Resolve **`<content-brain>`** per **`rules/project-identity.md`** (same **`~/ai-brain/projects/<project_name>/`** as Cursor **`kb-identity`**).
1. Parse inbound JSON; validate `run_id`, `action`, `event_id` idempotency.
2. Optional **`git pull`** for active workspace per `rules/repo-hygiene.md` when using git-tracked brain or project files.
3. **METRICS_READ** — load **`<content-brain>/analytics/metrics-current.json`**, **`metrics-latest.md`**; append `metrics_snapshot_read` to `~/.gemini/memory/observability/events.jsonl`.
4. Load pipeline state (`~/.gemini/memory/pipelines/current-state.md`); align FSM with `action`.
5. Append `phase_enter` audit for current phase.

## Per phase

- Execute **parallel group** personas (see orchestration table); internal comms: caveman `ultra` except security-autoclarity.
- After each handoff between personas: append `handoff` audit (hashes not bodies).
- On phase completion: `phase_exit` audit.
- **No mid-pipeline hand-holding:** do not end a turn by telling the operator to run **`cco`** again or to “start BRIEF” manually. After RESEARCH, enter **BRIEF** (`cmo`, `vp-brand`, `vp-editorial` per orchestration) in the same invocation / continued session until **`awaiting_user`**.

## Human gate

- When drafts + QA complete: set FSM `awaiting_user`; emit **`cco.run.awaiting_user`** with `CcoRunReport` JSON only.

## Continue / revise

- `continue`: METRICS*READ if policy says so; archivist when publish metadata present; `phase*\*` audits.
- `revise`: jump to `last_checkpoint` from run record; re-run downstream; emit `cco.run.revision_applied` when done.

## End

- Success: `cco.run.completed`, ledger consistent under **`<content-brain>/_meta/`**; commit via normal git if applicable.
- Failure: `~/.gemini/memory/pipelines/failures/<run_id>-<ts>.md`, `cco.run.failed`, FSM `failed`.

## Forbidden

Third production external agent; caveman in outbound JSON; skipping QA before `awaiting_user`.
