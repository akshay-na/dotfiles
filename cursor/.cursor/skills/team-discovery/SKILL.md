---
name: team-discovery
description: "Discovery + naming convention reference for typed dev/SME/QA/devops team members in any workspace folder. Primary consumer: `tech-lead` (org-tier)."
---

# Team Discovery

## When to Use

- You are `tech-lead` about to assign work to project agents.
- You are a dev/SME/QA agent unsure how to interpret team member names or scopes.
- You need a reminder on keeping context/token usage low when delegating or executing tasks.

## `discover(workspace_roots) → map<root, roles[]>`

For **each** directory `root` in `workspace_roots`, run discovery against that root’s agent pool (multi-folder workspaces repeat this per root).

Before assigning any work (for both direct tasks and plan-driven phases), for each `root`:

1. List all project-level agent files under `{root}/.cursor/agents/` that match team patterns (`dev-*`, `reviewer-*`, `sme-*`, `qa-*`, `devops`).
2. For each, read enough of the file to extract the agent **name**, its stated **scope**, and its **`parallelizable`** flag.
3. Build an internal table (e.g. `| Agent | Scope | Parallelizable |`) that you use to decide assignments and execution strategy.
4. Re-run this discovery at the start of each phase (and when onboarding changes the team) so you always work from the current team.

**Output:** `map<root, roles[]>` where `roles[]` is the ordered list of discovered typed agents (and their metadata from the table) for that `root`.

## `classify(touches[]) → map<root, touches_subset[]>`

**Longest-prefix-match:** For each path in `touches[]`, assign it to exactly one `root` in `workspace_roots` by choosing the **longest** `root` path such that the touch path is contained under that root (normalized path-prefix containment). Ties or unclear containment must not be broken by arbitrary choice.

**`on_ambiguous: ask_user` invariant:** If longest-prefix-match yields a tie (two or more roots equally qualify), no qualifying root, or ambiguity after path normalization, **do not infer** — ask the user which root owns the touch before proceeding to `dispatch`.

**Output:** `map<root, touches_subset[]>` aggregating, per root, the subset of `touches[]` assigned to that root. Every classified touch appears under exactly one root once disambiguation is complete.

## `dispatch(map<root, touches[]>)`

Apply **assignment rules** when turning classified touches into agent work:

- Match tasks to agents by scope. If `dev-1` owns frontend, frontend tasks go to `dev-1`.
- If a task falls outside all dev scopes, escalate to the user or `cto`, or trigger team refresh (`vp-onboarding`) — **never** implement it yourself.
- If a task needs domain expertise, route it to the relevant `sme-*`.
- Never assign a dev work outside their stated scope without flagging it to the user.
- If a task produces or modifies functionality, check for matching `qa-*` agents and assign test creation/update as a follow-up.

**Dispatch phase output schema** — emit, for each `(root, role)` tuple the orchestrator dispatches to:

```yaml
fanout_hint:
  recommended_instances: <int>
  partition_basis: <"path-prefix" | "module" | "service" | "single">
  disjoint_groups: <int>
```

**`fanout_hint` calculation rule:**

- After `classify`, consider the touch set planned for a single `(root, role)`. Partition it into **disjoint touch groups** (non-overlapping file sets; use path-prefix or plan-supplied module/service boundaries when applicable). Let `disjoint_groups` be that count.
- If `disjoint_groups >= 2`: set `recommended_instances = min(disjoint_groups, 8)`. Set `partition_basis` to `"path-prefix"`, `"module"`, or `"service"` according to how those groups were formed.
- If `disjoint_groups < 2`: set `recommended_instances: 1`, `partition_basis: "single"`, and `disjoint_groups` to the actual count (0 or 1).

## Interpreting Names

- `tech-lead`: org-tier orchestrator; this checklist applies when `tech-lead` invokes project agents inside a workspace root.
- `dev-<scope>`:
  - Developer roles, scoped by layer/domain/concern.
  - Examples: `dev-frontend`, `dev-backend`, `dev-infra`, `dev-tests`.
- `sme-<domain>`:
  - Subject-matter experts for deep domains.
  - Examples: `sme-payments`, `sme-ml`, `sme-data`.
- `qa-<scope>`:
  - Quality-focused roles.
  - Examples: `qa-unit`, `qa-e2e`, `qa-manual`.
- `devops`:
  - CI/CD and infra-as-code roles when the project actually needs them.

## Low-Token, Minimal-Context Rules

- **Load only what you need**
  - When assigning or executing a task:
    - Read only the specific files and rules relevant to that task.
    - Avoid scanning the entire repo or loading all rules/skills at once.
- **Access memory directly, delegate docs research**
  - For persistent knowledge:
    - Access memory directly via the `context-memory` skill (read/write protocols in `memory-access` and `memory-capture` rules).
    - Query namespaces: `project.<name>`, `project.<name>.<domain>`, `org.global`.
  - For external documentation:
    - Ask `docs-researcher` rather than calling docs MCPs directly.
- **Keep delegation tight**
  - `tech-lead` passes each agent:
    - Only the relevant plan fragment.
    - Only the necessary file paths/snippets.
    - Only the constraints that matter for that agent’s scope.

## Parallel Work Safety

- Only run tasks in parallel when:
  - They are within the same phase.
  - They do not depend on each other’s outputs.
- For each parallel task:
  - Assign it to exactly one agent whose scope matches.
  - Ensure acceptance criteria are clear and verifiable.
- After parallel execution:
  - Aggregate results, run verification, and report back before moving to the next phase.
