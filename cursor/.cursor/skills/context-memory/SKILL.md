---
name: context-memory
description: Use whenever reading from or writing to the MCP memory server. Defines schema, namespaces, retrieval order, promotion rules, and how to interact with the memory knowledge graph. All agents must follow this skill for memory operations.
---

# Smart Context Memory

## Overview

Memory is stored in a single MCP knowledge graph at `~/.cursor/context/memory` (configured via `MEMORY_FILE_PATH` in mcp.json). Ensure `~/.cursor/context/` exists; use an absolute path if `~` is not expanded by your environment. All agents use this shared store. Memory holds **conclusions only** — no raw chat, no brainstorming dumps. Structure replaces embeddings; retrieval is deterministic.

**MCP tools available:** `create_entities`, `create_relations`, `add_observations`, `delete_entities`, `delete_observations`, `delete_relations`, `search_nodes`, `open_nodes`, `read_graph`.

**Critical rule:** NEVER use `read_graph`. Always use `search_nodes` or `open_nodes` with targeted queries. Loading all memory pollutes context and wastes tokens.

## Mapping to the Knowledge Graph

The MCP memory server uses entities, relations, and observations. Our schema maps as follows:

| Our field | Graph representation |
|-----------|------------------------|
| namespace | Entity name prefix: `{namespace}.{category}.{id}` |
| category | Entity type and name segment |
| summary | Observation: `summary: <text>` |
| tags | Observation: `tags: tag1,tag2,tag3` |
| status | Observation: `status: accepted\|experimental\|deprecated\|superseded` |
| created_at | Observation: `created_at: ISO8601` |
| rationale | Observation: `rationale: <text>` (optional) |
| supersedes | Relation: `entity_new --supersedes--> entity_old` |

**Entity naming:** `{namespace}.{category}.{short_id}`  
Examples: `org.global.decision.001`, `project.dotmate.api.constraint.auth`, `session.current.todo.xyz`  
Use a unique short_id (timestamp fragment, uuid prefix, or descriptive slug) to avoid collisions.

**Entity type:** Use the category value (`decision`, `constraint`, `assumption`, `rejected`, `todo`, `risk`, `principle`).

**Observations (array of strings):**
```
summary: <1-2 lines, max 300 chars, conclusion only>
tags: tag1,tag2,tag3
status: accepted
created_at: 2024-01-15T12:00:00Z
rationale: <optional brief explanation>
```

## Mandatory Fields Per Entry

Every memory entry must include:

- **namespace** — one of `org.global`, `org.security`, `project.<name>`, `project.<name>.<domain>`, `session.current`, `project.junk`
- **category** — one of: `decision`, `constraint`, `assumption`, `rejected`, `todo`, `risk`, `principle`
- **summary** — 1–2 lines max, <= 300 characters, conclusion only
- **tags** — minimum 2: one technical (e.g. `auth`, `k8s`, `redis`), one domain (e.g. `api`, `infra`, `security`). Lowercase, no spaces.
- **status** — one of: `accepted`, `experimental`, `deprecated`, `superseded`
- **created_at** — ISO 8601 timestamp

Optional: `rationale`, `supersedes` (via relation), `confidence`.

## Namespace Hierarchy

| Namespace | Use for |
|-----------|---------|
| `org.global` | Org-wide decisions, principles, constraints that apply across all projects |
| `org.security` | Security policies, auth patterns, threat mitigations |
| `project.<name>` | Project-level decisions; `<name>` from git remote or folder |
| `project.<name>.<domain>` | Domain-scoped (e.g. `api`, `infra`, `security`, `agents`) |
| `session.current` | Short-lived insights; promote or drop after 2 sessions |
| `project.junk` | Cross-cutting items that don't fit a specific project |

**Project name derivation:**
1. If in a git repo with remote: extract repo name from URL (e.g. `https://github.com/akshay-na/DotMate.git` → `dotmate`). Normalize to lowercase.
2. If no remote: use repo root folder name, lowercase.
3. If item doesn't belong anywhere: use `project.junk`.

## Retrieval Priority (Deterministic)

When reading memory, agents MUST:

1. Determine the most specific namespace relevant to the question.
2. Call `search_nodes` with a targeted query — e.g. `search_nodes("org.global decision auth")` or `search_nodes("project.dotmate api")`.
3. Do NOT call `read_graph`.

**Query construction:** Combine namespace fragment + category + relevant tags. Examples:
- `search_nodes("org.global decision")` — org-level decisions
- `search_nodes("project.dotmate security")` — dotmate security
- `search_nodes("org.security auth")` — security auth decisions

**Filtering (post-retrieval):** Prefer `accepted` over `experimental`; prefer `created_at` descending. Ignore `deprecated` and `superseded` unless explicitly reviewing history.

## Write Rules

**When to write:** After a decision or principle is clearly articulated and likely to matter beyond the current exchange. After identifying a meaningful risk, todo, constraint, or assumption.

**How to write (create_entities):**
```json
{
  "entities": [{
    "name": "org.global.decision.001",
    "entityType": "decision",
    "observations": [
      "summary: Use Redis for session storage. Rationale: scalability.",
      "tags: redis,auth",
      "status: accepted",
      "created_at: 2024-01-15T12:00:00Z"
    ]
  }]
}
```

**Supersession:** When a decision changes:
1. Create a new entity with the updated content and `status: accepted` (or `experimental`).
2. Create relation via `create_relations`: `{"from": "new_entity_name", "to": "old_entity_name", "relationType": "supersedes"}`.
3. When retrieving, treat entities that are the target of a `supersedes` relation as superseded — exclude them from active results unless explicitly reviewing history.

## Promotion Workflow

**Session → Project:** If an insight in `session.current` is referenced across 2+ sessions and still relevant, promote to `project.<name>` as `decision` or `principle` with `status=accepted`. Mark old session entry deprecated/superseded.

**Project → Org:** If a `decision` or `principle` is reinforced across multiple projects, create `org.global` entry with `status=accepted`. Optionally add `supersedes` relation to the most canonical prior project entry.

**Cleanup:** Avoid storing temporary debugging state. Periodically phase out `deprecated`/`superseded` from active use. Use `delete_entities` or `delete_observations` for entries that are no longer needed.

## What NOT to Store

- Full conversation logs
- Brainstorming dumps
- Speculative reasoning chains
- Temporary debugging state

## Example Flows

**Decision change:** CTO previously stored `org.global.decision.001` (use Redis for sessions). New decision: use PostgreSQL instead. Create `org.global.decision.002` with updated summary; add relation `org.global.decision.002 --supersedes--> org.global.decision.001`. When querying, exclude entities that are targets of `supersedes` unless reviewing history.

**Cross-project promotion:** `project.dotmate.api` and `project.otherproject.api` both have "prefer idempotent endpoints" as a principle. tech-lead or cto creates `org.global.principle.001` with that summary; optionally add `supersedes` relation to the most canonical project entry.

**Junk handling:** A one-off insight about "prefer mise over nvm for Node version management" doesn't belong to a specific project. Store in `project.junk.principle.001` with tags `tooling,node`.

## Design Philosophy

- Memory stores conclusions, not reasoning chains.
- Memory is curated, not appended.
- Structure replaces embeddings.
- Determinism > fuzzy similarity.
