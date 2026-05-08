---
name: cro-loop
description: Two-pass CTO plan-critic loop owned by Chief Risk Officer (`cro`); ledger schema, bounce rubric, caps, observability stages.
version: 1
---

# CRO loop (`cro`)

Encodes the **singleton, post-plan** plan-critic loop. After `cto` has consulted specialists and written the **complete plan v0** to `<project>/.cursor/docs/plans/*.md`, it invokes the loop **exactly once**. Inside the loop, `cro` runs twice (pass 1 → CTO revises plan to v1 → pass 2 → CTO revises to v2) before user-visible delivery. The loop is **not interleaved** with drafting; there is **at most one** loop instance per planning episode (no concurrent or nested loops). See [`cro` agent](../../agents/cro.md) and [`agent-orchestration`](../../rules/agent-orchestration.mdc).

## Purpose

- Pass 1: adversarial review of the complete plan v0 + specialist bundle; findings may bounce to specialists **through CTO only**.
- Pass 2: review patched plan v1 + ledger; **frozen** finding IDs from pass 1 MUST NOT be re-raised.
- Singleton invariant: the loop holds the planning episode's `task_id`; any second concurrent invocation is a contract violation and MUST be rejected by CTO.

## Inputs

| Field                      | Description                                     |
| -------------------------- | ----------------------------------------------- |
| Plan draft                 | Markdown body or path + hash                    |
| `specialist_bundle_refs[]` | Aggregated specialist outputs / shard refs      |
| `pass_number`              | `1` or `2`                                      |
| `ledger_path`              | `~/ai-brain/session/<task-id>/critic-ledger.md` |
| `frozen_finding_ids[]`     | Pass 2 only; monotonic freeze list from ledger  |

## Outputs

- Per-pass `findings[]` inside **subagent-response-protocol** envelope (`status`, `summary`, `next_actions`, …).
- **Ledger delta**: rows to append under the pass section (CTO appends after parse).
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

- **Domain gap / wrong specialist coverage** → `bounce_target` set; CTO `Task`s specialist; **never** lateral `Task` from `cro`.
- **Coherence, missing phase, DAG smell** → resolve with internal reasoning. Factual claims require a research broker:
  - External libs / APIs / specs / standards → **`vp-research`** (primary).
  - Existing Jira / Confluence / prior decisions referenced in the plan → **`atlassian-pm`** in `mode=read-only-context` (CRO is on the read allow-list; writes remain off-limits).
  - Both unavailable → `status: degraded`, no unsubstantiated challenge.

## Caps and degradation

| Limit                              | Value                                  |
| ---------------------------------- | -------------------------------------- |
| Loop instances                     | **1** per planning episode (singleton) |
| Loop wall                          | 420s                                   |
| `vp-research`                      | ≤ 3 calls / loop                       |
| `atlassian-pm` (read-only-context) | ≤ 2 calls / loop                       |
| Bounces                            | ≤ 2 / pass (CTO-side)                  |
| Passes                             | 2 max                                  |

On `vp-research` skip: mark finding `degraded`, continue. On envelope malformed: CTO one reformat retry → protocol stub.

## Observability

Use [`agent-observability`](../agent-observability/SKILL.md):

- **`log_metric`** stage `cro.pass.1` | `cro.pass.2` with fields: `raised`, `bounced`, `accepted`, `frozen`, `degraded_skip`, `pass_duration_ms`, `plan_hash`.
- **`log_decision`** for freeze, bounce, degraded skip, and model fallback (`decision` row schema: `invocation_kind`, `pinned_model`, `fallback_model`, …). Model fallback is **hook-driven only**; CTO does not add extra Task retries across alternate slugs after hooks have fired (see `agent-orchestration.mdc` — no manual dedup fallback ladder).

## Cross-links

- Envelope contract: [`subagent-response-protocol`](../subagent-response-protocol/SKILL.md)
- CTO sequence: [`cto`](../../agents/cto.md) planning swarm
