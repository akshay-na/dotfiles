# remotion-builder — tech CRO loop runbook

Singleton adversarial loop for **Remotion + Skia + ffmpeg** plans authored by **`remotion-builder`**. **Editorial** plans from **`cco`** use **`editorial-cro-loop`** instead — do not mix critics on the wrong artifact.

## Preconditions

- Plan v0 exists at **`<project>/.cursor/docs/plans/YYYY-MM-DD-remotion-<slug>.md`**.
- User sent explicit approval to start CRO (see **`remotion-builder-planning-gate`**).
- **`remotion-builder`** is the **only** patcher for this plan file; **`cro`** does not write disk.

## Ledger

- Path: **`~/ai-brain/session/<task-id>/critic-ledger.md`** (or **`cursor-<task-id>`** prefix per active **`brain-conventions`** session layout).
- Append pass, finding ids, freeze state, bounces, **`degraded`** skips.

## Loop (two passes)

1. Invoke **`cro-loop`** once as a **singleton** for the episode (pass 1 → **`remotion-builder`** revises plan to v1 → pass 2 → v2).
2. **`cro`** returns **`subagent-response-protocol`** YAML envelope only; **`remotion-builder`** merges findings and edits the plan.
3. **Fail-closed:** missing pass 2, malformed envelope after one reformat retry, or **`blocked`** → no execution gate; no **`all-phases-approved`** surface.
4. **Override:** user phrase **`skip CRO loop for this plan`** recorded under plan **`## Open Risks`**.

## Post-loop

- Present execution mode choice: **`phase-by-phase`** vs **`all-phases-approved`**.
- Silence ≠ approval.

## Cross-references

- Org **`cro-loop`** skill: `ai/cursor/tech-team/skills/cro-loop/SKILL.md`
- Planning gate: `ai/cursor/tech-team/skills/remotion-builder-planning-gate/SKILL.md`
- Execution gate: `ai/cursor/tech-team/skills/remotion-builder-execution-gate/SKILL.md`
- Governance: `ai/cursor/tech-team/rules/remotion-builder-governance.mdc`
- **`subagent-response-protocol`**: `~/.cursor/rules/subagent-response-protocol.mdc`
