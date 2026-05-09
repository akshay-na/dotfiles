# Gemini content org pack (DotMate)

Versioned **Gemini CLI** editorial org configuration. Stow source: **`dotfiles/ai/gemini-content-team/`** → target **`~/.gemini/`** (use `./scripts/DotMate.sh stow_with_target ai/gemini-content-team .gemini` or `make stow-with-target TOOL_PATH="ai/gemini-content-team" TARGET_NAME=".gemini"` from the dotfiles repo root).

**Canonical Cursor pack (port source):** `dotfiles/ai/cursor-content-team/`. **Dual-pack rule:** behavior changes in Cursor content pack need matching Gemini updates or a documented exception — see **maintenance plan** below.

**Parity plan:** [`../../.cursor/docs/plans/2026-05-10-gemini-content-team-parity.md`](../../.cursor/docs/plans/2026-05-10-gemini-content-team-parity.md).

## What this package is

- Agents, rules, skills, templates, hooks (Gemini JSON I/O), configurations, contracts — aligned with the Cursor content pack where the CLI supports the same contracts.
- Durable memory/KB: **`~/ai-brain/`** (same writer policy as Cursor `brain-conventions` port under `rules/brain-conventions.md`).
- **Separate agent-written docs:** org/project plans and reviews go to **`~/.gemini/docs/**`** (and repo **`…/.gemini/docs/`**), never **`~/.cursor/docs/**`** — per-client audit.

## Apply

1. Ensure **`~/ai-brain/`** exists (stow `dotfiles/ai/ai-brain` or equivalent).
2. Stow this tree to **`~/.gemini/`** via DotMate (`stow_with_target` unstows sibling `gemini-*` packages first per `DotMate.sh`).
3. Enable Gemini CLI agents: `experimental.enableAgents` in **`~/.gemini/settings.json`**.
4. Merge **`hooks`** snippets from `docs/runbooks/gemini-settings-merge.md` — **never** overwrite a user’s full settings file wholesale.

## Layout

| Area | Role |
|------|------|
| `agents/` | External: **`cco`**, **`content-lead`**, **`metrics-steward`**; internal personas under `agents/internal/` |
| `rules/` | Policy mirrors of Cursor `.mdc` where ported (`*.md`) |
| `skills/` | Editorial pipeline, **`brain-memory-kb`**, **`editorial-cro-loop`**, orchestration helpers |
| `hooks/` | Gemini stdin/stdout JSON adapters |
| `docs/` | Runbooks and plans — stows under **`~/.gemini/docs/`** |
| `contracts/` / `templates/` | Automation schemas + examples |
| `configurations/` | Routing, pipelines, orchestration policies |

## Core references

- **`GEMINI.md`** — load order, headless flags, external entrypoints.
- **`CONVENTIONS.md`** — path symbols and contracts.
- **`docs/runbooks/gemini-hooks-parity.md`** — Cursor → Gemini hook mapping.
- **`docs/runbooks/gemini-cli-capabilities-map.md`** — CLI doc crosswalk.

## Editing

Edit **sources in this repo**, not symlink/copy targets under **`~/.gemini/`** directly. Keep changes minimal; follow dual-pack maintenance in the parity plan.
