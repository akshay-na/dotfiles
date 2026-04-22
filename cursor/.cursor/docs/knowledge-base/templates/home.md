---
title: Knowledge Base Home
type: home
tags:
  - kb
  - kb/type/home
generated_at: {{timestamp}}
generated_by: kb-engineer
stale: false
---

# Knowledge Base Home

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

Open any project hub to start exploring. Graph view (Ctrl/Cmd + G) renders the full vault with the 7-color palette.

### For AI Agents

Use the `kb-query` skill with token-efficient tiers:

- Level 0-1 — project overview, service topology (~200 tokens)
- Level 2 — specific module/service/datastore docs (~500 tokens)
- Level 3 — full graph.json traversal (~1000+ tokens)

## Color Palette

| Document Type | Color | Tag |
|---------------|-------|-----|
| Project hubs  | Blue   | `kb/type/hub`       |
| Services      | Yellow | `kb/type/service`   |
| Modules       | Green  | `kb/type/module`    |
| Datastores    | Red    | `kb/type/datastore` |
| Architecture  | Orange | `kb/type/arch`      |
| Dependencies  | Purple | `kb/type/deps`      |
| Vault Home    | Cyan   | `kb/type/home`      |
