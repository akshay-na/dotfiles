---
title: "Architecture: {{project_name}}"
type: architecture
project: {{project_name}}
tags: [{{project_name}}, architecture]
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: [{{source_files}}]
confidence: {{confidence}}
stale: false
---

# {{project_name}} Architecture

## Overview

{{overview}}

## System Diagram

```mermaid
flowchart TD
    subgraph External
        {{external_nodes}}
    end
    
    subgraph {{project_name}}
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
|--------|---------------|--------------|
{{module_boundaries_rows}}

## Service Boundaries

| Service | Responsibility | Protocol |
|---------|---------------|----------|
{{service_boundaries_rows}}

## Integration Points

{{integration_points}}

## Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
{{tech_decisions_rows}}

## Security Boundaries

{{security_boundaries}}

## Scalability Considerations

{{scalability}}

## Related

- [[README|Project Overview]]
- [[dependencies|Dependencies]]
- [[modules/_index|Modules]]
- [[services/_index|Services]]
