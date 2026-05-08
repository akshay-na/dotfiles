---
name: n8n-builder-planning-gate
description: Standardizes how `n8n-builder` performs planning triage, specialist consultation, and produces an implementation-ready plan v0 ready for the mandatory CRO loop. Use when n8n-builder is in Stage A (planning).
version: 1
---

# n8n-builder Planning Gate

This skill defines the **planning contract** that `n8n-builder` follows in
Stage A. It produces the plan v0 artifact the [CRO loop runbook](../../docs/runbooks/n8n-builder-cro-loop.md)
expects on disk and the structure the [execution-gate skill](../n8n-builder-execution-gate/SKILL.md)
relies on at dispatch time.

## When to use

- The user has invoked `n8n-builder` (explicit entrypoint).
- The task carries an n8n signal (workflow, node, MCP, n8n-as-code).
- No plan v0 exists yet for the current `task_id`.

If a plan v0 already exists for the episode, do **not** re-run this skill —
either revise v0 in-place per user feedback (pre-CRO checkpoint) or proceed
to the CRO loop.

## Required plan structure

The plan file lives at
`<project>/.cursor/docs/plans/YYYY-MM-DD-n8n-<slug>.md` and MUST contain the
following sections in this order:

1. **Context** — one paragraph: what is changing in n8n and why.
2. **Problem Framing** — bulleted list of the constraints, conflicts, and
   unknowns that motivate the design.
3. **Scope** — bulleted list of files, workflow ids, environments, and node
   families in scope.
4. **Out of Scope** — bulleted list of explicit non-goals.
5. **Assumptions** — bulleted list. Each assumption is a falsifiable
   statement. Mark each as `verified` or `pending`.
6. **Mode and Environment** — declared mode (`as-code` / `mcp-live` /
   `hybrid`), env (`dev` / `staging` / `prod`), and the justification per
   `n8n-builder-mode-policy.yml` selection rules.
7. **Risks & Mitigations** — table:
   `| Risk | Impact | Mitigation | Owner |`
8. **Phase Dependency Graph** — table with columns:
   `| Group | Phase ID | Depends on | Parallel siblings | Touches (disjoint across siblings) | Mode |`
9. **Implementation Phases** — for each phase:
   - Metadata block (required):
     - `id:` short stable id (e.g. `P2a`)
     - `depends_on:` list of phase ids that must complete before
     - `parallelizable_with:` list of sibling phase ids
     - `touches:` bounded list of file globs and/or workflow ids
     - `rollback_scope:` files / artifacts reverted on rollback (subset of
       `touches`)
     - `mode:` one of `as-code`, `mcp-live`, `hybrid`
     - `env:` one of `dev`, `staging`, `prod`
     - `worker_cap:` integer ≤ mode cap (≤ 4 for mcp-live, ≤ 8 for as-code)
     - `destructive:` boolean; if true, list affected workflow ids
     - `requires_review:` boolean (true for as-code by default)
     - `requires_qa:` boolean (true for as-code by default)
   - **Goal** (1 sentence)
   - **Steps** (numbered, with `what / why / files / acceptance`)
   - **Verification** (specific commands or checks)
   - **Rollback** (specific reversal steps using `rollback_scope`)
10. **Verification Strategy (Cross-Phase)** — bulleted list.
11. **Rollback Strategy (Cross-Phase)** — bulleted list.
12. **Open Questions** — explicit user-facing questions that block planning.
13. **Open Risks** (auto-populated by CRO bookkeeping; may be empty at v0).
14. **Execution Gate (Post-Plan)** — declare the two-choice gate
    (`phase-by-phase` vs `all-phases-approved`) the user will choose **after**
    the CRO loop completes.

## Specialist consultation triggers

Invoke specialists in **parallel** via `Task`. Pass minimal briefs only;
never the entire plan dump. Use the `subagent-response-protocol` envelope.

| Trigger condition | Specialist |
|---|---|
| Workflow boundary, sub-workflow design, retry/idempotency at workflow level, integration contracts | `vp-architecture` |
| Credentials, webhook auth, allowlisted node review, untrusted input handling, secret references | `ciso` |
| Concurrency, queue depth, throughput, partial failure handling, per-node timeout strategy | `vp-engineering` |
| Logging, metrics, alerting, runbook integration, rollout / rollback strategy | `sre-lead` |
| As-code artifact maintainability, naming, sub-workflow abstraction, expression-node simplification | `staff-engineer` |
| Repeated patterns across workflows, template extraction, generators, reusable sub-workflows | `vp-platform` |
| n8n version specifics, node API specifics, vendor docs, MCP capability lookups | `vp-research` (always — only broker for external docs) |
| Existing Jira / Confluence / Bitbucket context referenced in the plan | `atlassian-pm` (read-only) |

Skip a specialist if its domain does not apply. Never invoke "for show".
Never lateral-call. Specialists may not call each other; they return findings
to `n8n-builder`.

## Output contract for plan v0

The handoff to the CRO loop is the markdown file. Additionally, `n8n-builder`
must return a structured handoff envelope (used internally by the CRO loop
runbook) containing:

```yaml
plan_handoff:
  plan_path: "<project>/.cursor/docs/plans/YYYY-MM-DD-n8n-<slug>.md"
  plan_hash: "<sha256 of plan markdown>"
  task_id: "<episode task id>"
  mode: as-code | mcp-live | hybrid
  env: dev | staging | prod
  affected_workflow_ids: [ ... ]
  node_family_set: [ ... ]
  credential_aliases: [ ... ]   # alias names only, never values
  specialist_bundle_refs:
    - agent: vp-architecture
      ref: "<ref id or path>"
    # ... etc
  open_questions: [ ... ]
  status: ready_for_user_v0_checkpoint
```

The handoff is structured data, not a free-form chat blob. Secret values are
forbidden; aliases only.

## Self-check (before persisting v0)

Validate before writing:

- [ ] Every phase has the full metadata block.
- [ ] `touches` sets are pairwise disjoint across `parallelizable_with`
      siblings.
- [ ] DAG is acyclic.
- [ ] Each phase declares `mode` and `env`.
- [ ] No phase mixes envs or modes; cross-env / cross-mode edits are split
      into separate phases.
- [ ] Destructive phases have `destructive: true` and list affected workflow
      ids.
- [ ] Reviewer + QA flags are true for every `as-code` phase.
- [ ] Worker caps respect the mode cap (≤ 4 mcp-live, ≤ 8 as-code).
- [ ] Plan path uses the correct date and naming convention.
- [ ] No secret values anywhere in the plan; references only.
- [ ] Plan ends with the two-choice execution gate stub (resolved after CRO).

## Pre-CRO user checkpoint

After persisting v0, surface the checkpoint exactly as defined in the CRO
runbook:

> Plan v0 written: `<plan_path>`. Reply `approve v0 for CRO` to start the
> CRO adversarial loop. Reply with feedback to revise v0 first.

Do not start CRO without explicit approval text.

## Cross-references

- [`n8n-builder` agent](../../agents/n8n-builder.md)
- [CRO runbook](../../docs/runbooks/n8n-builder-cro-loop.md)
- [Mode policy](../../configurations/n8n-builder-mode-policy.yml)
- [Worker contract](../../configurations/n8n-builder-worker-contract.yml)
- [Governance rule](../../rules/n8n-builder-governance.mdc)
- Org-tier [`cro-loop` skill](../cro-loop/SKILL.md)
- Org-tier [`subagent-response-protocol`](../../rules/subagent-response-protocol.mdc)
