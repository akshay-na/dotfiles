---
name: cro-loop
description: Two-pass plan-critic loop (`cro`); ledger schema, adversarial rubric, bounce rubric, caps, observability stages.
version: 1.1
---

# CRO loop (`cro`)

Encodes the **singleton, execution-boundary** plan-critic loop for **any planning-episode owner** (typically `cto`; also `n8n-builder` / `remotion-builder` per their gates, or surrogate `cto`). After the owner has the **complete plan v0** — **persisted** under `<project>/.cursor/docs/plans/*.md` (or builder path) **or** **prompt-only** (final text in chat) — plus the **post–v0 edit round**, the owner invokes the loop **exactly once** when the user signals **implement / execute / proceed with implementation** — **before** `tech-lead` or implementers. Inside the loop, `cro` runs twice (pass 1 → owner substantive patch toward v1 → pass 2 → owner toward v2); **`cro` appends `## CRO pass <n>`** after **each** pass when the plan is on disk. **Not interleaved** with drafting v0; **at most one** loop per episode. See [`cro`](../../agents/cro.md), [`agent-orchestration`](../../rules/agent-orchestration.mdc).

## Purpose

- Pass 1: **breadth + structural adversarial** review of complete plan v0 + specialist bundle; apply **Adversarial dimensions** checklist; non-null **`bounce_target`** → **owner MUST `Task`** within caps (**automatic** = mandatory owner queue). **`cro` MAY** issue **≤2** read-only clarification **`Task`s** per pass to **`ciso`**, **`sre-lead`**, or **`staff-engineer`** only; **`cro` MUST NOT** `Task` **`vp-*`**. After pass 1, **`cro` appends** **`## CRO pass 1`** to persisted `plan_path` (append-only).
- Pass 2: **residual risk + freeze compliance + v1-regression scan** on plan v1 + ledger; **frozen** finding IDs MUST NOT be re-raised; same **`bounce_target` / clarification / `vp-*` ban / plan-append** rules; **`cro` appends** **`## CRO pass 2`** after pass 2.
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
- **`cro` plan append:** after each pass, **`cro`** appends **`## CRO pass <n>`** to the persisted plan file (append-only; see [`cro`](../../agents/cro.md)); **tool edits before** final YAML envelope in the `Task` turn (subagent-response-protocol).
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

- **Domain gap / wrong specialist coverage** → set `bounce_target`; **planning-episode owner MUST `Task`** each non-null id within caps (**automatic** = non-optional owner work). **`cro` MUST NOT** `Task` **`vp-*`**.
- **Read-only clarification** (bounded, when brokers insufficient) → **`cro` MAY `Task`** **`ciso`**, **`sre-lead`**, or **`staff-engineer`** only, **≤2** / pass (see **Caps**). Prefer `vp-research` / `atlassian-pm` when they suffice.
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
| **`bounce_target` owner `Task`s**  | ≤ 2 / pass (mandatory queue when non-null) |
| **`cro` clarification `Task`s**    | ≤ 2 / pass to `ciso` \| `sre-lead` \| `staff-engineer` only |
| Passes                             | 2 max                                  |

**Bounce vs shard precedence:** When `bounce_target` owner `Task`s would run concurrently with an inflight shard group (`tech-lead` intra-role fan-out per `swarm-task-decomposition`), **planning-episode owner** **serializes** those bounce dispatches **after** that group completes **or** documents explicit precedence in `critic-ledger.md`. **`tech-lead`** logs the overlap case in `dispatch-audit.md` per **`tech-lead.md`** (`parallelism: partial`, `swarm_override_reason: bounce_overlap`; row shape only there).

On `vp-research` skip: mark finding `degraded`, continue. On envelope malformed: owner one reformat retry → protocol stub.

## Observability

Use [`agent-observability`](../agent-observability/SKILL.md):

- **`log_metric`** stage `cro.pass.1` | `cro.pass.2` with fields: `raised`, `bounced`, `accepted`, `frozen`, `degraded_skip`, `pass_duration_ms`, `plan_hash`.
- **`log_decision`** for freeze, bounce, and degraded skip.

## Cross-links

- Envelope contract: [`subagent-response-protocol`](../subagent-response-protocol/SKILL.md)
- Default owner / planning swarm: [`cto`](../../agents/cto.md)
