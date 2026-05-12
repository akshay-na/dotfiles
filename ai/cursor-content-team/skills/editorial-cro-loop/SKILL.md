---
name: editorial-cro-loop
description: Two-pass CCO plan-critic loop owned by editorial-cro; ledger schema, editorial bounce rubric, caps, observability stages. Content org only — no Atlassian.
version: 1
---

# Editorial CRO loop (`editorial-cro`)

Singleton **execution-boundary** critic: after the **planning-episode owner** (typically **`cco`**) has **plan v0** — **persisted** **or** **prompt-only** — **post–v0 edit round**, and user signals **execution intent**, invoke **once**. Passes: `editorial-cro` pass 1 → **owner** patches v1 → pass 2 → **owner** patches v2 — **before** **`content-lead`**. See [`editorial-cro`](../../agents/editorial-cro.md), [`agent-orchestration`](../../rules/agent-orchestration.mdc).

## Purpose

- Pass 1: **breadth + structural adversarial** on v0 + bundle; full **Adversarial dimensions**; owner-only bounces.
- Pass 2: **residual + freeze compliance + v1-regression scan**; **frozen** IDs not re-litigated; explicit scan for **new** editorial/regression issues from v1 patches.
- **At most one** live loop per `task_id`; second concurrent = contract violation → **owner** rejects.
- **Owner multitask:** **`cco`** should dispatch independent **`bounce_target`** specialists in **parallel** when safe; if **serialized** when parallel was feasible, give a **one-line user-visible reason** — see **`agent-orchestration.mdc`** multitask bullet.

## Inputs

| Field | Description |
|-------|-------------|
| Plan draft | Path + hash **or** prompt-only body (stable excerpt) |
| `specialist_bundle_refs[]` | Specialist bundle refs from **owner** |
| `pass_number` | `1` or `2` |
| `ledger_path` | `~/ai-brain/session/cursor-<task-id>/critic-ledger.md` |
| `frozen_finding_ids[]` | Pass 2 only |

## Outputs

- **`findings[]`** in **subagent-response-protocol** envelope.
- Ledger delta rows for **owner** to append.
- Metrics: **`editorial-cro.pass.1`** | **`editorial-cro.pass.2`**.

## Ledger schema

Table columns:

| Column | Description |
|--------|-------------|
| `finding_id` | Stable e.g. `edcro-001` |
| `pass_raised` | `1` or `2` |
| `category` | `claim-fact`, `pii-consent`, `channel-policy`, `brand-voice`, `metric-schema`, `registry-index`, `wikilink-graph`, `repurpose-lineage`, `coherence`, `ia`, `repo-alignment`, `rollback-process`, … |
| `bounce_target` | `vp-editorial-architecture`, `cpo`, `staff-editor`, … or `-` |
| `status` | `open` \| `frozen_accepted` \| `frozen_open_risk` \| `degraded` |
| `evidence_ref` | `vp-research` ref, memory ref, **repo path#line**, or `-` if degraded |
| `resolved_in_plan_section` | anchor or `-` |

## Decision rubric

- **Domain gap** → `bounce_target` set; **owner** `Task`s specialist; **no** lateral `Task` from `editorial-cro`.
- **Coherence / phases** → self-resolve; external facts → **`vp-research`**; corpus facts → cite **repo path**, **schema/registry** lines, or **memory/KB**.
- **No `atlassian-pm`** in content org.

## Adversarial dimensions (editorial checklist)

- **Claims / PII / consent** — sourcing, privacy copy, regulated claims.
- **Channel policy / fit** — limits, disclosures, platform-sensitive patterns.
- **Brand / voice drift** vs playbook + corpus norms (evidence).
- **Metric / schema / registry / graph** — `metrics/`, `_schema`, `00-INDEX`, wikilinks.
- **Repurposing / lineage** — `parent_id`, recycle, cross-channel consistency.
- **Coherence / editorial DAG** — draft/staging/publish ordering; content vs asset dependencies.
- **Rollback / human process** — promotion gates, undo semantics, experiment observability.

## Pass differentiation

| Pass | Focus |
| ---- | ----- |
| **1** | Full rubric on **v0**; editorial bounces within budget. |
| **2** | Frozen IDs respected; residual non-frozen; **v1 vs v0** regression (new claims, channel scope, index/registry gaps from patches). |

## Conditional minimum bar (`findings[]`)

**Triggers (any):** multi-phase plan; **or** staging/publish promotion; **or** metrics/schema/registry/graph edits; **or** cross-channel repurpose; **or** high-liability/regulated claims.

When triggered, each pass **SHOULD** address themes: **claims/privacy**, **channel+voice**, **corpus automation** (schema/registry/index), **lineage** — combine or mark N/A with reason.

**Trivial single-step** low-risk draft: no minimum count; stay proportional.

## Caps

| Limit | Value |
|-------|--------|
| Loop instances | **1** / planning episode |
| Wall | 420s |
| `vp-research` | ≤ 3 / loop |
| Bounces | ≤ 2 / pass (**owner**) |
| Passes | 2 |

## Observability

[`agent-observability`](../agent-observability/SKILL.md): stages **`editorial-cro.pass.1`**, **`editorial-cro.pass.2`**.

## Cross-links

- [`subagent-response-protocol`](../subagent-response-protocol/SKILL.md)
- [`cco`](../../agents/cco.md)
