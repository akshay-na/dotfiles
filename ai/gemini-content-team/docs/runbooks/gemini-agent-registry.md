# Gemini agent registry (CLI)

Gemini CLI treats YAML frontmatter on `agents/*.md` as **registry metadata**.

## Rules

1. **Frontmatter keys:** **`name`** and **`description` only** on every `agents/**/*.md`.
2. **Model routing / tools / thinking:** configure via **`~/.gemini/settings.json`** (`modelConfigs`, MCP allowlists), **`GEMINI.md`**, and agent **body** text — not frontmatter.
3. **Org singletons** (e.g. **`chief-visual-officer`**) stay under **`~/.gemini/agents/`** after stow/copy — do not duplicate under `<project>/.gemini/agents/`.

## Verification

`make verify-gemini-frontmatter` (or the umbrella `make verify-gemini-pack`) runs `./ai/gemini-content-team/hooks/check-gemini-agent-frontmatter.sh`.
