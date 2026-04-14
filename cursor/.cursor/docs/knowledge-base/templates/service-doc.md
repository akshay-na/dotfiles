---
title: "Service: {{service_name}}"
type: service
project: {{project_name}}
tags: [{{project_name}}, service, {{service_name}}]
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: [{{source_files}}]
confidence: {{confidence}}
stale: false
aliases: [{{aliases}}]
---

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
|------|---------|
{{config_files_rows}}

## Related

- [[../README|Project Overview]]
- [[../architecture|Architecture]]
- [[_index|All Services]]
{{related_services}}
