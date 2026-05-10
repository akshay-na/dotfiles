# Cursor Setup Guide

This directory contains the shared Cursor runtime setup for this dotfiles repo.
When stowed, it maps to `~/.cursor/` and becomes the active local orchestration layer.

## What this package is

- Source of truth for Cursor agents, rules, skills, templates, hook scripts, and MCP server definitions.
- Versioned in dotfiles so behavior stays reproducible across machines.
- Designed for "edit in repo, then stow", not "edit symlink target directly".

## Content org pack (separate stow target)

Editorial/content automation uses a **separate** Cursor pack, also stowed to **`~/.cursor`**. Do **not** stow both this tech tree (`ai/cursor-tech-team`) and the content pack into **`~/.cursor`** at the same time — switch packs per workflow. See the **content org** pack’s README in `ai/cursor-content-team/`.

## How this tech package is applied

- Package path: `dotfiles/ai/cursor-tech-team/`
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
- `telemetry.yml` configures the hook-based telemetry pipeline (log dir,
  retention, caps, redaction, per-event toggles).
- `pack-identity.yml` carries the pack id (`cursor-tech-team`) used by the
  telemetry hooks to tag every JSONL event with `hooks_pack`.

### `hooks/` and `hooks.json`

Local lifecycle automations around tool calls, shell, MCP, subagents, and
sessions.

- `hooks.json` wires these scripts into Cursor hook points.
- Two complementary tracks share the hook chain:
  - **Safety controls (fail-closed where appropriate):**
    - `cursor-zone-writes.sh` — auto-approves writes inside trusted zones.
    - `safe-shell.sh` — auto-approves a narrow read-only command allowlist.
    - `subagent-task-antidup-preflight.sh` — rejects oversized inline blobs in
      `Task` dispatches (`failClosed: true`).
    - `subagent-protocol-inject.sh` — injects the subagent response contract
      and per-session marker.
  - **Telemetry pipeline (fail-open):** the `telemetry-*.sh` family records
    a structured JSONL audit + observability stream of every Cursor
    lifecycle event (`sessionStart`, `sessionEnd`, `pre/post ToolUse`,
    `postToolUseFailure`, `before/after ShellExecution`,
    `before/after MCPExecution`, `subagentStart`, `subagentStop`).
    Configuration: `configurations/telemetry.yml`.
    Operational runbook: `docs/runbooks/telemetry-pipeline.md`.
- The lint hook for subagent-protocol drift is
  `hooks/subagent-protocol-lint.sh` and runs as a pre-commit check rather
  than a Cursor hook event.

### `contracts/`

Contract/reference artifacts used by orchestrators and protocol checks.

### `mcp.json`

MCP server definitions used by this setup.

- Current configured servers include:
  - `sequential-thinking`
  - `fetch`
  - `time`
  - `context7`

### `ai-brain/` (sibling package, not part of this tree)

The tracked skeleton for the local AI brain lives in a **separate** stow
package at `dotfiles/ai/ai-brain/` and is not nested inside this Cursor pack.
After stow it surfaces as `~/ai-brain/`.

- Source skeleton includes templates/instructions (for example `_schema/`, `_templates/`, and `README.md`).
- Runtime/project-specific brain content is intentionally local and ignored after stow.
- Private vault policy (see `rules/brain-conventions.mdc`): **PII allowed** in private/local brain content when user-approved; **secrets forbidden** (passwords, API keys, tokens, private keys, cookies, MFA seeds, payment/bank secrets).
- Operator model path: `~/ai-brain/org/global/operator-profile/` (layout in `_templates/operator-profile.md`).

## New user workflow

1. Clone dotfiles.
2. Run `make install` (or `make stow CONFIGS="cursor"` if only Cursor config is needed).
3. Confirm `~/.cursor/` resolves to symlinks from this repo.
4. Open Cursor and verify hooks/MCP are loaded.
5. Make changes in this repo under `dotfiles/ai/cursor-tech-team/`, not under `~/.cursor/` directly.
6. Re-run stow after edits when needed.

## Token and cache discipline

- **Goal:** smaller `alwaysApply` hot path, stable early prefix, fewer redundant reads — see [`skills/context-cache-discipline/SKILL.md`](skills/context-cache-discipline/SKILL.md).
- **Policy:** long playbooks live in **skills**; rules keep **hard gates + pointers**. Edit pack in-repo, then stow — avoid drifting local `~/.cursor` copies.
- **Cross-pack:** content org pack may point here for canonical discipline text (`dotfiles/ai/cursor-tech-team/skills/context-cache-discipline/SKILL.md`).

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
- `~/.cursor/logs/telemetry/events.jsonl` (when stowed and active) contains
  no raw secrets and every line parses with `schema_version: 1`. Verify with
  the redaction grep in `docs/runbooks/telemetry-pipeline.md`.
- Stow still links this package cleanly.
