---
title: "Module: {{module_name}}"
type: module
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/module/{{module_name}}
  - kb/type/module
generated_at: { { timestamp } }
generated_by: kb-engineer
source_files: [{ { source_files } }]
confidence: { { confidence } }
stale: false
aliases: [{ { aliases } }]
---

<!-- TAGS: Hierarchical for Obsidian graph grouping and AI querying -->

# {{module_name}}

## Purpose

{{purpose}}

## Location

- **Path**: `{{module_path}}`
- **Entry point**: `{{entry_point}}`

## Public API

{{public_api}}

## Internal Structure

```mermaid
flowchart TD
    subgraph {{module_name}}
        {{internal_nodes}}
    end
    {{external_connections}}
```

## Dependencies

### Internal (other modules)

{{internal_dependencies}}

### External (packages)

{{external_dependencies}}

## Dependents

Modules/services that depend on this module:

{{dependents}}

## Call Flow

```mermaid
flowchart LR
    {{call_flow_nodes}}
```

## Key Files

| File | Purpose |
| ---- | ------- |

{{key_files_rows}}

## Configuration

{{configuration}}

## Cross-Project Dependencies

> Module-to-module links to other projects (if this module uses external project modules).

{{cross_project_module_links}}

```mermaid
flowchart LR
    this["{{module_name}}"]

    {{cross_project_module_nodes}}

    {{cross_project_module_edges}}
```

## Related

### Project Hub

> **REQUIRED**: This link makes [[../{{project_name}}|{{project_name}}]] the center of the graph.

- [[../{{project_name}}|{{project_name}}]]

### This Project

- [[../architecture|Architecture]]
- [[../dependencies|Dependencies]]
- [[_index|All Modules]]

### Related Modules (Same Project)

{{related_modules}}

### Related Modules (Other Projects)

{{cross_project_related}}
