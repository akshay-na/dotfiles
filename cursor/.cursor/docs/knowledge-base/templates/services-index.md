---
title: "Services: {{project_name}}"
type: service-index
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/service
  - kb/type/service
  - kb/type/index
generated_at: { { timestamp } }
generated_by: kb-engineer
confidence: { { confidence } }
stale: false
---

<!-- TAGS: Hierarchical for Obsidian graph grouping and AI querying -->

# {{project_name}} Services

## Overview

This project contains **{{service_count}}** services.

## Service Topology

```mermaid
flowchart TD
    %% Node color classes
    classDef hub fill:#4A90D9,stroke:#2E5A8B,stroke-width:3px,color:#fff
    classDef service fill:#FDD835,stroke:#F9A825,stroke-width:2px,color:#000
    classDef external fill:#9C27B0,stroke:#6A1B9A,stroke-width:2px,color:#fff

    hub["{{project_name}}"]:::hub

    {{service_nodes}}

    {{external_service_nodes}}

    hub --> {{first_service}}
    {{service_edges}}
```

## All Services

| Service | Port | Protocol | Health Check | Dependencies |
| ------- | ---- | -------- | ------------ | ------------ |

{{service_table_rows}}

## Service Details

{{service_detail_links}}

## Communication Matrix

| From | To  | Protocol | Purpose |
| ---- | --- | -------- | ------- |

{{communication_matrix_rows}}

## Related

### Project Hub

> **REQUIRED**: This link makes [[../{{project_name}}|{{project_name}}]] the center of the graph.

- [[../{{project_name}}|{{project_name}}]]

### This Project

- [[../architecture|Architecture]]
- [[../dependencies|Dependencies]]
- [[../modules/_index|Modules]]

### All Services

{{all_service_links}}
