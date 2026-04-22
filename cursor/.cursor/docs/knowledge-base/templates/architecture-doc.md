---
title: "Architecture: {{project_name}}"
type: architecture
project: {{project_name}}
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/arch
  - kb/type/arch
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: {{source_files}}
confidence: {{confidence}}
stale: false
---

# Architecture: {{project_name}}

Back to [[{{project_name}}|{{project_name}}]].

## System Overview

```mermaid
{{system_overview_mermaid}}
```

## Layers

```mermaid
{{layers_mermaid}}
```

## Data Flow

```mermaid
{{data_flow_mermaid}}
```

## Module Boundaries

| Module | Responsibility | Depends On |
|--------|----------------|------------|
{{module_boundaries_table}}

## Service Boundaries

| Service | Protocol | Port | Upstream | Downstream |
|---------|----------|------|----------|------------|
{{service_boundaries_table}}

## Integration Points

{{integration_points}}

## Related

{{related_links}}
