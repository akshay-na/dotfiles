---
name: context-memory
description: Use whenever reading from or writing to Qdrant-backed memory. Defines schema, namespaces, retrieval order, promotion rules, diagram handling, and how to interact with the Qdrant MCP server. All agents must follow this skill for memory operations.
---

# Smart Context Memory (Qdrant-only)

## Overview

Memory is stored **only** in Qdrant collections managed by the `qdrant` MCP server. There is **no JSONL graph file**, no `server-memory` MCP, and no fallback file-based cache.

The Qdrant data directory lives under:

- `~/.cursor/memory/qdrant` (mounted into the Qdrant container)

All agents share a single Qdrant instance with a **fixed set of collections**:

- `org_memory` — org-wide, long-lived knowledge
- `project_memory` — project-scoped, long-lived knowledge
- `session_memory` — session-scoped knowledge (`session.current`)
- `cache_memory` — ephemeral cache and staging area for new / experimental entries

Qdrant is accessed via a single MCP server named `qdrant` in `~/.cursor/mcp.json`:

- `QDRANT_URL` points at the running Qdrant instance.
- `COLLECTION_NAME` defaults to `org_memory` (org-level collection).
- Other collections are selected per-call using the `collection_name` argument on Qdrant tools.

Memory holds **conclusions only** — no raw chat, no brainstorming dumps. Structure (namespaces, categories, tags, status) drives retrieval; embeddings are a ranking signal on top.

## Namespaces and Collections

Namespaces are unchanged and still drive how you think about scope:

- `org.global` — Org-wide decisions, principles, constraints that apply across all projects
- `org.security` — Security policies, auth patterns, threat mitigations
- `project.<name>` — Project-level decisions; `<name>` from git remote or folder, lowercase
- `project.<name>.<domain>` — Domain-scoped (e.g. `api`, `infra`, `security`, `agents`)
- `session.current` — Short-lived insights within the current session
- `project.junk` — Cross-cutting items that don't fit a specific project

These namespaces map to Qdrant collections as follows:

- `org.global`, `org.security` → `org_memory`
- All `project.<name>` and `project.<name>.<domain>`, and `project.junk` → `project_memory`
- `session.current` → `session_memory`

The `cache_memory` collection is used as an **ephemeral staging area**:

- New or low-confidence entries start in `cache_memory` when appropriate.
- Stable entries are promoted from `cache_memory` into `project_memory` or `org_memory`.

## Entity Schema in Qdrant

Each memory entry is stored as a single Qdrant point:

- **ID**: `entity_name` (string; can be used directly as the point ID)
- **Vector**: embedding of an `embedding_text` string derived from summary/rationale/tags
- **Payload** (JSON object) with at least:
  - `entity_name`: string (canonical identifier)
  - `namespace`: string (e.g. `project.dotmate.api`)
  - `category`: string
  - `summary`: string (1–2 lines, <= 300 chars, conclusion only)
  - `tags`: string[]
  - `status`: string (`accepted`, `experimental`, `deprecated`, `superseded`)
  - `created_at`: ISO 8601 string
  - `rationale`: optional string
  - `supersedes`: string[] of `entity_name`s (when applicable)
  - `project`: string (derived from namespace, e.g. `dotmate`)
  - `source`: `"primary" | "fallback" | "imported"` (typically `"primary"` in this architecture)
  - `last_synced_at`: ISO 8601 string
  - `confidence`: optional number between 0 and 1

### Mandatory fields per entry

Every memory entry must include:

- **namespace** — one of `org.global`, `org.security`, `project.<name>`, `project.<name>.<domain>`, `session.current`, `project.junk`
- **category** — one of: `decision`, `constraint`, `assumption`, `rejected`, `todo`, `risk`, `principle`, `diagram`
- **summary** — 1–2 lines max, <= 300 characters, conclusion only
- **tags** — minimum 2: one technical (e.g. `auth`, `k8s`, `redis`), one domain (e.g. `api`, `infra`, `security`). Lowercase, no spaces.
- **status** — one of: `accepted`, `experimental`, `deprecated`, `superseded`
- **created_at** — ISO 8601 timestamp

Optional: `rationale`, `supersedes`, `confidence`, diagram-specific fields (see below).

### Entity naming

Use the same pattern as before:

- `entity_name = {namespace}.{category}.{short_id}`
- Examples:
  - `org.global.decision.001`
  - `project.dotmate.api.constraint.auth`
  - `session.current.todo.xyz`

`short_id` should be unique (timestamp fragment, uuid prefix, or descriptive slug).

## Embedding Text Construction

Qdrant computes embeddings from a free-form text string. Construct `embedding_text` as:

- For non-diagram entities:

```text
{summary}

rationale: {rationale}

tags: {tag1,tag2,...}

namespace: {namespace} category: {category}
```

- For diagram entities (`category="diagram"`), see the dedicated section below.

Agents do **not** need to call the embedding model directly; they pass this `embedding_text` to the Qdrant MCP tools that handle embedding internally.

## Diagram Entities (`category="diagram"`)

Diagrams are first-class memory entities stored in Qdrant with `category="diagram"`.

When a plan or workflow is important enough to store (especially for org-wide agents like `cto`, `vp-architecture`, `vp-engineering`):

- Generate a mermaid diagram (e.g. `flowchart`, `sequence`, `state`).
- Create a `diagram` entity with:
  - `summary`: 1–2 lines describing what the diagram shows.
  - `rationale`: why the diagram exists / what decision or flow it captures.
  - `tags`: must include `diagram` and `mermaid` plus domain tags (`architecture`, `memory`, `infra`, etc.).
  - Diagram-specific payload fields:
    - `diagram_language`: string (e.g. `"mermaid"`)
    - `diagram_type`: string (e.g. `"flowchart"`, `"sequence"`, `"state"`)
    - `diagram_code`: string (the original mermaid code)
    - `diagram_hash`: string (short hash of `diagram_code` for deduplication)
    - `diagram_scope`: string (`"org"`, `"project"`, or `"session"`)
    - `diagram_subject`: string (short label, e.g. `"qdrant_memory_architecture"`)
    - `related_entities`: string[] of `entity_name`s this diagram explains

Store diagram entities in:

- `org_memory` with `namespace="org.global.diagram.*"` for cross-project/global flows.
- `project_memory` with `namespace="project.<name>.diagram.*"` for project-specific flows.

### Embedding text for diagrams

**Do not embed raw mermaid code.** Instead, describe the diagram in natural language:

```text
{summary}

rationale: {rationale}

diagram_subject: {diagram_subject}

diagram_type: {diagram_type}

tags: {tag1,tag2,...}

namespace: {namespace} category: {category}
```

Qdrant uses this text for embeddings so diagrams can be retrieved semantically by subject, type, and tags.

## Read Behavior (Normal Mode)

In **normal mode** (Qdrant healthy), agents read memory only via the `qdrant` MCP server.

When reading memory:

1. Determine the most specific namespace relevant to the question.
2. Choose appropriate collections:
   - Project-scoped questions → `project_memory` (+ optionally `org_memory`).
   - Org-wide questions → `org_memory`.
   - Session-focused questions → `session_memory`.
   - For very recent or experimental context → also query `cache_memory`.
3. Call Qdrant search tools with:
   - `collection_name` set to the desired collection (`project_memory`, `session_memory`, `cache_memory`), or omit it to use the default `org_memory`.
   - Filters on payload fields such as `namespace`, `category`, `project`, `status`, `tags`.
   - A textual query (e.g. built from summary-like phrasing and key tags).
4. Combine results from multiple collections when needed:
   - Prefer long-lived entries from `org_memory` / `project_memory`.
   - Augment with recent entries from `session_memory` and `cache_memory`.

### Ranking and filtering

After retrieving candidates:

- Start from vector similarity.
- Prefer:
  - `status=accepted` over `experimental`.
  - Recent `created_at` / `updated_at`.
  - Strong tag overlap with the current task.
- Ignore `deprecated` and `superseded` unless explicitly reviewing history.

## Write Behavior (Normal Mode)

Write to Qdrant only when a conclusion is stable or clearly worth persisting.

**When to write:**

- After a decision, principle, or constraint is clearly articulated and likely to matter beyond the current exchange.
- After identifying a meaningful risk, todo, or assumption.
- When recording important diagrams that represent flows or architectures.

**Where to write (collection selection):**

- `org_memory`:
  - Org-level decisions, principles, constraints.
  - Cross-project diagrams and global policies.
- `project_memory`:
  - Project-scoped decisions/principles/constraints.
  - Project-specific diagrams.
- `session_memory`:
  - Short-lived insights that may or may not be promoted later.
- `cache_memory`:
  - New, unproven, or tentative entries, especially when confidence is low.

**How to write:**

- Construct `entity_name`, payload fields, and `embedding_text`.
- Upsert via Qdrant MCP tools, passing:
  - `collection_name` based on the mapping above.
  - The point ID, payload, and embedding_text.

**Supersession and updates:**

- When a decision changes:
  - Create a new entity with updated content and `status=accepted` or `experimental`.
  - In payload, set `supersedes` to include the old `entity_name`.
  - Treat entities that appear in `supersedes` lists as superseded in active retrieval.

## Promotion Workflow (Cache → Project → Org)

Promotion is how entries move from ephemeral to durable collections:

- **Session → Project:**
  - If a `session.current` insight is referenced across 2+ sessions and remains relevant:
    - Create a new entity in `project_memory` (namespace `project.<name>` or `project.<name>.<domain>`).
    - Mark the original `session.current` entry as `deprecated` or add it to `supersedes`.

- **Cache → Project:**
  - New or experimental entries may start in `cache_memory` with:
    - `status=experimental`.
    - Lower `confidence`.
  - When they prove useful and stable:
    - Re-write them into `project_memory` with `status=accepted` and higher `confidence`.
    - Optionally mark the cache entry as `deprecated` or track supersession via payload.

- **Project → Org:**
  - If a decision/principle is reinforced across multiple projects:
    - Create `org.global` entry in `org_memory` with `status=accepted`.
    - Optionally include `supersedes` pointing at the most canonical prior project entry.

- **Cleanup:**
  - Periodically de-emphasize or remove:
    - `deprecated` / `superseded` entries from active use.
    - Stale entries in `cache_memory` that never graduated.

## Fallback Behavior (Qdrant Unavailable)

Qdrant is the **only** persistent memory backend. When it is unavailable:

- Agents must **stop all memory reads/writes**.
- Agents must **not** fall back to any JSONL files, `server-memory` MCPs, or alternate stores.

### Detecting Qdrant health

- On session start (and periodically), a lightweight Qdrant MCP call should be made (e.g. list collections or a dedicated health/`/collections` ping).
- If the call succeeds:
  - Mark Qdrant as healthy for this session (`fallback=false`).
- If the call fails (timeout, connection error, non-OK status):
  - Mark Qdrant as unavailable (`fallback=true` for this session).

### Behavior in fallback mode

When `fallback=true`:

- **Do not** call any Qdrant MCP tools.
- Do not claim that long-term memory has been read or updated.
- Operate only on:
  - The current conversation.
  - Any ephemeral, in-process state (not persisted).
- Clearly inform the user the first time you detect fallback:
  - Example: “Vector memory (Qdrant) is unavailable; long-term memory reads/writes are disabled for this session.”
- Optionally record a transient `session.current.risk` in *ephemeral* reasoning (not persisted) noting the outage.

When a subsequent health check indicates Qdrant is healthy again:

- Clear the `fallback` flag for new operations.
- Resume normal mode (reads/writes via Qdrant collections).
- There is **no** separate fallback datastore; anything that happened while Qdrant was down is not persisted.

## Design Philosophy

- Memory stores conclusions, not reasoning chains.
- Memory is curated, not appended.
- Namespaces, categories, and tags provide structure; Qdrant embeddings rank within that structure.
- Deterministic scoping (namespace and collection) comes first; similarity search is a supporting signal.
