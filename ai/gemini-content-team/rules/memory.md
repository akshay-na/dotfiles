# Memory — Gemini + unified ai-brain

Canonical **org memory and KB** follow **`rules/brain-conventions.md`** and **`rules/docs-and-knowledge.md`** (same strategy as Cursor `~/.cursor/rules/`).

## Canonical root (cross-tool)

- **`~/ai-brain/`** — `org/`, `projects/<name>/`, `session/`, `.meta/`, promoted decisions and structure.
- **Editorial pipeline durable tree:** **`~/ai-brain/projects/<project_name>/`** — **`project_name`** from git or folder (**`rules/project-identity.md`**, **`skills/project-identity/SKILL.md`**); or absolute **`GEMINI_CONTENT_BRAIN`** bypass. See **`rules/brain-paths.md`**.

## Gemini-local run scratch

- **`~/.gemini/memory/`** — pipeline runs, observability NDJSON, run summaries, and other **ephemeral** Gemini CLI state only.
- **Do not** treat `~/.gemini/memory/` as durable org memory. Promote conclusions to **`~/ai-brain/`** when they are cross-session, reused, or policy-stable.

## Schema (Gemini-local)

If present under `~/.gemini/memory/_schema/`, it applies to **Gemini-local** entries only (not to `~/ai-brain/` layout).

## Writers

- **`cco`:** Gemini-local paths allowed by **`rules/orchestration.md`**. Writes to **`~/ai-brain/`** only when matching **`rules/brain-conventions.md`** writer tier (bounded, entrypoint-led).
- **`metrics-steward`:** Writes analytics under **`<content-brain>/analytics/`**; optional promotion of cross-tool metrics summaries into **`~/ai-brain/org/`** when policy says so.
- Internal personas: write only paths allowed in **`rules/orchestration.md`**; durable editorial content lives under **`<content-brain>/`**.
