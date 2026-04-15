---
title: "Service: {{service_name}}"
type: service
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/service/{{service_name}}
  - kb/type/service
generated_at: { { timestamp } }
generated_by: kb-engineer
source_files: [{ { source_files } }]
confidence: { { confidence } }
stale: false
aliases: [{ { aliases } }]
---

<!-- TAGS: Hierarchical for Obsidian graph grouping and AI querying -->

# {{service_name}}

## Purpose

{{purpose}}

## Configuration

- **Port**: {{port}}
- **Protocol**: {{protocol}}
- **Entry point**: `{{entry_point}}`

## API Endpoints

{{api_endpoints}}

## Service Interactions

```mermaid
sequenceDiagram
    {{sequence_diagram_content}}
```

## Dependencies

### Services

{{service_dependencies}}

### Modules

{{module_dependencies}}

### External

{{external_dependencies}}

## Architecture

```mermaid
flowchart LR
    {{architecture_nodes}}
```

## Deployment

{{deployment_info}}

## Health & Observability

- **Health endpoint**: {{health_endpoint}}
- **Metrics**: {{metrics}}
- **Logs**: {{logging}}

## Configuration Files

| File | Purpose |
| ---- | ------- |

{{config_files_rows}}

## Cross-Project Services

> Service-to-service links to other projects (connected/dependent services).

{{cross_project_service_links}}

```mermaid
flowchart LR
    this["{{service_name}}"]

    {{cross_project_service_nodes}}

    {{cross_project_service_edges}}
```

## Related

### Project Hub

> **REQUIRED**: This link makes [[../{{project_name}}|{{project_name}}]] the center of the graph.

- [[../{{project_name}}|{{project_name}}]]

### This Project

- [[../architecture|Architecture]]
- [[../dependencies|Dependencies]]
- [[_index|All Services]]

### Related Services (Same Project)

{{related_services}}

### Related Services (Other Projects)

{{cross_project_related}}
