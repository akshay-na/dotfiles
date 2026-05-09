# Gemini agent registry (CLI)

Gemini CLI treats YAML frontmatter on `agents/*.md` as **registry metadata**.

## Rules

1. **Frontmatter keys:** **`name`** and **`description` only** on every `agents/**/*.md`.
2. **Model routing / tools / thinking:** configure via **`~/.gemini/settings.json`** (`modelConfigs`, MCP allowlists), **`GEMINI.md`**, and agent **body** text — not frontmatter.
3. **Org singletons** (e.g. **`chief-visual-officer`**) stay under **`~/.gemini/agents/`** after stow/copy — do not duplicate under `<project>/.gemini/agents/`.
4. **`remotion-builder`** — **Cursor tech-pack** entrypoint only (`DotMate` **`ai/cursor-tech-team/agents/remotion-builder.md`** → **`~/.cursor/agents/remotion-builder.md`**). **Gemini** uses **`video-editor`** + **`video-editor-handoff`**; user runs **`remotion-builder`** in Cursor for renders (v1).

## Verification

`make verify-gemini-frontmatter` (or the umbrella `make verify-gemini-pack`) runs `./ai/gemini-content-team/hooks/check-gemini-agent-frontmatter.sh`.
