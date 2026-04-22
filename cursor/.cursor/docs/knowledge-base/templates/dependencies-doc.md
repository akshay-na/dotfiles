---
title: "Dependencies: {{project_name}}"
type: dependency
project: {{project_name}}
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/deps
  - kb/type/deps
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: {{source_files}}
confidence: {{confidence}}
stale: false
---

# Dependencies: {{project_name}}

Back to [[{{project_name}}|{{project_name}}]].

## External Dependencies

| Name | Version | Type | Purpose |
|------|---------|------|---------|
{{external_deps_table}}

## Dependency Graph

```mermaid
{{dependency_graph_mermaid}}
```

## Inter-Service Dependencies

Service-to-service and service-to-datastore edges from `graph.json`. Kept under ~200 tokens.

| Source | Target | Relation | Confidence |
|--------|--------|----------|------------|
{{inter_service_edges_table}}

```mermaid
{{inter_service_topology_mermaid}}
```

## Security Considerations

{{security_notes}}

## Update Recommendations

{{update_recommendations}}

## Related

{{related_module_links}}
