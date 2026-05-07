# Cursor Setup Guide

This directory contains the shared Cursor runtime setup for this dotfiles repo.
When stowed, it maps to `~/.cursor/` and becomes the active local orchestration layer.

## What this package is

- Source of truth for Cursor agents, rules, skills, templates, hook scripts, and MCP server definitions.
- Versioned in dotfiles so behavior stays reproducible across machines.
- Designed for "edit in repo, then stow", not "edit symlink target directly".

## How it is applied

- Package path: `dotfiles/cursor/.cursor/`
- Target path after stow: `~/.cursor/`
- Apply with:
  - `make stow CONFIGS="cursor"`
  - or `make install` for full machine setup

If symlinks drift or break, run `make clean` then re-run `make stow CONFIGS="cursor"`.

## Directory breakdown

### `agents/`

Agent definitions and role contracts.

- Org-level orchestrators and specialists live here (for example: `tech-lead`, `code-reviewer`, `vp-onboarding`, `staff-engineer`).
- These files define scope, delegation boundaries, and expected outputs.
- Changes here directly affect routing and behavior of automated agent chains.

### `rules/`

Persistent behavior constraints loaded by Cursor.

- Includes orchestration boundaries, mode selection guidance, memory conventions, and security/quality expectations.
- Files under this directory are policy inputs; avoid casual edits.
- Prefer small, explicit rule updates with clear intent.

### `skills/`

Reusable process playbooks and execution helpers.

- Skills encode workflows (for example orchestration, verification loops, memory/KB operations, and communication patterns).
- Agents load skills as needed to execute structured tasks consistently.

### `templates/`

Template registry and scaffolding artifacts.

- Used by onboarding and orchestration flows to generate deterministic files.
- `templates/onboarding/_index.yml` is the current template registry index.

### `configurations/`

YAML policy/config data for orchestration behaviors.

- Includes routing maps and orchestration policy documents.
- Supports deterministic dispatch and anti-duplication controls.

### `hooks/` and `hooks.json`

Local lifecycle automations around tool calls, shell, and commits.

- `hooks.json` wires these scripts into Cursor hook points.
- Current hook groups:
  - `preToolUse`: write guards + task preflight/injection hooks
  - `beforeShellExecution`: shell safety wrapper
  - `preCommit`: protocol lint checks for subagent response schema drift

### `contracts/`

Contract/reference artifacts used by orchestrators and protocol checks.

### `mcp.json`

MCP server definitions used by this setup.

- Current configured servers include:
  - `sequential-thinking`
  - `fetch`
  - `time`
  - `context7`

### `ai-brain/`

Tracked skeleton for local AI brain bootstrap.

- Source skeleton includes templates/instructions (for example `_schema/`, `_templates/`, and `README.md`).
- Runtime/project-specific brain content is intentionally local and ignored after stow.

## New user workflow

1. Clone dotfiles.
2. Run `make install` (or `make stow CONFIGS="cursor"` if only Cursor config is needed).
3. Confirm `~/.cursor/` resolves to symlinks from this repo.
4. Open Cursor and verify hooks/MCP are loaded.
5. Make changes in this repo under `dotfiles/cursor/.cursor/`, not under `~/.cursor/` directly.
6. Re-run stow after edits when needed.

## Editing guidance

- Keep diffs minimal and behavior-focused.
- Do not mass-reformat files unless explicitly requested.
- Keep policy/template changes synchronized:
  - if protocol or orchestration contracts change, update corresponding rule/template/hook references together.
- Validate key flows after meaningful edits:
  - hook execution paths
  - routing/policy file consistency
  - onboarding template index references

## Quick verification checklist

- `hooks.json` points only to scripts that exist in `hooks/`.
- `templates/onboarding/_index.yml` paths resolve to real template files.
- `mcp.json` remains valid JSON and matches intended server set.
- No secrets are introduced in tracked files.
- Stow still links this package cleanly.

