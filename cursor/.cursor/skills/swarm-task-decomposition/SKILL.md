---
name: swarm-task-decomposition
description: CTO/tech-lead helper — split work into disjoint shard briefs with caps (instance_cap, partition_basis, determinism keys).
version: 1
---

# Swarm Task Decomposition (thin skill)

Consumers: `cto` (planning swarm grouping), `tech-lead` (execution fan-out).

## Contract

Follow `templates/agent-task-spec-v1.yml.tmpl`:

- Respect `routing-table.yml` + `verification-gates.yml` swarm defaults.
- Mark `depends_on_tasks[]` honestly to block illicit background dispatch.

## Outputs

Emit **only shard brief refs** pointing at plan rows / YAML fragments — avoid duplicating codebase text (anti-dup).

## Strict consistency rules

- Always emit deterministic shard ordering by `task_id` lexical ascending.
- Enforce `touch-write.yml` quotas when shard includes ai-brain touch-write tasks.
- Never emit shard payloads exceeding per-touch byte cap; use refs.

