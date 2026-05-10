# Strict tool and responsibility boundaries (content org)

Applies while **this** pack is the active global config at **`~/.gemini`**. Companion to **`agent-orchestration.md`**, **`vp-research.md`**, **`mcp-usage.md`**.

## Identity of `<project>`

- **`<project>`** = **content corpus git root** for the current brief (see **`docs-and-decisions.md`**). It is **not** **`~/.cursor`** for plans or vault data.
- **Editing `~/.gemini/*`** (org pack files) only when the user explicitly runs a **pack maintenance** task — not as a side effect of client corpus work.

## File tools (read / write / delete)

- **Reads:** Paths required by the plan, skill, or user; prefer project index files when the corpus defines them.
- **Writes** (`apply_patch`, `write`, delete):
  - **`cco` / `content-lead` / org specialists:** only `<project>` paths in **`touches[]`** / phase text, plus **`<project>/.gemini/docs/`** as the role allows. No new `<project>` top-level directories without plan/ADR.
  - **Project agents (`sme-*`, `reviewer-*`):** only what **that** repository’s rules allow (e.g. **content-foundry** → **`path-conventions.md`**).

## Subagent dispatch (Gemini CLI — not Cursor `Task`)

- Use the **Gemini CLI agent-delegation tool** registered for the target agent (see **`mode-auto-selection.md`**). **Do not** reference Cursor IDE’s **`Task`** tool in this client.
- Dispatch **only** agents allowed by **`agent-orchestration.md`**, the active **CCO plan**, **`content-team-discovery`**, or **`routing-table.yml`**.
- **No** improvised agent names. **No** peer dispatch chains **org `vp-*` ↔ `vp-*`** without **`cco`** orchestration.
- **Zero-gap:** no parent file writes on child-owned **`touches[]`** until the child dispatch completes (or protocol degraded stub) — same chain rules as **`agent-orchestration.md`**.
- Child agents return structured output per **`subagent-response-protocol.md`** where required.

## Shell (`run_terminal_cmd`)

- **Git:** follow **`content-git-workflow`**; **no** `push --force`, `reset --hard`, branch `--delete`, or history rewrite unless the user explicitly instructs verbatim.
- **Network:** **no** `curl` / `wget` / `ssh` to editorial, CMS, or analytics endpoints unless a **skill or runbook** names that integration — platform facts go through **`vp-research`**.
- **Tooling:** **no** `npm install`, `pip install`, or project bootstrap on `<project>` unless the plan includes a setup phase.

## MCP

- **Fetch / WebSearch / Context7 / equivalent:** **`vp-research`** only — **`mcp-usage.md`**.
- **Atlassian:** not part of this pack — no writes; no assumed **`atlassian-pm`**.
- **Secrets:** never pass tokens/credentials into MCP payloads.

## Browser (IDE) — `chief-profile-metrics` only

When the user (or **`cco`** / **`content-lead`** per plan) invokes **`chief-profile-metrics`**:

- **May** use **Cursor in-session browser** / snapshot tools to read **numeric profile or dashboard fields** the **logged-in user** can already access — same session as the human; **no** headless credential entry, **no** stuffing secrets into files.
- **Does not** replace the **no-`curl`-to-platforms** rule for raw HTTP scrapers; this carve-out is **interactive IDE browser** only.
- Other agents **must not** use browser tools to bypass **`vp-research`** for general web research — only **`chief-profile-metrics`** for **profile metric capture** as above.

## Image / composer tooling

- **Corpus-facing raster** (heroes, thumbs, committed **assets/**): **`chief-visual-officer`** only, after **`chief-visual-handoff`**.
- Other agents supply **briefs / prompts / paths**, not final branded pixels meant for CVO.

## Programmatic video (Remotion + Skia + ffmpeg)

- **Editorial:** **`video-editor`**; **`video-editor-handoff`** preconditions.
- **Execution:** **`remotion-builder`** in **Cursor** (DotMate **`ai/cursor-tech-team`**) for v1 — Gemini prepares the handoff; **`sme-*`** do not invoke **`remotion-builder`** directly.

## Brain (`~/ai-brain/`, `~/.cursor` memory lanes)

- **`brain-conventions.md`**; bounded fields; **no** PII or secret dumps.

## On violation

**Stop** — state which clause failed, suggest **`cco`**, **`content-lead`**, **`vp-research`**, or user. **Do not** patch past the breach without correction.
