---
title: "Service: {{service_name}}"
type: service
project: {{project_name}}
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/service/{{service_name}}
  - kb/type/service
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: {{source_files}}
discovery_sources: {{discovery_sources}}
port: {{port}}
protocol: {{protocol}}
confidence: {{confidence}}
stale: false
aliases: {{aliases}}
---

# Service: {{service_name}}

Back to [[{{project_name}}|{{project_name}}]].

## Purpose

{{purpose}}

## Discovery

| Field | Value |
|-------|-------|
| Discovery sources | {{discovery_sources_display}} |
| Port | {{port_display}} |
| Protocol | {{protocol_display}} |

Source content is capped at ~400 tokens per service doc.

## API Endpoints

| Method | Path | Purpose |
|--------|------|---------|
{{endpoints_table}}

## Sequence

```mermaid
{{sequence_mermaid}}
```

## Upstream Dependencies

Services and datastores this one calls (max 5).

{{upstream_dependencies}}

## Downstream Dependents

Services that call this one (max 5).

{{downstream_dependents}}

## Configuration

{{configuration_notes}}

## Health Checks

{{health_checks}}

## Related

{{related_service_links}}
