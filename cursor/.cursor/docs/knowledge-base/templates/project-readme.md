---
title: "Project: {{project_name}}"
type: overview
project: {{project_name}}
tags: [{{project_name}}, overview]
generated_at: {{timestamp}}
generated_by: kb-engineer
confidence: {{confidence}}
stale: false
---

# {{project_name}}

## Overview

{{description}}

## Tech Stack

| Category | Technology | Version |
|----------|------------|---------|
{{tech_stack_rows}}

## Architecture

→ [[architecture|Architecture Details]]

```mermaid
flowchart TD
    subgraph Overview
        {{architecture_overview_nodes}}
    end
```

## Key Modules

{{module_links}}

→ [[modules/_index|All Modules]]

## Key Services

{{service_links}}

→ [[services/_index|All Services]]

## Dependencies

| Dependency | Type | Purpose |
|------------|------|---------|
{{dependency_summary_rows}}

→ [[dependencies|Full Dependency Map]]

## Quick Stats

- **Modules**: {{module_count}}
- **Services**: {{service_count}}
- **External dependencies**: {{dep_count}}
- **Source files analyzed**: {{file_count}}

## Entry Points

{{entry_points}}

## Related

- [[architecture|Architecture]]
- [[dependencies|Dependencies]]
- [[modules/_index|Modules Index]]
- [[services/_index|Services Index]]
