# cco single-invocation contract

## Repo hygiene (binding)

Every **`cco`** invocation: **start** with `git pull` on `~/content-knowledge-base` and **end** with `bash ~/.gemini/scripts/kb-sync.sh sync` per `rules/repo-hygiene.md` (wrapper runs shell if the model cannot). No periodic LaunchAgent.

## Inbound (discriminated by `action`)

- **`start`:** `run_id` (UUID), `channels[]`, `source_idea` or `brief_path`, optional `slug`, `correlation_id`, `event_id`.
- **`continue`:** `run_id`, optional `canonical_url`, publish metadata, `event_id`.
- **`revise`:** `run_id`, `revision_notes`, optional `user_edited_paths[]`, optional `reset`, `event_id`.
- **`abort`:** `run_id`, `reason`, `event_id`.

## Idempotency

Duplicate `(run_id, event_id)` → no-op or safe replay per last successful outbound hash recorded under `memory/pipelines/runs/<run_id>.md` (or JSON sidecar).

## METRICS_READ (mandatory)

After the **start-of-run** `git pull` / before **BRIEF**: read `kb/90-Analytics/metrics-current.json` and `memory/org/metrics-latest.md`. If missing, log `metrics_snapshot_read` with `stale: true`. Before **DRAFT** on long runs (>1h wall clock or `action: continue` / `revise`): repeat METRICS_READ once.

## Caveman

Internal persona→persona: **`skills/caveman/SKILL.md`** (`ultra` default). **Never** put caveman inside `CcoRunReport` JSON or user-visible `summary`.

## Forbidden

- Exposing `agents/internal/*` as separate production HTTP agents.
- Publishing without FSM `awaiting_user` → approved `continue` (unless emergency override in disaster runbook).
