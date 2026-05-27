---
name: swarm-deterministic-merge
description: Deterministic aggregation of shard results — lexical ordering + schema-checked bundle merges.
version: 1
---

# Swarm Deterministic Merge

Input: envelopes matching `templates/agent-result-bundle-v1.yml.tmpl`.

## Rules

1. Sort shards by `task_id` lexical asc.
2. Reject merges if any child envelope malformed twice (parent parse contract).
3. Concatenate summaries; union `artifacts[]` de-duped by ref token or path.
4. Emit merge hash = sha256 over sorted `determinism_hash` list.
5. Reject inline duplicate bodies when equivalent `<REF:...#sha256:...>` already exists.

## Failure isolation

Failed shard → re-dispatch single instance; do not restart healthy shards.

