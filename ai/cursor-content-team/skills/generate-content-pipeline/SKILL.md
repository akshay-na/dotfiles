---
name: generate-content-pipeline
description: Declarative stages for content automation — optional git_sync, plan, generate_content, git_commit_push; n8n correction branch with target_paths[].
version: 1
---

# generate-content-pipeline

## Default linear stages

| Stage | Owner | Notes |
|-------|--------|------|
| `git_sync` | `content-lead` / shell | `fetch` + `pull`; must run before **`cco`** if session starts here |
| `plan` | `cco` | Writes plan v0; optional **`editorial-cro-loop`** |
| `generate_content` | `content-lead` + project agents | Touches drafts per `touches[]` |
| `git_commit_push` | `content-lead` | [`content-git-workflow`](../content-git-workflow/SKILL.md) |

## Correction run

Payload: `correction_brief`, `target_paths[]`, same `task_id` lineage. Re-run **`git_sync`** → surgical edits → **`git_commit_push`**.

## Pipeline files

YAML under `configurations/pipelines/*.yml` names stages and allowed globs. **`skill-validation`** may reference this skill from manifests.
