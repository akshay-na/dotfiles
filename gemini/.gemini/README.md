# Gemini Setup Guide

This directory is the shared Gemini capability layer in DotMate.
When stowed, it maps to `~/.gemini/` and provides the content pipeline orchestration setup.

## What this package is

- Versioned source of Gemini agent configs, rules, skills, scripts, and templates.
- Built for content operations driven by `cco` and `metrics-steward`.
- Intended workflow is "edit in dotfiles, then stow", not editing symlink targets directly.

## How it is applied

- Source path: `dotfiles/gemini/.gemini/`
- Target path: `~/.gemini/`
- Apply with:
  - `make stow CONFIGS="gemini"`
  - or `make install`

After stow, run:

- `bash ~/.gemini/scripts/kb-bootstrap.sh`

This bootstraps and links the content repository (`~/content-knowledge-base/` by default).

## Core references

- `CONVENTIONS.md` — canonical paths, script names, and operating contracts.
- `GEMINI.md` — runtime behavior for external/internal agents and phase flow.
- `rules/orchestration.md` — phase DAG and execution order.

Read these first before changing rules, agents, or scripts.

## Directory breakdown

### `agents/`

- External entrypoints:
  - `agents/cco.md`
  - `agents/metrics-steward.md`
- Internal personas live in `agents/internal/` and are invoked inside `cco` phases.

### `rules/`

- Operational policy files for orchestration, repo hygiene, observability, dedup, platform behavior, and constraints.
- Important examples: `repo-hygiene.md`, `orchestration.md`, `metrics-contract.md`, `subagent-response-protocol.md`.

### `skills/`

- Reusable execution guidance used by the orchestration flow.
- Includes `cco-orchestration`, `caveman`, and `subagent-observability`.
- `pipeline-state` is not stored here by default; it is symlinked from the content repo path after bootstrap.

### `scripts/`

Operational scripts that are called directly (no Makefile wrapper required):

- `kb-bootstrap.sh` — clone/init content repo, install hooks, wire symlinks.
- `kb-sync.sh` — sync wrapper (`pull`, `commit`, `push`, `sync`, `status`).
- `kb-status.sh` — repo health/staleness checks.
- `kb-lock.sh` — lock helper for multi-file write windows.
- `kb-log.sh` — structured logging for sync operations.
- `scripts/auth/*` — keychain/deploy-key helpers.

### `templates/`

Template artifacts for drafting, briefing, brand voice, ledger entries, and metrics payload examples.

## Content repo integration

Default companion repo: `~/content-knowledge-base/`

Key symlinks after bootstrap:

- `~/.gemini/kb` -> `~/content-knowledge-base/kb/`
- `~/.gemini/memory` -> `~/content-knowledge-base/memory/`
- `~/.gemini/docs` -> `~/content-knowledge-base/docs/`
- `~/.gemini/runbooks` -> `~/content-knowledge-base/runbooks/`
- `~/.gemini/skills/pipeline-state` -> `~/content-knowledge-base/docs/skills/pipeline-state/`

If your repo location differs, set `CONTENT_KB_REPO` before running bootstrap scripts.

## New user quick start

1. Stow this package: `make stow CONFIGS="gemini"`.
2. Run bootstrap: `bash ~/.gemini/scripts/kb-bootstrap.sh`.
3. Verify setup: `bash ~/.gemini/scripts/kb-status.sh`.
4. Ensure Gemini CLI subagents are enabled (`experimental.enableAgents` in `~/.gemini/settings.json`).
5. Use `cco` for pipeline runs and `metrics-steward` for analytics ingestion.

## Editing and maintenance guidance

- Keep changes minimal and targeted; avoid broad rewrites.
- Do not mass-format files unless explicitly requested.
- Keep contracts in sync when changing behavior:
  - agent definitions
  - orchestration/rules
  - templates and scripts that enforce those rules
- Validate path assumptions against `CONVENTIONS.md` before merging updates.
