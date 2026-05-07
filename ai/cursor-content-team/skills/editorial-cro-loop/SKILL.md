---
name: editorial-cro-loop
description: Two-pass CCO plan-critic loop owned by editorial-cro; ledger schema, editorial bounce rubric, caps, observability stages. Content org only — no Atlassian.
version: 1
---

# Editorial CRO loop (`editorial-cro`)

Singleton **post-plan** critic: after **`cco`** writes **plan v0** to `<project>/.cursor/docs/plans/*.md`, invoke **once**. Passes: `editorial-cro` pass 1 → **`cco`** patches v1 → pass 2 → **`cco`** patches v2. See [`editorial-cro` agent](../../agents/editorial-cro.md) and [`agent-orchestration`](../../rules/agent-orchestration.mdc) (content pack).

## Purpose

- Pass 1: review plan v0 + specialist bundle; bounces only **`cco`** issues `Task`s.
- Pass 2: v1 + ledger; **frozen** `finding_id` values MUST NOT be re-raised.
- **At most one** live loop per `task_id`; second concurrent = contract violation → **`cco`** rejects.

## Inputs

| Field | Description |
|-------|-------------|
| Plan draft | Path + hash or body |
| `specialist_bundle_refs[]` | Specialist bundle refs from **`cco`** |
| `pass_number` | `1` or `2` |
| `ledger_path` | `~/.cursor/ai-brain/session/<task-id>/critic-ledger.md` |
| `frozen_finding_ids[]` | Pass 2 only |

## Outputs

- **`findings[]`** in **subagent-response-protocol** envelope.
- Ledger delta rows for **`cco`** to append.
- Metrics: **`editorial-cro.pass.1`** | **`editorial-cro.pass.2`**.

## Ledger schema

Table columns:

| Column | Description |
|--------|-------------|
| `finding_id` | Stable e.g. `edcro-001` |
| `pass_raised` | `1` or `2` |
| `category` | brand-voice, claim, channel-fit, legal-privacy, coherence, repo-alignment, ia, … |
| `bounce_target` | `vp-editorial-architecture`, `cpo`, `staff-editor`, … or `-` |
| `status` | `open` \| `frozen_accepted` \| `frozen_open_risk` \| `degraded` |
| `evidence_ref` | `vp-research` ref, memory ref, **repo path#line**, or `-` if degraded |
| `resolved_in_plan_section` | anchor or `-` |

## Decision rubric

- **Domain gap** → `bounce_target` set; **`cco`** `Task`s specialist; **no** lateral `Task` from `editorial-cro`.
- **Coherence / phases** → self-resolve; external facts → **`vp-research`**; corpus facts → cite **repo/workdir** or **memory/KB**.
- **No `atlassian-pm`** in content org.

## Caps

| Limit | Value |
|-------|--------|
| Loop instances | **1** / planning episode |
| Wall | 420s |
| `vp-research` | ≤ 3 / loop |
| Bounces | ≤ 2 / pass (**`cco`**) |
| Passes | 2 |

## Observability

[`agent-observability`](../agent-observability/SKILL.md): stages **`editorial-cro.pass.1`**, **`editorial-cro.pass.2`**.

## Cross-links

- [`subagent-response-protocol`](../subagent-response-protocol/SKILL.md)
- [`cco`](../../agents/cco.md)
