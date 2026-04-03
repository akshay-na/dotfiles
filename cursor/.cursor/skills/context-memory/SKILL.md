---
name: context-memory
description: File-based Markdown memory at ~/.cursor/memory/. Any agent can read/write directly using this skill. No external dependencies.
---

# Context Memory (File-based)

## Overview

Memory is stored as Markdown files under `~/.cursor/memory/`. No external services, no containers, no network dependencies. Any agent can access memory directly using this skill.

Each namespace maps to a directory. Each entry is a `.md` file with YAML frontmatter. Each directory has an `_index.md` for fast lookup.

## Local-only Semantics

Memory content is **local to each machine** and never tracked in the dotfiles repo. Rules, skills, and agents sync via dotfiles; memory content does not. A new machine starts with empty memory — this is intentional. Rebuild context as you work.

## Namespaces and Directories

| Namespace | Directory |
|---|---|
| `org.global` | `org/global/` |
| `org.security` | `org/security/` |
| `project.<name>` | `projects/<name>/` |
| `project.<name>.<domain>` | `projects/<name>/<domain>/` |
| `project.junk` | `projects/junk/` |
| `session.current` | `session/current/` |

All paths are relative to `~/.cursor/memory/`. Derive `<name>` from git remote or repo folder, lowercased.

## Entity Schema

Each `.md` file has YAML frontmatter followed by a body:

```yaml
---
entity_name: org.global.decision.001
namespace: org.global
category: decision
status: accepted
tags: [auth, security]
created_at: 2026-04-03T10:00:00Z
rationale: Brief explanation of why
supersedes: []
confidence: 0.9
source_path: docs:global/decisions/auth-flow.md
updated_at: 2026-04-03T10:00:00Z
---

Body text with the conclusion. 1-3 sentences. No reasoning chains.
```

**Mandatory fields**: `entity_name`, `namespace`, `category`, `status`, `tags` (min 2), `created_at`

**Optional fields**: `rationale`, `supersedes`, `confidence`, `source_path`, `updated_at`

**Categories**: `decision`, `constraint`, `assumption`, `rejected`, `todo`, `risk`, `principle`, `diagram`

**Status values**: `accepted`, `experimental`, `deprecated`, `superseded`

## Diagram Variant

Diagrams use additional frontmatter fields:

```yaml
diagram_language: mermaid
diagram_type: flowchart
diagram_subject: memory-write-flow
diagram_code: |
  flowchart TD
    A[Start] --> B[Write file]
    B --> C[Update index]
related_entities: [org.global.decision.001]
```

The body describes the diagram in natural language. Mermaid code goes in `diagram_code` frontmatter, not the body.

## File Naming

- **File**: `{category}-{short_id}-{slug}.md` (e.g., `decision-001-auth-flow.md`)
- **Entity**: `{namespace}.{category}.{short_id}` (e.g., `org.global.decision.001`)
- **short_id**: Sequential number (001, 002) or descriptive slug

## `_index.md` Schema

```markdown
# Index: {namespace}

> Last updated: 2026-04-03T10:00:00Z

| Entity | Category | Summary | Tags | Status | File |
|---|---|---|---|---|---|
| org.global.decision.001 | decision | Auth uses JWT | auth, security | accepted | decision-001-auth-flow.md |
```

Every write must update the index. The index enables fast filtering without reading all files.

## Read Protocol

1. Identify namespace(s) relevant to task
2. Check if directory exists — if not, no memory for that namespace
3. Read `_index.md`; scan table for category, tags, keyword, status matches
4. Read individual `.md` files **only** for matches; **max 5 per query**
5. Prefer `status: accepted` over `experimental`; prefer recent `created_at`; prefer strong tag overlap
6. Ignore `deprecated` and `superseded` unless reviewing history
7. Do NOT query `session/current/` unless explicitly needed for recent context

## Write Protocol

**Steps 5 and 6 are atomic — never create a file without updating the index.**

```
Step 1: Determine target namespace and directory path
Step 2: If directory does not exist, create it with empty _index.md
Step 3: Read _index.md — check for duplicates by category + similar summary
Step 4: Generate entity_name: {namespace}.{category}.{short_id}
        (short_id: next sequential number from index, or descriptive slug)
Step 5: Create the .md file with YAML frontmatter + body
Step 6: MANDATORY — Append new row to _index.md with:
        entity_name | category | summary (≤100 chars) | tags | status | filename
Step 7: If updating existing entry, update the row in _index.md too
```

## Index Self-Healing

Any agent that detects mismatch between `_index.md` and actual files should repair inline:

1. List all `.md` files (excluding `_index.md`, `_pending_refresh.md`)
2. Parse YAML frontmatter from each
3. Regenerate `_index.md` from parsed data
4. Continue with original task

**Detection triggers** (lazy, not on every read):
- File referenced in index doesn't exist
- `.md` file exists but no row in index
- Row count doesn't match file count

## Promotion and Supersession

**Promotion**: Change `status` from `experimental` to `accepted` in both file and index. For namespace promotion (project → org), create new entry in target namespace with `supersedes` pointing to source.

**Supersession**: When revising a decision:
1. Create new entry with `supersedes: [old_entity_name]`
2. Update old entry's status to `superseded` in both file and index
3. Add `updated_at` to old entry noting when it was superseded

## Session Memory

Session entries live in `session/current/`. They are ephemeral.

- Write only for insights that matter within current session
- Before ending session with valuable insights, promote to project namespace
- Do NOT load `session/current/_index.md` unless explicitly needed
- Keep session entries minimal; stable insights go directly to project/org

## Namespace Scaling

When a namespace exceeds ~50 entries, split by domain:

- **Before**: `projects/myapp/` (55 entries, mixed)
- **After**: `projects/myapp/api/`, `projects/myapp/frontend/`, etc.

Move entries to subdirectories. Create `_index.md` in each. Update parent to contain only cross-cutting entries or remove it.

## What to Store / What NOT to Store

**Store**: Stable decisions, constraints, principles, risks, todos, diagrams, pointers to docs

**Do NOT store**: Raw chat logs, secrets/tokens/PII, large code dumps (git has them), ephemeral scratch notes, implementation details obvious from code

## Sync Hooks

Install hooks to track file changes on main/master branch merges:

```bash
cp $HOME/dotfiles/scripts/.local/bin/cursor-memory-hook .git/hooks/post-merge
cp $HOME/dotfiles/scripts/.local/bin/cursor-memory-hook .git/hooks/post-checkout
chmod +x .git/hooks/post-merge .git/hooks/post-checkout
```

The hook only runs on `main` or `master` branches. It writes `_pending_refresh.md` listing changed files. `memory-access` rule instructs agents to process pending refreshes at session start. `vp-onboarding` copies the hooks during project bootstrap (if the source file exists).

## Migration from Previous System

If migrating from a previous memory system:

1. Export important entries before removing the old system
2. Create equivalent `.md` entries in new `~/.cursor/memory/` structure
3. Preserve old data at `~/.cursor/memory/archive/` as backup
4. Remove old system after confirming migration complete

## Design Philosophy

- Memory stores **conclusions**, not reasoning chains
- Memory is **curated**, not appended
- Namespaces, categories, tags provide **structure**
- Directory scoping is **deterministic**; index scanning supports **filtering**
