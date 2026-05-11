# Orchestration — phase DAG (`cco`)

## Parallelism first

Maximise parallel fan-out where paths are disjoint. **Serial gates** only where predicates require all upstream artefacts.

## Phase DAG (canonical ids)

| Phase id | Parallel group | Typical internal personas | Allowed KB writes (high level) |
|----------|----------------|----------------------------|--------------------------------|
| `INTAKE` | G0 | (cco) | `~/.gemini/memory/pipelines/`, `~/.gemini/memory/observability/` |
| `TOPIC_DECISION` | G0b | `vp-research`, `cmo` | brief seed notes / run summary pointers |
| `RESEARCH` | G1 | `vp-research`, `cmo` | `<content-brain>/ideas/`, `<content-brain>/topics/` reads (`rules/brain-paths.md`) |
| `BRIEF` | G2 | `cmo`, `vp-brand`, `vp-editorial` | `<content-brain>/briefs/` |
| `DRAFT` | G3 (parallel per channel) | `editor-blog`, `editor-twitter`, `editor-linkedin`, `editor-shorts` (incl. instagram/reels), `editor-newsletter` | `<content-brain>/drafts/<channel>/` only for each |
| `QA_SERIAL` | G4 | `qa-content` | annotations under draft paths, QA scratch in `~/.gemini/memory/pipelines/runs/` |
| `BRAND_COMPLIANCE` | G5 (parallel) | `vp-brand`, `ciso-content` | read-mostly; findings → `~/.gemini/memory/` / QA notes |
| `AWAITING_USER` | — | (cco) | FSM pause; emit `cco.run.awaiting_user` |
| `PUBLISH` | G6 | `archivist`, `kb-librarian` | `<content-brain>/published/`, `<content-brain>/_meta/`, ledger |
| `REPURPOSE` | G7 | `repurposer` | `<content-brain>/repurposed/` |

## METRICS_READ gates

1. Immediately after **start-of-run** optional workspace `git pull` when git-tracked (`rules/repo-hygiene.md`), before `BRIEF`.
2. Again before `DRAFT` when resuming `continue` or `revise`, or if wall time exceeded policy.

Append **`metrics_snapshot_read`** audit line each time.

## Topic discovery mode

When `action:start` has no `source_idea` and no `brief_path`, run `TOPIC_DECISION` before `RESEARCH`:

1. Choose one topic for the requested channels using metrics + recent published/draft state.
2. Record the chosen topic in run summary memory so downstream personas use a single canonical direction.
3. Continue normal flow (`RESEARCH` -> `BRIEF` -> `DRAFT` ...).

## Forbidden parallel pairs

Any two steps that write the same `_meta/*.json` row concurrently — serialize via orchestration (single-writer phase for `_meta/` or explicit `archivist` / `kb-librarian` coordination). Draft channels remain disjoint by path.

## Failure classes

- `retryable` — rate limits, transient network (bounded backoff).
- `needs_human` — policy ambiguity, merge conflict.
- `fatal` — unrecoverable; write `~/.gemini/memory/pipelines/failures/<run_id>-<ts>.md`, emit `cco.run.failed`, set FSM `failed`.

## Checkpoints (revise)

Safe resume: `post_brief`, `post_all_drafts`, `post_qa`. On `action: revise`, re-run from `last_checkpoint` downstream unless `reset: true`.

## Observability

On every `phase_enter`, `phase_exit`, and `handoff`: append one NDJSON line per `rules/inter-persona-observability.md`.

## Automation gate signals

Automation (**`execution_mode: automation`**) honors **plan-declared structured signals only** — PR merge, approval webhook, or **idempotency-keyed** payload field (e.g. `correction_enqueue_mode`, `push_after_commit`). **Never** infer approval from silence or generic affirmations. Plans must enumerate the gate event for each automated stage.
