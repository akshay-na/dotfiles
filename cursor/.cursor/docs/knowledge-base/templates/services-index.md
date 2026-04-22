---
title: "Services Index: {{project_name}}"
type: index
project: {{project_name}}
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/type/index
generated_at: {{timestamp}}
generated_by: kb-engineer
stale: false
---

# Services Index: {{project_name}}

Back to [[{{project_name}}|{{project_name}}]].

> Navigation scaffolding. Excluded from the Obsidian graph (`-file:_index`) to keep the graph focused on content nodes. Contains the topology table + mermaid used by the `service-topology` query type (Level 1, ~200 tokens).

## Services

| Service | Sources | Port | Protocol | Upstream | Downstream |
|---------|---------|------|----------|----------|------------|
{{services_topology_table}}

Budget: this doc stays under ~300 tokens.

## Topology

```mermaid
{{services_topology_mermaid}}
```

## All Services

{{all_service_backlinks}}
