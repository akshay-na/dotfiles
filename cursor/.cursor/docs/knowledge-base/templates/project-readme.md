---
title: "{{project_name}}"
type: overview
project: {{project_name}}
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/hub
  - kb/type/hub
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: {{source_files}}
confidence: {{confidence}}
stale: false
---

# {{project_name}}

{{project_description}}

## Tech Stack

| Layer | Tech |
|-------|------|
{{tech_stack_table}}

## Architecture Preview

```mermaid
{{architecture_mermaid}}
```

## Modules

{{module_links}}

## Services

{{service_links}}

## Datastores

{{datastore_links}}

## Quick Stats

| Metric | Value |
|--------|-------|
| Modules | {{module_count}} |
| Services | {{service_count}} |
| Datastores | {{datastore_count}} |
| Dependencies | {{dependency_count}} |
| Edges | {{edge_count}} |

## Related

- [[architecture|Architecture]]
- [[dependencies|Dependencies]]
- [[modules/_index|Modules Index]]
- [[services/_index|Services Index]]
- [[datastores/_index|Datastores Index]]
{{cross_project_links}}
