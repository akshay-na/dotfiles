# Brain conventions — unified ai-brain (Gemini)

Aligned with Cursor `~/.cursor/rules/brain-conventions.mdc`. Gemini agents use the **same** vault layout and discipline.

## Canonical root

- Root: `~/ai-brain/`
- Integrated namespace (no top-level KB/memory split at the filesystem level).
- Tracked skeleton (dotfiles stow): `_schema/`, `_templates/`, `README.md`, `.gitignore`.
- Local runtime content: `projects/`, `org/`, `session/`, `.meta/`, `Home.md`, `.obsidian/graph.json`.

## Operating model

- **Memory lane (RAM-like):** short-lived orchestration context, session notes, quick recall under `session/` and compact org scratch that is safe to supersede.
- **Knowledge lane (HDD-like):** durable, canonical structural and decision knowledge under `org/` and `projects/<name>/`.
- **Promotion path:** memory → KB when reused, stable, or high-signal.

## Query and token discipline

- Lookup-first, body-later.
- Escalate query depth only when needed.
- Prefer compact summaries and reference pointers.
- Avoid duplicate payload transfer between subagents and orchestrators.

## Writer policy (cross-tool)

Same roles as Cursor, interpreted for Gemini:

- **Org-tier touch-write (bounded):** Cursor C-suite + `tech-lead` analogs; for Gemini **orchestration**, `cco` and **`metrics-steward`** may coordinate writes to `~/ai-brain/` only when the change matches org/process/metrics namespaces and does not violate dedup / touch-write quotas. Prefer the same path ownership as Cursor (`org/global`, `projects/<name>/`, etc.).
- **Excluded from KB/memory writes (dedup):** treat `code-reviewer`, `senior-dev`, `cro` and **standalone** internal editorial personas the same way—**read/query only** for `~/ai-brain/` unless a single org entrypoint (`cco` outer run) delegates a scoped write documented in the run ledger.
- **Project agents** (`dev-*`, `sme-*`, `qa-*`, `reviewer-*`, `devops`): read/query only for `~/ai-brain/`.

Internal personas (`vp-editorial`, editors, `qa-content`, etc.) follow **`rules/orchestration.md`** for **`<content-brain>/`** paths (**`~/ai-brain/projects/<project_name>/`** per **`rules/project-identity.md`** — Cursor **`kb-identity`** parity). Ephemeral run state uses **`~/.gemini/memory/`** (`rules/memory.md`).

## Retention and growth

- Do not auto-delete memory.
- Keep memory bounded via dedupe, supersede, archive, and compact entries.
- Promote stable decisions, constraints, risks, and principles into durable KB nodes under `~/ai-brain/projects/<name>/` or `~/ai-brain/org/` as appropriate.
