---
name: parallel-dispatch
description: Three-level parallelism (phase group → phase-task → intra-role fan-out), parallelize-by-default stance, disjoint-touches pre-flight, merge/rollback for horizontal fan-out, failure semantics, and dynamic concurrency caps for orchestrators consuming a cto plan.
---

## Parallelize by Default

Every dispatchable unit runs in parallel unless a documented blocker applies. Default log field: `parallelism_decision: parallel`. When serializing, log **`parallelism_decision: serial+blocker:<reason>`** per dispatched unit.

The only recognized blockers (exhaustive list):

| ID | Blocker |
|----|---------|
| a | Same-file write conflict (detected by disjoint-touches pre-flight or post-edit verification). |
| b | Package-manifest contention or git-tracked file race in the same folder (serialize per folder when siblings both write it). |
| c | Sequential `depends_on` edge in the `cto` plan DAG (downstream cannot start until upstream completes). |
| d | Explicit user / plan `serial: true` flag on the affected unit or group. |

**R1 — plan graph is read-only for the consuming orchestrator. Any DAG mutation requires hand-back to `cto` with a `re_plan_brief`. Re-dispatch within an existing phase is allowed; mutating the DAG is not.**

## Level-1 Phase Group Fan-out

**Level 1 — fan-out across sibling phases in one parallel group.** Phases that share the same `depends_on` set form a group; dispatch every phase in that group as parallel `Task` calls in a single assistant turn when each is `parallelizable` and touches are disjoint per pre-flight.

**Per-group execution (topological order):**

1. Fan out every phase in the current group as parallel `Task` calls in one turn (Level-1 parallelism). A single-phase group is inherently serial.
2. Within each dispatched phase, the assignee may further parallelize at Level 2 per disjoint-touches rules.
3. Brief each phase/agent with steps, `touches` / `rollback_scope`, context, acceptance criteria — minimal briefs (no full plan dump).
4. Wait for **all** phases in the group; collect structured outputs; verify per-phase acceptance and that disjoint writes held at runtime.
5. Run sequential follow-ups inside the group only when the plan explicitly orders them inside that group.

**Example — phase-group fan-out (Level 1):**

```
CTO plan dependency graph:
G1: P1 → foundation
G2: P2a, P2b, P2c → all depend on [P1]; touches disjoint
G3: P3 → depends on [P2a, P2b, P2c]

Your execution:
→ Dispatch P1 (single phase, serial).
→ Await user checkpoint for G1.
→ Dispatch P2a, P2b, P2c as three parallel Task calls in one turn.
→ Await all three to complete; verify disjoint writes actually held.
→ Present group summary; await user checkpoint for G2.
→ Dispatch P3 (single phase, serial).
→ Await user checkpoint for G3 → plan complete.
```

After group execution: summarize per-phase work, parallelism vs lone dispatch, verification, failures, rollbacks if any — then **checkpoint** for explicit user approval before the next group (same semantics as orchestration rules).

## Level-2 Phase-Task Fan-out within Group

**Level 2 — task fan-out within a single phase.** Split steps into agent-scoped tasks (`dev-frontend`, `dev-backend`, `qa-unit`, etc.) and parallelize those whose `parallelizable` flag is true and whose file touches are disjoint; respect task-level `depends_on` ordering inside the phase.

**Example — task fan-out (Level 2, within one phase):**

```
Phase P2a tasks:

- dev-frontend: implement login UI (parallelizable: true, touches ui/**)
- dev-backend: implement auth API (parallelizable: true, touches api/**)
- qa-unit: write unit tests (depends on dev output — runs after)

Execution:
→ Dispatch dev-frontend + dev-backend in parallel.
→ Wait for both.
→ Dispatch qa-unit (dependent).
→ Verify phase.
```

**Do not parallelize** at Level 2 when: phases are not `parallelizable_with` each other per plan; siblings' `touches` intersect at runtime; tasks have write dependencies on the same files; steps are explicitly sequential; or tasks need shared mutable state.

## Level-3 Intra-Role Horizontal Fan-out

Given phase **P**, role **R**, and `touches[] = [t1..tk]`:

1. **Partition** into **N** disjoint groups with **longest-common-prefix segmentation** (greedy scan of sorted paths; grow each group while the common path prefix is stable; minimum group size **2** unless **k < 2N**, in which case degrade to **k** single-task instances — no fan-out).
2. **Fan-out only if** **N ≥ 2** disjoint groups and **N ≤ 8**. If below threshold, use a single instance. Hard cap: **max 8** instances per role per phase.
3. For each group **g_i** (**1 ≤ i ≤ N**): spawn an agent instance with **`instance_id = "<role>#<i>"`**, pass disjoint slice **`touches_i`**, collect **`diff_i`** and **`diff_hash_i`**.
4. **Merge:** union all **`diff_i`** into **`merged_diff`**. After edits, verify **∀ i,j (i≠j):** **`touches_i ∩ touches_j = ∅`** and **`files_modified_i ∩ files_modified_j = ∅`** (instances may touch files outside their slice — post-edit check is mandatory).
5. **Post-edit overlap:** rollback all **N** instances using each instance’s **`originating_diff`**, log **`[tech-lead] fanout_post_edit_overlap_rollback phase={p} instances={n}`**, then fall back to **single-instance sequential** for the phase slice.
6. Compute **`merged_diff_hash`** for downstream loops (e.g. merged-diff review).

## Disjoint-Touches Pre-flight

**Dispatch rules (Level 1 and Level 2):**

1. **Identify independent units** — different files/modules, no shared state; at Level 1, each unit’s `parallelizable_with` must include the sibling IDs you dispatch with.
2. **Check `parallelizable`** — only background-parallelize agents/tasks marked `parallelizable: true` where the plan allows it.
3. **Invoke in parallel** — parallel `Task` calls in one turn, or `run_in_background: true` for all but one as required by the host.
4. **Verify disjoint writes pre-dispatch** — for every pair of siblings, `touches` sets must not intersect; if they do, stop and escalate to `cto` (plan parallel-safety broken).
5. **Collect and confirm** — wait for all units in the group; confirm acceptance from agent reports or verification passes — not by editing or running implementation yourself.

**Build the execution DAG** from `## Phase Dependency Graph`: group phases by `depends_on`; cross-check each phase’s `parallelizable_with` matches its group’s sibling IDs; escalate if malformed.

**R8 — cross-folder:** Phases in a parallel group **MUST** share a single **`folder_root`**. Cross-folder phases in one parallel group are a **plan defect**; **halt and escalate to `cto`**. Within one folder, **serialize** any phase that touches package manifests or git-tracked files if a sibling also writes that same folder.

## Failure Semantics within a Group

**Collect-then-report:** For an approved parallel group, run **all** in-flight tasks to completion (or each task’s timeout) before `tech-lead` reports outcomes to the user. **Do not** surface partial failures mid-group.

**Per-instance failure (Level-3 fan-out):** Re-dispatch **only** the failed instance’s slice **alone** — **one** retry; if that fails, **escalate**. Keep the other **N−1** instances’ diffs in a **staging area** on disk until the retried instance returns, then proceed with merge.

**Legacy sibling-phase behavior (after group completes):** If one sibling phase fails and others succeed: roll back **only** the failed phase per its `rollback_scope`; report partial success; await user guidance before re-dispatching the failed phase — do not roll back successful siblings. If multiple siblings fail: roll back each independently; escalate with a combined summary. If failure shows `touches` were not actually disjoint: halt, roll back **all** siblings to be safe, escalate to `cto`.

## Concurrency Caps

- **Per-group concurrency** = count of **`parallelizable`** phases in the current `cto` plan group (**dynamic**). The **legacy fixed cap of 4 parallel phases per group is removed** — do not apply a hardcoded 4.
- **Per-phase intra-role fan-out:** **maximum 8** instances per role per phase (see Level-3).
- **Global safety net:** **12** concurrent in-flight `Task` calls per orchestrator session (across all groups and fan-outs).
- **Rate-limit backoff:** On **3 consecutive HTTP 429** (or equivalent rate-limit signals), **halve** effective concurrency for **60 seconds**, then reassess.
