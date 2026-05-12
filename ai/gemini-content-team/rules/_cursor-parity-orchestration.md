# Cursor ↔ Gemini orchestration parity

Canonical **payload**, **phase DAG**, **automation gates**, and **n8n / git** behavior live in:

- **`agent-orchestration.md`** — entrypoints, execution approval, brain, tool boundaries, swarm / multitask pointers.
- **`orchestration.md`** — parallelism first, phase ids, METRICS_READ, automation gate signals, failure classes.

This file records **deltas** between Cursor IDE workflows and **Gemini CLI**, plus a maintainer checklist so the two packs do not drift.

## Path and mechanism deltas

| Topic | Cursor (content tech path) | This pack (Gemini) |
|--------|------------------------------|---------------------|
| Plan on disk | `<project>/.cursor/docs/plans/` | `<project>/.gemini/docs/plans/` |
| Child invoke | Cursor **`Task`** tool | **`dispatch`** (Gemini CLI agent delegation per **`mode-auto-selection.md`**) |

**Artifact contract** (`content-post-artifact-v1`): schema at **`contracts/schemas/content-post-artifact.schema.json`**; operational fields summarized in **`../agents/content-lead.md`** § Automation output contract — do not duplicate field lists here.

## Gemini vs Cursor telemetry

Gemini CLI has **no** Cursor JSONL hook telemetry substrate (`~/.cursor/hooks/telemetry-*.sh` is **Cursor-only**). Coordinators rely on **`agent-observability`** metrics + brain ledger writes; append **`swarm_override_reason`** / optional **`multitask_override_reason`** to **`~/ai-brain/org/global/orchestration/dispatch-audit.md`** when applicable (same cross-pack sink as tech pack).

## Parity checklist (orchestration)

- ☑ Automation gate signals mirrored (`rules/orchestration.md`).
- ☑ Corpus boundary + entrypoints mirrored (`rules/agent-orchestration.md`).
- ☑ Cross-pack swarm audit + `dispatch-audit.md` pointer mirrored (`agent-orchestration.md` § Swarm audit).
- ☑ Gemini hook/telemetry gap documented (§ Gemini vs Cursor telemetry).
- ☑ Multitask default + user-visible serial justification mirrored (`rules/orchestration.md`, `rules/agent-orchestration.md`, tech pack § Multitask default).
