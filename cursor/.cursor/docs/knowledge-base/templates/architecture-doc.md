---
title: "Architecture: {{project_name}}"
type: architecture
project: { { project_name } }
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/arch
  - kb/type/arch
generated_at: { { timestamp } }
generated_by: kb-engineer
source_files: [{ { source_files } }]
confidence: { { confidence } }
stale: false
---

<!-- TAGS: Hierarchical for Obsidian graph grouping and AI querying -->

# {{project_name}} Architecture

## Overview

{{overview}}

## System Diagram

```mermaid
flowchart TD
    subgraph external["External"]
        {{external_nodes}}
    end

    subgraph project["{{project_name}}"]
        {{internal_nodes}}
    end

    {{connections}}
```

## Component Breakdown

### Layers

```mermaid
flowchart LR
    subgraph Presentation
        {{presentation_nodes}}
    end

    subgraph Business
        {{business_nodes}}
    end

    subgraph Data
        {{data_nodes}}
    end

    Presentation --> Business
    Business --> Data
```

### Key Components

{{key_components}}

## Data Flow

```mermaid
flowchart LR
    {{data_flow_nodes}}
```

## Module Boundaries

| Module | Responsibility | Dependencies |
| ------ | -------------- | ------------ |

{{module_boundaries_rows}}

## Service Boundaries

| Service | Responsibility | Protocol |
| ------- | -------------- | -------- |

{{service_boundaries_rows}}

## Integration Points

{{integration_points}}

## Technology Decisions

| Decision | Choice | Rationale |
| -------- | ------ | --------- |

{{tech_decisions_rows}}

## Security Boundaries

{{security_boundaries}}

## Scalability Considerations

{{scalability}}

## Cross-Project Architecture

> System boundaries and how this project connects to other projects.

{{cross_project_architecture}}

```mermaid
flowchart TD
    this["{{project_name}}"]
    {{internal_architecture_nodes}}

    {{cross_project_nodes}}

    {{cross_project_edges}}
```

## Related

### Project Hub

> **REQUIRED**: This link makes [[{{project_name}}|{{project_name}}]] the center of the graph.

- [[{{project_name}}|{{project_name}}]]

### This Project

- [[dependencies|Dependencies]]
- [[modules/_index|Modules]]
- [[services/_index|Services]]

### Connected Projects

{{connected_projects_links}}
