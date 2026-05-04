# Orchestration — phase DAG (`cco`)

## Parallelism first

Maximise parallel fan-out where paths are disjoint. **Serial gates** only where predicates require all upstream artefacts.

## Phase DAG (canonical ids)

| Phase id | Parallel group | Typical internal personas | Allowed KB writes (high level) |
|----------|----------------|----------------------------|--------------------------------|
| `INTAKE` | G0 | (cco) | `memory/pipelines/`, observability |
| `RESEARCH` | G1 | `vp-research`, `cmo` | `kb/20-Ideas/`, `kb/70-Topics/` reads |
| `BRIEF` | G2 | `cmo`, `vp-brand`, `vp-editorial` | `kb/30-Briefs/` |
| `DRAFT` | G3 (parallel per channel) | `editor-blog`, `editor-twitter`, `editor-linkedin`, `editor-shorts`, `editor-newsletter` | `kb/40-Drafts/<channel>/` only for each |
| `QA_SERIAL` | G4 | `qa-content` | annotations under draft paths, QA scratch in `memory/pipelines/runs/` |
| `BRAND_COMPLIANCE` | G5 (parallel) | `vp-brand`, `ciso-content` | read-mostly; findings → memory / QA notes |
| `AWAITING_USER` | — | (cco) | FSM pause; emit `cco.run.awaiting_user` |
| `PUBLISH` | G6 | `archivist`, `kb-librarian` | `kb/50-Published/`, `kb/_meta/`, ledger |
| `REPURPOSE` | G7 | `repurposer` | `kb/60-Repurposed/` |

## METRICS_READ gates

1. Immediately after **start-of-run** `git pull` on the content repo (`rules/repo-hygiene.md`), before `BRIEF`.
2. Again before `DRAFT` when resuming `continue` or `revise`, or if wall time exceeded policy.

Append **`metrics_snapshot_read`** audit line each time.

## Forbidden parallel pairs

Any two steps that write the same `_meta/*.json` row concurrently — serialize via `kb-lock.sh`. Draft channels remain disjoint by path.

## Failure classes

- `retryable` — rate limits, transient network (bounded backoff).
- `needs_human` — policy ambiguity, merge conflict.
- `fatal` — unrecoverable; write `memory/pipelines/failures/<run_id>-<ts>.md`, emit `cco.run.failed`, set FSM `failed`.

## Checkpoints (revise)

Safe resume: `post_brief`, `post_all_drafts`, `post_qa`. On `action: revise`, re-run from `last_checkpoint` downstream unless `reset: true`.

## Observability

On every `phase_enter`, `phase_exit`, and `handoff`: append one NDJSON line per `rules/inter-persona-observability.md`.
