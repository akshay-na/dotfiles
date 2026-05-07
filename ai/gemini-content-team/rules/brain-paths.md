# Content pipeline paths (ai-brain)

**`<content-brain>`** = durable editorial root for **this** run. Resolve **before** any read/write under the pipeline (see **`rules/project-identity.md`** + **`skills/project-identity/SKILL.md`** — **ditto Cursor `kb-identity`** → **`~/ai-brain/projects/<project_name>/`**).

## Resolution recap

1. **`GEMINI_CONTENT_BRAIN`** (absolute) → use directly.
2. Else derive **`project_name`** from **`project_root`** (env, payload, workspace, `PWD`) per **`skills/project-identity/SKILL.md`**.
3. **`<content-brain>`** = **`$HOME/ai-brain/projects/<project_name>/`**.

Below, **`<ROOT>`** === **`<content-brain>`** after resolution.

## Layout (under `<ROOT>/`)

Same subtree Cursor uses for a **project** node in **`~/ai-brain/projects/<name>/`** — editorial pipeline folders only:

| Area                    | Path                                                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------------------------------- |
| Ideas                   | `<ROOT>/ideas/`                                                                                               |
| Topics                  | `<ROOT>/topics/`                                                                                              |
| Briefs                  | `<ROOT>/briefs/`                                                                                              |
| Drafts                  | `<ROOT>/drafts/<channel>/` — channels: `blog`, `twitter`, `linkedin`, `shorts`, `newsletter`                  |
| Published               | `<ROOT>/published/`                                                                                           |
| Repurposed              | `<ROOT>/repurposed/`                                                                                          |
| Meta / ledger           | `<ROOT>/_meta/` — e.g. `ledger.json`, `topic-index.json`, `slug-index.json`, optional `frontmatter.schema.md` |
| Analytics               | `<ROOT>/analytics/` — `metrics-current.json`, `metrics-summary.md`, `metrics-latest.md`, `history/`           |
| Brand                   | `<ROOT>/brand/` — `voice.md`, `glossary.md`, `constraints.md`                                                 |
| Integrations (optional) | `<ROOT>/integrations/` — e.g. n8n contract copies                                                             |

## Ephemeral pipeline state (Gemini home)

Not the project KB subtree; local to Gemini runs:

- **`~/.gemini/memory/pipelines/`** — `current-state.md`, `runs/`, `failures/`
- **`~/.gemini/memory/observability/`** — `events.jsonl`, optional `runs/<run_id>.jsonl`
- **`~/.gemini/memory/_schema/`** — schemas for local observability only

Promote stable conclusions into **`<ROOT>/`** or **`~/ai-brain/org/`** per **`rules/brain-conventions.md`**.

## Writers

- **`metrics-steward`** alone writes **`metrics-current.json`**, **`metrics-summary.md`**, **`analytics/history/*`**, **`metrics-latest.md`** under **`<ROOT>/analytics/`** (unless a written exception exists).
- **`archivist`** / **`kb-librarian`:** **`<ROOT>/published/`**, **`<ROOT>/_meta/*`**; serialize conflicting **`_meta/`** updates via orchestration.

## Metrics read paths (`METRICS_READ`)

- **`<ROOT>/analytics/metrics-current.json`**
- **`<ROOT>/analytics/metrics-latest.md`**
