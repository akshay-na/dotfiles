---
name: n8n-builder-execution-gate
description: Standardizes how `n8n-builder` enters and runs Stage C (implementation) with worker fan-out, group checkpoints, and gated progression. Use when n8n-builder transitions from CRO `approved`/`degraded_skip` to execution.
version: 1
---

# n8n-builder Execution Gate

This skill defines the **execution contract** for Stage C of `n8n-builder`.
It is invoked only after the CRO loop has reached `approved` (v2 on disk) or
`degraded_skip` (explicit user override recorded in the plan).

## Entry requirements (hard)

The execution-gate skill MUST refuse to start unless **all** of the following
hold:

1. Plan v2 exists on disk at the path returned by the planning-gate handoff
   (or v0 if `degraded_skip` and recorded under `## Open Risks`).
2. CRO state is `approved` OR `degraded_skip`.
3. The user has selected the execution mode with explicit text:
   - `phase-by-phase` (group-by-group checkpoints), or
   - `all-phases-approved` + an authorization line indicating they accept
     auto-progression across groups.
4. The plan declares `mode` and `env` for every phase, and the mode policy
   matrix accepts the declarations (per
   `n8n-builder-mode-policy.yml`).
5. Every destructive phase has its named per-action approval already on
   record OR the execution gate must stop and request it before dispatching
   that phase.
6. The worker contract preflight (per `n8n-builder-worker-contract.yml`)
   passes for every phase that intends to fan out.

If any check fails, transition to `blocked` and surface a blocker report.
Do not improvise.

## Execution lifecycle

### 1. Pre-dispatch validation (per phase)

For each phase about to be dispatched:

- Validate `mode`, `env`, `touches`, `rollback_scope`, `worker_cap`,
  `destructive`, `requires_review`, `requires_qa`.
- Run worker-contract preflight if shard count ≥ 2:
  - `declare_partition_basis`,
  - `disjoint_touches`,
  - `side_effect_dependencies`,
  - `idempotency_classification`,
  - `env_consistency`,
  - `destructive_pre_approval`.
- If shard count is 1, skip fan-out and run the phase as a single owner.

### 2. Dispatch

- **Per-group concurrency:** dispatch all `parallelizable_with` siblings in a
  single assistant turn via parallel `Task` calls. Cap dynamic; never exceed
  `global_concurrent_task_cap: 12`.
- **Per-phase fan-out:** within a phase, dispatch up to `worker_cap` worker
  subagents (≤ 4 in `mcp-live`, ≤ 8 in `as-code`) on disjoint partitions.
- Each worker receives:
  - the phase metadata,
  - its disjoint slice (`touches_i`),
  - an `idempotent: true|false` flag,
  - the credential alias for the active environment (alias only, never the
    secret value),
  - the artifact-write convention to use,
  - the rollback strategy stub (so it can produce a `rollback_ref`).
- Worker outputs follow the worker contract shard schema.

### 3. Merge

- Order shards by stable `(phase_id, shard_id)` lex key.
- Verify post-edit disjointness: no shard wrote outside its declared
  `touches` slice; no two shards modified the same file/workflow id.
- Aggregate to `merged_diff` with `merged_diff_hash`.
- On disjoint violation: roll back the entire group using each shard's
  `rollback_ref`, log
  `[n8n-builder] fanout_post_edit_overlap_rollback phase=<pid>
  shards=<n>`, and fall back to single-instance sequential dispatch.

### 4. Mode-specific completion (Stage D handoff)

- `as-code` (or hybrid code-side):
  - Invoke `code-reviewer` (mandatory). Wait for review envelope.
  - Run QA per `n8n-builder-qa-policy.yml` (mandatory minimum verification
    set: schema check, workflow validation, regression checks).
  - If reviewer or QA fail: enter the as-code rework loop per the
    [as-code reviewer/QA runbook](../../docs/runbooks/n8n-builder-as-code-review-qa.md).
- `mcp-live` (or hybrid live-side):
  - Capture pre/post snapshots of affected workflow ids.
  - Append audit row to
    `~/ai-brain/org/global/orchestration/n8n-builder-audit.md`.
  - Smoke trigger only on non-prod envs unless plan explicitly authorizes
    a prod smoke test.
  - Capture-back to as-code if both surfaces exist.

### 5. Per-group checkpoint

- If `execution_mode: phase-by-phase`:
  - Surface a concise per-group summary (parallelism applied, fan-out used,
    outcomes, audit row refs, open risks).
  - Stop. Wait for `proceed` or feedback.
- If `execution_mode: all-phases-approved`:
  - Print the same summary inline.
  - Continue to the next group automatically.
  - Even under `all-phases-approved`, destructive actions still require a
    named per-action approval per the governance rule.

### 6. Final completion

- Run Stage E from the agent: collect plan, mode, ledger, audit refs;
  request explicit `mark this n8n-builder run complete` before declaring
  the run finished.

## Failure semantics

- **Per-shard:** retry once if `idempotent: true`; otherwise escalate.
- **Per-phase (siblings within a group):** if one sibling fails and others
  succeed, roll back only the failed sibling per its `rollback_scope`;
  report partial success; await user guidance before re-dispatch.
- **Audit failure (`mcp-live`):** hard fail. Halt the phase and request
  user guidance. Do not proceed without an audit row.
- **Suspected secret leak in any envelope:** rewrite envelope to
  `status: malformed` with
  `degraded_reason: "suspected_secret_in_output"`; halt the phase; record
  incident.

## Blocked-state handling

- `blocked_invalid_entry`: missing CRO approval or missing user mode choice.
  Action: surface required remediation; do not dispatch.
- `blocked_preflight`: worker preflight rejected. Action: revise plan or
  collapse fan-out; do not improvise.
- `blocked_destructive_no_approval`: destructive phase without named
  approval. Action: ask for the named approval phrase per
  `n8n-builder-governance.mdc`.
- `blocked_audit`: audit append failed. Action: investigate sink; do not
  silently retry.

## Observability

- `log_metric` stages:
  - `n8n_builder.exec.group.<gid>` — `phases_planned`, `phases_dispatched`,
    `phases_succeeded`, `phases_failed`, `group_duration_ms`.
  - `n8n_builder.exec.shard.<phase>.<shard>` — `duration_ms`, `retried`,
    `mode`, `env`.
- `log_decision` rows for every per-phase rollback, fan-out collapse,
  destructive approval received, and override use.

## Self-check (before each group dispatch)

- [ ] Entry conditions hold.
- [ ] All siblings' `touches` disjoint pre-flight.
- [ ] All destructive actions in this group have named approvals.
- [ ] Worker cap and global cap not exceeded.
- [ ] All credentials referenced by the group are alias-only, env-matched.
- [ ] Audit sink writable (test write of a no-op canary line; revert).

## Cross-references

- [`n8n-builder` agent](../../agents/n8n-builder.md)
- [Planning-gate skill](../n8n-builder-planning-gate/SKILL.md)
- [Worker contract](../../configurations/n8n-builder-worker-contract.yml)
- [Mode policy](../../configurations/n8n-builder-mode-policy.yml)
- [Governance rule](../../rules/n8n-builder-governance.mdc)
- [QA policy](../../configurations/n8n-builder-qa-policy.yml)
- [Operations runbook](../../docs/runbooks/n8n-builder-operations.md)
- [As-code reviewer/QA runbook](../../docs/runbooks/n8n-builder-as-code-review-qa.md)
- Org-tier [`parallel-dispatch`](../parallel-dispatch/SKILL.md)
- Org-tier [`subagent-response-protocol`](../../rules/subagent-response-protocol.mdc)
