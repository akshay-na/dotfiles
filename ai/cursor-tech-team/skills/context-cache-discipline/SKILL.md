---
name: context-cache-discipline
description: Token and prompt-cache discipline — lean always-on rules, stable prefixes, skill indirection, minimal Task payloads, bounded reads.
version: 1
---

# Context and cache discipline

Use this skill when orchestrating or editing the pack so **context stays small** and **early prompt prefixes stay stable** (better cache hit odds on providers; always fewer input tokens).

## Principles

| Goal | Practice |
|------|----------|
| Stable prefix | Prefer **one** canonical copy of long text in **skills**; rules **point** — avoid churn in `alwaysApply: true` bodies. |
| Lean always-on | Rarely needed norms → `alwaysApply: false` + `globs`, or load skill on demand. |
| Indirection | Agents/rules cite skill path; **do not** paste full playbooks into rules or agent bodies. |
| Task payloads | Parent **`Task` prompts**: goal, constraints, **`approved_plan_path`**, phase/shard id, **`touches[]`**, correlation ids — **not** full rules or transcripts. |
| Reads | Batch parallel **`Read`** where independent; **one read per file** per turn unless content changed; lookup-first for **`brain-memory-kb`**. |
| Subagent traffic | Children: **caveman-ultra** + single YAML envelope per `templates/subagent-response.yml.tmpl`; parents: **do not** paste raw child YAML to user. |

**Non-claim:** Exact cache eligibility is vendor-defined; token reduction is always a win.

## When to load what

- Routing, swarm, routing table, **Task payload caps**: [`task-orchestration`](./task-orchestration/SKILL.md)
- Memory/KB + git-backed brain sync: [`brain-memory-kb`](./brain-memory-kb/SKILL.md)
- Docs / HTTP / web / Context7: **rule** `vp-research.mdc` (single broker); never duplicate broker bullets elsewhere
- Envelope + parent parse: [`subagent-response-protocol`](./subagent-response-protocol/SKILL.md) + `templates/subagent-response.yml.tmpl`
- Metrics + optional **`token_stats`**: [`agent-observability`](./agent-observability/SKILL.md)

## Forbidden

- Pasting full `alwaysApply` rule bodies into chat to “teach” a subagent
- Re-fetching the same skill/rule in one turn without reason
- Oversized inline blobs in `Task` (anti-dup hook is fail-closed)
