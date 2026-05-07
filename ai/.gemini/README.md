# Gemini Setup Guide

This directory is the shared Gemini capability layer in DotMate.
When stowed, it maps to `~/.gemini/` and provides the content pipeline orchestration setup.

## What this package is

- Versioned source of Gemini agent configs, rules, skills, templates, and minimal scripts.
- Built for content operations driven by `cco` and `metrics-steward`.
- Durable KB and memory follow **`~/ai-brain/`** (same model as Cursor **`kb-identity`**): **`~/ai-brain/projects/<project_name>/`** for pipeline files, with **`project_name`** from git remote or folder.
- Intended workflow is "edit in dotfiles, then stow", not editing symlink targets directly.

## How it is applied

- Source path: `dotfiles/ai/.gemini/`
- Target path: `~/.gemini/`
- Apply with:
  - `make stow CONFIGS="gemini"` or `make stow CONFIGS="ai"` when using the combined `ai` stow package
  - or `make install`

No bootstrap script: ensure **`~/ai-brain/`** exists (stow `dotfiles/ai/ai-brain` or equivalent). Opening Gemini from a **git repo** (or setting **`GEMINI_PROJECT_ROOT`**) defines **`<project_name>`** and thus **`~/ai-brain/projects/<project_name>/`** for editorial content.

## Core references

- `CONVENTIONS.md` — canonical paths and contracts.
- `GEMINI.md` — runtime behavior for external/internal agents and phase flow.
- `rules/project-identity.md` — **`project_name`** / **`<content-brain>`** resolution (**`kb-identity`** parity).
- `skills/project-identity/SKILL.md` — full derivation algorithm.
- `rules/content-brain-paths.md` — editorial folder layout under **`~/ai-brain/projects/<project_name>/`**.
- `rules/orchestration.md` — phase DAG and execution order.
- `rules/brain-conventions.md` — unified `~/ai-brain/` memory+KB (aligned with Cursor).
- `rules/docs-and-knowledge.md` — three-tier docs/knowledge model.
- `rules/memory.md` — Gemini-local `~/.gemini/memory/` vs `~/ai-brain/`.

## Directory breakdown

### `agents/`

- External entrypoints: `agents/cco.md`, `agents/metrics-steward.md`
- Internal personas: `agents/internal/` (invoked inside `cco` only).

### `rules/`

- Policy for orchestration, repo hygiene, observability, dedup, platform behavior, brand, metrics.

### `skills/`

- `cco-orchestration`, `project-identity`, `caveman`, `subagent-observability`, etc.

### `scripts/`

- `scripts/auth/keychain-helper.sh` — optional macOS keychain helper.

### `templates/`

- Briefs, drafts, brand voice, ledger, metrics examples.

## New user quick start

1. Stow: `make stow CONFIGS="ai"` (or `gemini` if split).
2. Ensure `~/ai-brain/` exists; run from your **project git root** (or set **`GEMINI_PROJECT_ROOT`**) so **`<project_name>`** resolves and **`~/ai-brain/projects/<project_name>/`** is used for pipeline artefacts.
3. Enable Gemini CLI subagents (`experimental.enableAgents` in `~/.gemini/settings.json`).
4. Use `cco` for pipeline runs and `metrics-steward` for analytics ingestion.

## Editing and maintenance guidance

- Keep changes minimal and targeted.
- Keep agents, orchestration rules, and templates aligned with `rules/content-brain-paths.md`.
