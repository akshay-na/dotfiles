---
title: "Module: {{module_name}}"
type: module
project: {{project_name}}
tags: [{{project_name}}, module, {{module_name}}]
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: [{{source_files}}]
confidence: {{confidence}}
stale: false
aliases: [{{aliases}}]
---

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
|------|---------|
{{key_files_rows}}

## Configuration

{{configuration}}

## Related

- [[../README|Project Overview]]
- [[../architecture|Architecture]]
- [[_index|All Modules]]
{{related_modules}}
