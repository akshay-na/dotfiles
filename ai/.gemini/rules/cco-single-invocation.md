# cco single-invocation contract

## Repo hygiene (optional)

There is **no** dedicated content KB git loop. See **`rules/repo-hygiene.md`**: optional `git pull` only for the **active** workspace when its files are git-tracked.

## Inbound (discriminated by `action`)

- **`start`:** `run_id` (UUID), `channels[]`, optional `source_idea` or `brief_path`, optional `slug`, `correlation_id`, `event_id`, optional **`project_root`** (absolute path — resolves **`<content-brain>`** per `rules/project-identity.md` when `GEMINI_CONTENT_BRAIN` unset).
- **`continue`:** `run_id`, optional `canonical_url`, publish metadata, `event_id`, optional **`project_root`** (same resolution as `start`).
- **`revise`:** `run_id`, `revision_notes`, optional `user_edited_paths[]`, optional `reset`, `event_id`, optional **`project_root`**.
- **`abort`:** `run_id`, `reason`, `event_id`.

If both `source_idea` and `brief_path` are missing on `start`, `cco` must enter **topic-discovery mode**:
1. Read recent state (`~/.gemini/memory/pipelines/current-state.md`, published ledger under `<content-brain>/published/`, topic index, metrics under `<content-brain>/analytics/`).
2. Select one concrete topic for requested channels.
3. Write/derive brief material and continue full pipeline in the same run.

Channel aliases for routing:
- `instagram` -> `editor-shorts`
- `reels` -> `editor-shorts`

## Idempotency

Duplicate `(run_id, event_id)` → no-op or safe replay per last successful outbound hash recorded under `~/.gemini/memory/pipelines/runs/<run_id>.md` (or JSON sidecar).

## METRICS_READ (mandatory)

Before **BRIEF**: read `<content-brain>/analytics/metrics-current.json` and `<content-brain>/analytics/metrics-latest.md` (`rules/content-brain-paths.md`). If missing, log `metrics_snapshot_read` with `stale: true` in `~/.gemini/memory/observability/events.jsonl`. Before **DRAFT** on long runs (>1h wall clock or `action: continue` / `revise`): repeat METRICS_READ once.

## Caveman

Internal persona→persona: **`skills/caveman/SKILL.md`** (`ultra` default). **Never** put caveman inside `CcoRunReport` JSON or user-visible `summary`.

## Forbidden

- Exposing `agents/internal/*` as separate production HTTP agents.
- Publishing without FSM `awaiting_user` → approved `continue` (unless emergency override in disaster runbook).
