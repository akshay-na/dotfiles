---
name: atlassian-hierarchy-discovery
description: |
  Bootstraps a Jira hierarchy snapshot before any multi-issue create / edit
  session. Disambiguates the parent input (issue key, spec URL, Confluence
  page URL, or `greenfield`), walks parents up (depth-cap 4), walks children
  down via JQL recursion (depth-cap 4, max 50 children per node), and
  returns a structured tree alongside the issue-type scheme and link-type
  metadata the caller needs to render a draft. Used primarily by
  `atlassian-pm`; secondary consumers (after the G2.5 retrofit) are the
  upstream Atlassian plugin skills `spec-to-backlog` and
  `capture-tasks-from-meeting-notes`. The skill **does not render**;
  rendering belongs to the caller (typically `atlassian-pm` rendering a
  markdown tree to chat).
version: 1.0.0
---

# `atlassian-hierarchy-discovery`

A pure read-side hierarchy discovery skill for the `plugin-atlassian-atlassian` MCP. The caller (typically `atlassian-pm`) hands in a parent reference; the skill returns a structured snapshot of what already exists, so the caller can prompt the user with a "this is what's there — what should we add?" tree before drafting writes.

## Used by

| Consumer                                                        | Role                                                                                                                                              |
| --------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cursor/.cursor/agents/atlassian-pm.md`                          | Primary consumer. Calls this skill at session start when ≥ 2 issues will be created, or when the user supplies a parent / initiative key.         |
| `~/.cursor/plugins/cache/cursor-public/atlassian/.../skills/spec-to-backlog/SKILL.md`                | After the G2.5 retrofit, `atlassian-pm` invokes this skill before drafting backlog items derived from a Confluence spec page.                     |
| `~/.cursor/plugins/cache/cursor-public/atlassian/.../skills/capture-tasks-from-meeting-notes/SKILL.md` | After the G2.5 retrofit, `atlassian-pm` invokes this skill before drafting tasks captured from a Confluence meeting-notes page.                   |
| `cursor/.cursor/agents/atlassian-pm.md` — plugin-skill retrofit  | All four upstream plugin skills (`spec-to-backlog`, `triage-issue`, `capture-tasks-from-meeting-notes`, `generate-status-report`) route through `atlassian-pm`; `atlassian-pm` itself is the only direct user of this skill. |

## Inputs schema

| Field                  | Type                                                              | Required | Default | Notes                                                                                                                                              |
| ---------------------- | ----------------------------------------------------------------- | -------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cloudId`              | string                                                            | yes      | —       | Resolved by the caller via `getAccessibleAtlassianResources` before invoking this skill.                                                          |
| `parent_input`         | enum: `greenfield` \| `<ISSUE-KEY>` \| `<spec_url>` \| `<confluence_page_url>` | yes      | —       | The user's answer to "what's the highest-level / initiative ticket?".                                                                             |
| `depth_cap`            | int                                                               | no       | `4`     | Maximum hops up (parent walk) AND maximum hops down (children walk). Caps blast radius and runtime.                                                |
| `project_key`          | string                                                            | yes      | —       | Constrains JQL recursion and child-walk to a single project; prevents cross-project leakage.                                                       |
| `max_children_per_node`| int                                                               | no       | `50`    | Per-node cap on the children walk. Larger trees are truncated and reported in `warnings`.                                                          |

## Outputs schema

```yaml
status: ok | skipped | error
root_key: <KEY> | null                 # null when parent_input == greenfield
project_key: <KEY>
hierarchy:
  - key: <KEY>
    type: Initiative | Epic | Story | Task | Sub-task | <custom>
    summary: <string>
    parent: <KEY> | null
    depth: <int>          # 0 = root
    existing: true        # always true; "new" nodes are added by the caller
    url: <string>
    last_updated: <RFC3339>
existing_count: <int>
allowed_child_types_per_node:
  <type>:
    - <child_type>
required_fields_per_type:
  <type>:
    - <field_id>
link_types:
  - id: <id>
    name: <name>
    inward: <string>
    outward: <string>
warnings:
  - depth_cap_reached_at: <KEY>
  - max_children_truncated_at: <KEY> (count_seen=<int>, truncated=<int>)
  - cross_project_parent_blocked: <KEY>
error_message: <string> | null
```

## Algorithm

### 1. cloudId resolution (caller-side)

The caller (typically `atlassian-pm`) MUST pre-resolve `cloudId` via `getAccessibleAtlassianResources` and `atlassianUserInfo`. This skill does NOT call those itself — it assumes the caller has already established auth and selected a cloud.

If the caller passes an empty/invalid `cloudId`, the skill returns `{ status: "error", error_message: "missing_cloud_id" }`.

### 2. Parent disambiguation

| `parent_input` shape         | Resolution                                                                                                                                                                                                   |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `greenfield`                 | `root_key=null`, `hierarchy=[]`, `existing_count=0`. Skip parent walk + children walk. Continue to step 5 (issue-type scheme) and step 6 (link types) so the caller can draft new nodes with valid metadata. |
| `<ISSUE-KEY>` (e.g. `PROJ-100`) | Use directly as `root_key` after a `getJiraIssue(<KEY>)` confirms existence.                                                                                                                                |
| `<spec_url>`                 | Search Jira for issues remote-linked to the URL via `getJiraIssueRemoteIssueLinks` + `searchJiraIssuesUsingJql` (`text ~ "<url>"`). On a single match, use it; on multiple, return `warnings: [{ ambiguous_parent: [<KEY>, ...] }]` and `error_message: "ambiguous_parent"`; the caller must re-prompt. |
| `<confluence_page_url>`      | Same as `<spec_url>` — Jira side via remote links. Confluence-side parent (a Confluence page parent) is **not** the parent of a Jira issue; the caller treats this as a Confluence-only context if they pass a page URL with `parent_input` mistakenly set. |

### 3. Preflight auth check

Call `getJiraIssue(<root_key>)` (or `getVisibleJiraProjects()` for `greenfield`) once. Any `401`/`403` returns `{ status: "error", error_message: "auth_lost" }` immediately — the caller surfaces re-auth instructions.

### 4. Walk parents up (depth-cap = `depth_cap`)

```
current = root_key
depth   = 0
while depth < depth_cap:
  issue = getJiraIssue(current)
  hierarchy.append({ key: current, type: issue.issuetype, ..., depth: depth, existing: true })
  if not issue.fields.parent: break
  if issue.fields.parent.project_key != project_key:
      warnings.append({ cross_project_parent_blocked: issue.fields.parent.key })
      break
  current = issue.fields.parent.key
  depth += 1
if depth == depth_cap and current still has parent:
    warnings.append({ depth_cap_reached_at: current })
```

The walk cuts off at the depth cap and at any cross-project boundary. Cross-project parents are recorded but not traversed (they break the project-key invariant).

### 5. Walk children down (depth-cap = `depth_cap`, breadth-cap = `max_children_per_node`)

JQL recursion against the **highest** ancestor we reached (i.e. the topmost member of the parents-up walk). For each ancestor, run:

```
jql = parent = <KEY> AND project = <PROJECT_KEY>
results = searchJiraIssuesUsingJql(jql, max_results = max_children_per_node + 1)
```

If `len(results) > max_children_per_node`, record `{ max_children_truncated_at: <KEY>, count_seen: len(results), truncated: len(results) - max_children_per_node }` in `warnings` and keep only the first `max_children_per_node`. Recurse on each retained child until `depth == depth_cap` (record `depth_cap_reached_at` warning if children remain).

The walk is **breadth-first** so the caller sees a balanced tree. Order within a level is by `key` ascending for deterministic rendering.

### 6. Issue-type scheme + link-type fetch

- `getJiraProjectIssueTypesMetadata(project_key)` → populate `allowed_child_types_per_node`. Map each issue type to the child types that may live under it (Initiative → Epic; Epic → Story / Task; Story → Sub-task; etc., per the project's scheme — the skill does NOT hard-code Atlassian Cloud's defaults; it reads from the project).
- `getJiraIssueTypeMetaWithFields(project_key, <type_id>)` for each unique type encountered in the hierarchy + each type the caller plans to use → populate `required_fields_per_type`.
- `getIssueLinkTypes()` → populate `link_types` (caller uses this to pick `Blocks` / `Relates` / `Implements` etc. when drafting links).

### 7. Return

The skill returns the structured outputs object. **The skill does NOT render the tree to chat** — that is the caller's job. The caller (typically `atlassian-pm`) renders an ASCII / markdown tree using `existing: true` markers and adds `✚ <KEY>` placeholders for new nodes the user will create.

## Pre-validation

Before calling any MCP tool:

- `cloudId` is non-empty.
- `project_key` is non-empty and matches `^[A-Z][A-Z0-9_]+$`.
- `parent_input` is `greenfield` OR a recognised shape from the disambiguation table.
- `depth_cap` ∈ `[1, 6]`. Default 4. Values outside the range → clamp + `warnings.append({ depth_cap_clamped: <orig> })`.
- `max_children_per_node` ∈ `[10, 200]`. Default 50.

## Post-validation

After populating the outputs:

- `status == "ok"` requires `error_message == null` and at least one of: `root_key != null` (non-greenfield) OR `parent_input == "greenfield"`.
- `existing_count == len(hierarchy)`.
- For each entry in `hierarchy`, `depth >= 0` and `depth <= depth_cap`.
- For each entry in `hierarchy`, `parent` is null OR present elsewhere in `hierarchy` OR flagged as a cross-project boundary in `warnings`.

If post-validation fails: return `{ status: "error", error_message: "post_validation_failed", warnings: [<details>] }`.

## Failure modes

| Mode                          | Cause                                                                                                  | Returned                                                                          |
| ----------------------------- | ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| `missing_cloud_id`            | Caller passed empty / invalid `cloudId`.                                                               | `{ status: "error", error_message: "missing_cloud_id" }`.                         |
| `auth_lost`                   | First MCP call returned `401`/`403`.                                                                   | `{ status: "error", error_message: "auth_lost" }`.                                |
| `parent_not_found`            | `getJiraIssue(<root_key>)` 404.                                                                        | `{ status: "error", error_message: "parent_not_found" }`.                         |
| `ambiguous_parent`            | `parent_input` was a URL that matched multiple issues.                                                 | `{ status: "error", error_message: "ambiguous_parent", warnings: [...] }`.        |
| `cross_project_parent`        | Highest ancestor lives in another project.                                                             | `{ status: "ok", warnings: [{ cross_project_parent_blocked: <KEY> }] }` (still ok). |
| `depth_cap_reached`           | Walk hit the depth cap with more parents/children remaining.                                           | `{ status: "ok", warnings: [{ depth_cap_reached_at: <KEY> }] }`.                  |
| `max_children_truncated`      | A node had more children than `max_children_per_node`.                                                 | `{ status: "ok", warnings: [{ max_children_truncated_at: <KEY>, ... }] }`.        |
| `mcp_unauth_mid_walk`         | MCP returned `401`/`403` after the preflight call (e.g. token expired mid-walk).                       | `{ status: "skipped", error_message: "auth_lost_mid_walk" }`.                     |
| `5xx_mcp`                     | MCP returned `5xx` for any tool call.                                                                  | `{ status: "error", error_message: "mcp_5xx", warnings: [<tool, details>] }`.     |
| `429_mcp`                     | MCP rate-limited.                                                                                       | `{ status: "error", error_message: "mcp_429", warnings: [{ retry_after: <s> }] }`. |
| `post_validation_failed`      | Internal consistency check failed (parent not in tree, etc.).                                          | `{ status: "error", error_message: "post_validation_failed" }`.                   |

The skill never auto-retries; the caller decides whether to retry, surface to the user, or proceed without hierarchy context.

## What this skill does NOT do

- It does **NOT** render the hierarchy to chat. Rendering an ASCII / markdown tree to the user is the caller's responsibility.
- It does **NOT** create, edit, transition, or comment on any issue or page. It is read-only.
- It does **NOT** ask the user for clarification. If `parent_input` is ambiguous, the skill returns `ambiguous_parent` and the caller re-prompts.
- It does **NOT** auto-resolve `cloudId`. The caller pre-resolves auth before invoking.
- It does **NOT** walk across projects. Cross-project parents are recorded as warnings and not traversed.
- It does **NOT** apply audience-translation scrubbing. Returned summaries / titles are raw; if the caller chooses to render them, the caller applies its own scrubber (this skill returns `existing: true` Atlassian-side data verbatim apart from secret detection at the caller level).
- It does **NOT** retry on failure. The caller decides retry semantics.
