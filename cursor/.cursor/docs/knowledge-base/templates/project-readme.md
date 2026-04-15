---
title: { { project_name } }
type: overview
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/hub
  - kb/type/hub
generated_at: { { timestamp } }
generated_by: kb-engineer
confidence: { { confidence } }
stale: false
aliases: [{ { project_name } }, "Project: {{project_name}}"]
---

<!--
  FILE: Save as {{project_name}}.md (NOT README.md)
  TAGS: Hierarchical tags for Obsidian graph grouping and AI querying
-->

# {{project_name}}

## Overview

{{description}}

## Tech Stack

| Category | Technology | Version |
| -------- | ---------- | ------- |

{{tech_stack_rows}}

## Architecture

→ [[architecture|Architecture Details]]

```mermaid
flowchart TD
    hub["{{project_name}}"]

    hub --> modules[Modules]
    hub --> services[Services]
    hub --> arch[Architecture]
    hub --> deps[Dependencies]

    {{module_nodes}}
    {{service_nodes}}
    {{external_dep_edges}}
```

## Key Modules

{{module_links}}

→ [[modules/_index|All Modules]]

## Key Services

{{service_links}}

→ [[services/_index|All Services]]

## Dependencies

| Dependency | Type | Purpose |
| ---------- | ---- | ------- |

{{dependency_summary_rows}}

→ [[dependencies|Full Dependency Map]]

## Quick Stats

- **Modules**: {{module_count}}
- **Services**: {{service_count}}
- **External dependencies**: {{dep_count}}
- **Source files analyzed**: {{file_count}}

## Entry Points

{{entry_points}}

## Connected Projects

> Cross-project dependencies — these links create hub-to-hub connections in the Obsidian graph.

{{connected_projects_links}}

```mermaid
flowchart LR
    this["{{project_name}}"]

    {{connected_projects_nodes}}

    {{hub_to_hub_edges}}
```

## Related

### This Project

- [[architecture|Architecture]]
- [[dependencies|Dependencies]]
- [[modules/_index|Modules Index]]
- [[services/_index|Services Index]]

### All Modules

{{all_module_links}}

### All Services

{{all_service_links}}

### Connected Projects

{{connected_projects_related}}
