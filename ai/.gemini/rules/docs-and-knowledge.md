# Documentation and knowledge (Gemini)

Mirrors Cursor `~/.cursor/rules/docs-and-decisions.mdc` for **where** durable knowledge lives. Gemini has no `brain-memory-kb` skill file here—apply the **same three-tier model** by path and process.

## Three-tier model

| Tier | Location | Content | Ownership |
| ---- | -------- | ------- | --------- |
| **Brain memory + KB** | `~/ai-brain/` | Decisions, constraints, risks, principles; project hubs under `projects/<name>/` | Org entrypoints (`cco` outer run, `metrics-steward` where metrics belong in org namespace); read/query for most personas |
| **Project docs (Cursor)** | `<project>/.cursor/docs/` | Plans, ADRs, runbooks | Agents writing in Cursor context |
| **Project docs (Gemini / repo)** | `<project>/.gemini/docs/` if present | Same intent for Gemini-first repos | Same discipline as `.cursor/docs/` |

### When to use which tier

**`~/ai-brain/` (memory + KB)** — cross-session conclusions and reusable structure:

- Decided constraints, SLO notes, org-wide patterns.
- Project overview graph and module docs under `~/ai-brain/projects/<name>/`.
- Session ledger paths under `~/ai-brain/session/<task-id>/` where policies require it.

**Project docs** — long-form, VCS-friendly write-ups next to the repo:

- Implementation plans, ADRs, runbooks.
- Use date-stamped filenames: `YYYY-MM-DD-slug.md` under `plans/`, `decisions/`, `runbooks/`.

### Query ladder (conceptual)

Same as Cursor `brain-memory-kb`:

1. Index / hub first (`_index.md`, `Home.md`, project hub).
2. Narrow query (module, relationship) only if needed.
3. Project agents: prefer **read/query** of `~/ai-brain/`; broad KB writes stay with org entrypoints.

## Project-local layout (reference)

```
<project>/.cursor/          # Cursor
├── docs/
│   ├── plans/
│   ├── decisions/
│   └── runbooks/

<project>/.gemini/          # optional Gemini mirror
├── docs/
│   ├── plans/
│   ├── decisions/
│   └── runbooks/
```

## Decision records

- Record rationale, alternatives, implications in `decisions/` or in `~/ai-brain/` as compact nodes with links—avoid pasting the full ADR body in both places.

## Memory integration

- **Unified brain:** `~/ai-brain/` per **`rules/brain-conventions.md`**.
- **Gemini-local scratch:** `~/.gemini/memory/` for pipeline/runs only—**not** a substitute for `~/ai-brain/`.
- **`.cursor/memory/`** (if used from Cursor) remains Cursor-local scratch; promote durable facts to `~/ai-brain/`.
- **Editorial durable paths:** **`<content-brain>/`** = **`~/ai-brain/projects/<project_name>/`** (`rules/project-identity.md`, `rules/content-brain-paths.md`). **`project_name`** matches Cursor **`kb-identity`** for the **same `project_root`**, so Cursor and Gemini **share** that project subtree under **`~/ai-brain/projects/`** by default.

---

## Agent expectations

- Prefer `~/ai-brain/` for anything that must survive across Cursor, Gemini, and repos.
- Check existing hubs before new duplicate nodes.
- Cross-link brain paths to project docs when useful.
