# ADR-001: Tech-Lead Promotion to Org-Tier

## Status: accepted

## Context

The project-tier `tech-lead` orchestrator lived as an approximately one-thousand-line template embedded in [`vp-onboarding.md`](../../agents/vp-onboarding.md): each onboarding run duplicated that body into `<workspace>/.cursor/agents/tech-lead.md`, spreading identical logic across projects. Multi-folder Cursor workspaces lacked a single first-class execution entrypoint that could coordinate work across disjoint roots. Promoting execution ownership to org tier intersects routing where `senior-dev` remains the default direct implementer doc-wise, producing a precedence ambiguity between “call `senior-dev`” and “everything goes through `tech-lead`” unless boundaries are tightened.

Specialist consultation (abbreviated citations only):

- **vp-architecture:** R3, R7, R10, R16
- **vp-engineering:** R4, R5
- **vp-platform:** R4, R7
- **staff-engineer:** R3, R5
- **sre-lead:** R11, R15

## Decision

`tech-lead` is promoted to an org-tier singleton (stowed via the dotfiles `cursor/` package). Planning still starts under `cto`; review still starts under `code-reviewer`; **`tech-lead` is the org execution entrypoint** for routed multi-agent implementation. Invariants binding the design:

**(a)** The plan graph (phases from `cto` or equivalent) is **read-only** to `tech-lead` — it executes and coordinates, never rewrites canonical plan topology.

**(b)** **Single-owner-per-target review:** in-flight implementation-review loops belong to `tech-lead`; end-of-phase / cross-cutting review stays with `code-reviewer` where policy says.

**(c)** Cross-folder work is **sequenced by default** (no silent parallel splits across workspace roots unless an explicit carve-out permits it).

**(d)** Any automatic specialist escalation paths are **normalized through `code-reviewer`** — one gate before specialist fan-out — and that auto-escalation path stays **default OFF**.

## Alternatives Considered

**Alt 1 — Stay project-tier; dedupe only via shared skill.**

Reject. Template deduplication trims bytes but leaves every workspace reinventing invocation paths, does **not** make multi-folder orchestration first-class, and fails to collapse the **`senior-dev` vs `tech-lead` precedence** collision surfaced after promotion concepts land.

**Alt 2 — Promote to org-tier and auto-invoke `code-reviewer` / specialists on every heuristic trigger.**

Reject per **vp-architecture R2** and **vp-engineering R4**: duplicates `code-reviewer`’s triage role, explodes parallel Task cost, weakens audit boundaries, and churns duplicate specialist passes.

**Alt 3 — Promote behind a routing-table feature flag for demotion.**

Reject per **vp-architecture R14** for this repo: Git history plus `git revert` already gives a single-user rollback story; dragging permanent dead branching through `vp-onboarding.md` is worse than reversing commits.

## Trade-offs

Accepted trade-offs:

1. **Loss of bespoke text in project-scoped `tech-lead.md` bodies.** Mitigations: typed runtime team discovery stays in-repo; vp-onboarding’s legacy cleanup backs up deleted project copies before removal.

2. **Shadow window:** `<workspace>/.cursor/agents/tech-lead.md` can override `~/.cursor/agents/tech-lead.md` until onboarding cleanup deletes the legacy clone. Mitigations: phased rollout ordering in the wider plan plus startup self-check warnings in the agent body.

3. **Single gate through `code-reviewer` caps review parallelism.** Accepted for predictable spend, clearer RACI between implementation (`tech-lead`) and authoritative review aggregation (`code-reviewer`).

## Consequences

- **Plan mode** entry remains **`cto`**. **Review** entry remains **`code-reviewer`**. **Implementation orchestration** now names **`tech-lead`** at org tier while **`senior-dev`** stays the default when a user invokes a single implementer directly without project routing needs.
- **Project-local agents** — `dev-*`, `reviewer-*`, `sme-*`, `qa-*`, `devops` — continue to materialize **per repository** via `vp-onboarding`; org tier does **not** replace typed IC / SME / QA roles.
- **Multi-folder workspaces** are first-class: sequencing semantics and orchestration spans roots by default unless policy opts out.
- **Observability** extends with **eight new `decision_type` values** and **eleven structured logging fields** so routing, fan-out, fallbacks, and gate decisions remain inspectable (exact enums live beside the rolling agent-observability schema).
- **SLO stubs** (`slos.md`) and **cleanup audit logs** (`cleanup-log.md` entries appended during onboarding cleanup) join the permanent artifact set tying operational posture to migrations.

## References

- [Implementation plan (workspace root)](../../../../.cursor/docs/plans/2026-04-30-tech-lead-org-promotion.md) — same path as `~/dotfiles/.cursor/docs/plans/2026-04-30-tech-lead-org-promotion.md` when the repo root is `~/dotfiles`; not under the stowed `cursor/` package.
- [`agent-orchestration.mdc`](../../rules/agent-orchestration.mdc)
- [`vp-onboarding.md`](../../agents/vp-onboarding.md)
- [`tech-lead.md`](../../agents/tech-lead.md)

Specialist briefs (2026-04-30; transcripts not inlined): [`vp-architecture`](../../agents/vp-architecture.md), [`vp-engineering`](../../agents/vp-engineering.md), [`vp-platform`](../../agents/vp-platform.md), [`staff-engineer`](../../agents/staff-engineer.md), [`sre-lead`](../../agents/sre-lead.md).
