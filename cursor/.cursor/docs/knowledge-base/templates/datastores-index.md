---
title: "Datastores Index: {{project_name}}"
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

# Datastores Index: {{project_name}}

Back to [[{{project_name}}|{{project_name}}]].

> Navigation scaffolding. Excluded from the Obsidian graph (`-file:_index`) to keep the graph focused on content nodes. Indexes carry `kb/type/index`, not `kb/type/datastore`, so they never pick up the red datastore color.

## Datastores

| Datastore | Kind | Version | Consumers |
|-----------|------|---------|-----------|
{{datastores_table}}

Kind is one of `postgres`, `mysql`, `redis`, `mongo`, `kafka`, `rabbitmq`, etc.

## Consumer Graph

Services (yellow) → datastores (red) edges, derived from `graph.json` `shares_datastore` / `publishes_to` / `subscribes_to` relations.

```mermaid
{{datastore_consumer_mermaid}}
```

## All Datastores

{{all_datastore_backlinks}}
