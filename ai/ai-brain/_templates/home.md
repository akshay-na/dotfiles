---
title: AI Brain Home
type: home
tags:
  - kb
  - kb/type/home
generated_at: {{timestamp}}
generated_by: entrypoint-touch-write
stale: false
---

# AI Brain Home

Central navigation hub for all project documentation in this Obsidian vault.

## Projects

| Project | Type | Modules | Services | Datastores | Last Updated |
|---------|------|---------|----------|------------|--------------|
{{projects_table}}

## Global Architecture

```mermaid
{{global_architecture_mermaid}}
```

## Statistics

| Metric | Value |
|--------|-------|
| Total projects | {{total_projects}} |
| Total modules | {{total_modules}} |
| Total services | {{total_services}} |
| Total datastores | {{total_datastores}} |
| Total dependencies | {{total_dependencies}} |

## Recently Updated

{{recently_updated_list}}

## Usage

### For Humans

Open any project hub to start exploring. Graph view renders the full vault with palette settings.

### For AI Agents

Use `brain-memory-kb` in `mode: kb-query` with tiered budgets:

- Level 0-1 — project overview, topology
- Level 2 — specific node docs
- Level 3 — full graph traversal
