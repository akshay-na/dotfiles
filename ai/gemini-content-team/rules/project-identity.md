# Project identity (binding)

**`<content-brain>`** must resolve to **`~/ai-brain/projects/<project_name>/`** using the **same** rules as Cursor **`kb-identity`** — full steps in **`skills/project-identity/SKILL.md`**.

## Precedence (first hit wins)

1. **`GEMINI_CONTENT_BRAIN`** — absolute path → use as **`<content-brain>`** (no derivation).
2. **`GEMINI_PROJECT_ROOT`** — absolute path → use as **`project_root`** for derivation.
3. **Inbound JSON** — `project_root` on **`cco`** / **`metrics-steward`** payloads when provided (automation / n8n).
4. **Workspace root** — directory Gemini CLI or the IDE treats as the active project (where user `@` files and edits anchor).
5. **Current working directory** — last resort for headless CLI (`PWD`).

Then run **`skills/project-identity/SKILL.md`** on **`project_root`** to get **`<project_name>`** and set:

**`<content-brain>`** = `$HOME/ai-brain/projects/<project_name>/`

## Cross-tool brain

- **Org / session / other projects:** unchanged — **`rules/brain-conventions.md`**, **`~/ai-brain/org/`**, **`~/ai-brain/session/`**, **`~/ai-brain/projects/<other>/`**.
- **This pipeline’s durable files:** only under **`<content-brain>/`** for the resolved project — identical layout to Cursor **project KB** under **`~/ai-brain/projects/<name>/`**.

## Conflicts

If **`project_root`** is ambiguous (multi-root workspace), **`cco`** must take **`project_root`** from payload or env — do not guess across unrelated repos in one run.
