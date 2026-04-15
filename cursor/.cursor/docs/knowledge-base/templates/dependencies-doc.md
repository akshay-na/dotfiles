---
title: "Dependencies: {{project_name}}"
type: dependency
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/deps
  - kb/type/deps
generated_at: { { timestamp } }
generated_by: kb-engineer
confidence: { { confidence } }
stale: false
---

<!-- TAGS: Hierarchical for Obsidian graph grouping and AI querying -->

# {{project_name}} Dependencies

## Overview

{{overview}}

## Dependency Graph

```mermaid
flowchart LR
    %% Node color classes
    classDef hub fill:#4A90D9,stroke:#2E5A8B,stroke-width:3px,color:#fff
    classDef module fill:#7CB342,stroke:#558B2F,stroke-width:2px,color:#fff
    classDef external fill:#9C27B0,stroke:#6A1B9A,stroke-width:2px,color:#fff

    subgraph project["🔵 {{project_name}}"]
        hub["{{project_name}}"]:::hub
        {{internal_module_nodes}}
    end

    subgraph deps["🟣 External Dependencies"]
        {{external_dep_nodes}}
    end

    {{dependency_edges}}
```

## Production Dependencies

| Package | Version | Purpose | Used By |
| ------- | ------- | ------- | ------- |

{{prod_deps_rows}}

## Development Dependencies

| Package | Version | Purpose |
| ------- | ------- | ------- |

{{dev_deps_rows}}

## Peer Dependencies

| Package | Version | Required By |
| ------- | ------- | ----------- |

{{peer_deps_rows}}

## Dependency Analysis

### By Category

| Category | Count | Examples |
| -------- | ----- | -------- |

{{deps_by_category_rows}}

### Security Notes

{{security_notes}}

### Update Recommendations

{{update_recommendations}}

## Related

### Project Hub

> **REQUIRED**: This link makes [[{{project_name}}|{{project_name}}]] the center of the graph.

- [[{{project_name}}|{{project_name}}]]

### This Project

- [[architecture|Architecture]]
- [[modules/_index|Modules]]
- [[services/_index|Services]]
