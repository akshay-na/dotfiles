---
name: remotion-builder-execution-gate
description: Standardizes how `remotion-builder` runs Stage C (implementation) after tech CRO approval — remotion CLI, browser ensure, Skia smoke, ffmpeg from approved recipes, group checkpoints.
version: 1
---

# remotion-builder Execution Gate

**Stage C** for **`remotion-builder`**. Invoked only after tech CRO **`approved`** (v2 on disk) or recorded **`degraded_skip`** under **`## Open Risks`**.

## Entry requirements (hard)

1. Plan v2 path valid (or documented override).
2. User chose **`phase-by-phase`** or **`all-phases-approved`** with explicit authorization.
3. **Render mode** allowed by **`remotion-builder-mode-policy.yml`**.
4. **ffmpeg** steps (if any) reference only **recipe id** or **checked-in** script from the plan — no paste-through of untrusted filter strings.
5. **Destructive** phases (e.g. overwrite **published** **`assets/`**) have **named** approvals per governance.

## Execution lifecycle

### 1. Environment

- **`npx remotion browser ensure`** (or documented non-interactive equivalent) when the plan requires; **`CI=true`** where vendor docs recommend.
- **`LoadSkia()`** before **`registerRoot`** in entry — verify ordering matches plan.
- Optional **`--gl`** / env per plan and target host.

### 2. Render

- **`npx remotion`** / **`npm run`** targets exactly as declared in the phase.
- **Smoke:** one frame or short composition list; fail-closed on Skia init errors.

### 3. ffmpeg

- Run only wrappers/recipes named in the plan; **`ffmpeg -version`** smoke when first used in episode.
- **No** ad hoc **`-filter_complex`** from user chat unless governance approval recorded.

### 4. Checkpoints

- **`phase-by-phase`:** stop after each parallel group; wait **`proceed`**.
- **`all-phases-approved`:** continue groups; **destructive** still needs per-action named approval.

### 5. Completion

- Request explicit completion phrase per **`remotion-builder-governance.mdc`**.
- Emit **`agent-observability`** metrics (render duration, bytes out, outcome).

## Failure semantics

- **Suspected secret in tool output:** halt; **`subagent-response-protocol`** incident path.
- **CRO incomplete:** **`blocked_invalid_entry`** — no dispatch.

## Cross-references

- [`remotion-builder` agent](../../agents/remotion-builder.md)
- [Planning gate](../remotion-builder-planning-gate/SKILL.md)
- [Mode policy](../../configurations/remotion-builder-mode-policy.yml)
- [QA policy](../../configurations/remotion-builder-qa-policy.yml)
- [Governance](../../rules/remotion-builder-governance.mdc)
- [`parallel-dispatch`](../parallel-dispatch/SKILL.md)
