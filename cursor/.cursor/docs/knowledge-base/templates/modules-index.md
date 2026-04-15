---
title: "Modules: {{project_name}}"
type: module-index
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/module
  - kb/type/module
  - kb/type/index
generated_at: { { timestamp } }
generated_by: kb-engineer
confidence: { { confidence } }
stale: false
---

<!-- TAGS: Hierarchical for Obsidian graph grouping and AI querying -->

# {{project_name}} Modules

## Overview

This project contains **{{module_count}}** modules.

## Module Map

```mermaid
flowchart TD
    %% Node color classes
    classDef hub fill:#4A90D9,stroke:#2E5A8B,stroke-width:3px,color:#fff
    classDef module fill:#7CB342,stroke:#558B2F,stroke-width:2px,color:#fff

    hub["{{project_name}}"]:::hub

    {{module_nodes}}

    hub --> {{first_module}}
    {{module_edges}}
```

## All Modules

| Module | Path | Type | Key Exports | Dependencies |
| ------ | ---- | ---- | ----------- | ------------ |

{{module_table_rows}}

## Module Details

{{module_detail_links}}

## Dependency Matrix

| Module | Depends On | Depended By |
| ------ | ---------- | ----------- |

{{dependency_matrix_rows}}

## Related

### Project Hub

> **REQUIRED**: This link makes [[../{{project_name}}|{{project_name}}]] the center of the graph.

- [[../{{project_name}}|{{project_name}}]]

### This Project

- [[../architecture|Architecture]]
- [[../dependencies|Dependencies]]
- [[../services/_index|Services]]

### All Modules

{{all_module_links}}
