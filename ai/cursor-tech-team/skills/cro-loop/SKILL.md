---
name: cro-loop
description: Two-pass plan-critic loop (`cro`); ledger schema, adversarial rubric, bounce rubric, caps, observability stages.
version: 1
---

# CRO loop (`cro`)

Encodes the **singleton, execution-boundary** plan-critic loop for **any planning-episode owner** (typically `cto`; also `n8n-builder` / `remotion-builder` per their gates, or surrogate `cto`). After the owner has the **complete plan v0** — **persisted** under `<project>/.cursor/docs/plans/*.md` (or builder path) **or** **prompt-only** (final text in chat) — plus the **post–v0 edit round**, the owner invokes the loop **exactly once** when the user signals **implement / execute / proceed with implementation** — **before** `tech-lead` or implementers. Inside the loop, `cro` runs twice (pass 1 → owner revises to v1 → pass 2 → owner revises to v2). **Not interleaved** with drafting v0; **at most one** loop per episode. See [`cro`](../../agents/cro.md), [`agent-orchestration`](../../rules/agent-orchestration.mdc).

## Purpose

- Pass 1: **breadth + structural adversarial** review of complete plan v0 + specialist bundle; apply **Adversarial dimensions** checklist; findings may bounce **through owner only**.
- Pass 2: **residual risk + freeze compliance + v1-regression scan** on plan v1 + ledger; **frozen** finding IDs MUST NOT be re-raised or re-litigated; **explicitly** scan for **new** second-order issues introduced by v1 patches vs v0.
- Singleton invariant: one live loop per planning episode `task_id`; second concurrent invocation = contract violation → **owner** rejects.

## Inputs

| Field                      | Description                                     |
| -------------------------- | ----------------------------------------------- |
| Plan draft                 | Path + hash **or** prompt-only markdown body (stable excerpt for `Task`) |
| `specialist_bundle_refs[]` | Aggregated specialist outputs / shard refs      |
| `pass_number`              | `1` or `2`                                      |
| `ledger_path`              | `~/ai-brain/session/cursor-<task-id>/critic-ledger.md` |
| `frozen_finding_ids[]`     | Pass 2 only; monotonic freeze list from ledger  |

## Outputs

- Per-pass `findings[]` inside **subagent-response-protocol** envelope (`status`, `summary`, `next_actions`, …).
- **Ledger delta**: rows to append under the pass section (**planning-episode owner** appends after parse).
- Metrics: stage **`cro.pass.1`** / **`cro.pass.2`** on `session.current.metric.<task_id>` (see Observability).

## Ledger schema

File: `critic-ledger.md`. Start with a schema version line, then sections **Pass 1** / **Pass 2**.

Table columns:

| Column                     | Description                                                            |
| -------------------------- | ---------------------------------------------------------------------- |
| `finding_id`               | Stable id (e.g. `cro-001`); never reused across passes for a new issue |
| `pass_raised`              | `1` or `2`                                                             |
| `category`                 | e.g. coherence, architecture, security, perf                           |
| `bounce_target`            | Specialist id or `-` if none                                           |
| `status`                   | `open` \| `frozen_accepted` \| `frozen_open_risk` \| `degraded`        |
| `evidence_ref`             | `vp-research` ref, memory ref, or `-` if degraded                      |
| `resolved_in_plan_section` | Heading anchor or `-`                                                  |

## Decision rubric

- **Domain gap / wrong specialist coverage** → `bounce_target` set; owner `Task`s specialist; **never** lateral `Task` from `cro`.
- **Coherence, missing phase, DAG smell** → internal reasoning first. Factual claims require a broker: **`vp-research`** (external) or **`atlassian-pm`** `mode=read-only-context` (tickets/pages). Both skip → `degraded`, no unsubstantiated challenge.

## Adversarial dimensions (structured checklist)

Scan each pass along these axes (ground facts per brokers; pure structure may be internal):

- **Loopholes / escape hatches** — silent prod, weak approvals, undefined ownership for destructive steps.
- **Second-order / post-implementation effects** — partial failure, blast radius, operator toil, cost/latency drift, non-idempotent “fix forward only.”
- **Coherence / phase DAG** — `depends_on` vs narrative, verification vs `touches`, unsafe parallelism.
- **Rollback / observability** — revert artifact, proof of success, signals for regression; who runs rollback.
- **Dependency / version / migration** — skew, schema forward-only steps, cutover strategy, pin discipline.
- **Human / process** — runbook/on-call, checkpoint semantics vs actual risk, unstated handoffs.

## Pass differentiation

| Pass | Primary focus |
| ---- | ------------- |
| **1** | Full rubric on **v0**; breadth; structural + domain gaps; bounce budgeting. |
| **2** | **No** re-open frozen `finding_id`s; residual open rows; **v1 vs v0 regression** (new loopholes/second-order/coherence breaks from patches). |

## Conditional minimum bar (`findings[]`)

When **any** trigger holds: plan has **≥2** implementation phases or non-trivial DAG; **or** destructive / hard-to-reverse work; **or** prod-touched scope; **or** security-adjacent surface; **or** migration / cross-version / schema impact — each pass **SHOULD** cover these **themes** (combine in one finding if evidenced; omit a theme only with explicit “N/A + why”):

| Theme | Ledger `category` hint |
| ----- | ------------------------ |
| Coherence / DAG | `coherence`, `architecture` (graph) |
| Rollback / observability | `observability`, `rollback` |
| Security / compliance-adjacent | `security`, `supply-chain` |
| Domain / coverage | specialist bounce **or** `coverage` with evidence ref |

**Trivial single-step, low-blast, non-prod, non-destructive, non-security:** no artificial minimum count; proportional depth only.

## Caps and degradation

| Limit                              | Value                                  |
| ---------------------------------- | -------------------------------------- |
| Loop instances                     | **1** per planning episode (singleton) |
| Loop wall                          | 420s                                   |
| `vp-research`                      | ≤ 3 calls / loop                       |
| `atlassian-pm` (read-only-context) | ≤ 2 calls / loop                       |
| Bounces                            | ≤ 2 / pass (owner-side)                  |
| Passes                             | 2 max                                  |

On `vp-research` skip: mark finding `degraded`, continue. On envelope malformed: owner one reformat retry → protocol stub.

## Observability

Use [`agent-observability`](../agent-observability/SKILL.md):

- **`log_metric`** stage `cro.pass.1` | `cro.pass.2` with fields: `raised`, `bounced`, `accepted`, `frozen`, `degraded_skip`, `pass_duration_ms`, `plan_hash`.
- **`log_decision`** for freeze, bounce, and degraded skip.

## Cross-links

- Envelope contract: [`subagent-response-protocol`](../subagent-response-protocol/SKILL.md)
- Default owner / planning swarm: [`cto`](../../agents/cto.md)
