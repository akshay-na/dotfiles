---
name: remotion-builder-planning-gate
description: Standardizes how `remotion-builder` performs planning triage, specialist consultation, and produces plan v0; mandatory tech `cro-loop` at execution intent before Stage C. Use when remotion-builder is in Stage A (planning).
version: 1
---

# remotion-builder Planning Gate

Planning contract for **`remotion-builder`** Stage A. Plan v0 feeds the [CRO runbook](../../docs/runbooks/remotion-builder-cro-loop.md) and the [execution-gate skill](../remotion-builder-execution-gate/SKILL.md).

**Renderer reality (one line):** Skia runs as WASM **inside** Chrome Headless Shell for default SSR — not a Chromium-free server path unless **`vp-research`** validates an alternative and the plan says so.

## When to use

- User invoked **`remotion-builder`** or content handoff authorizes the episode.
- Remotion/Skia/ffmpeg signals present; corpus root known.

## Required plan structure

**Prefer** path **`<project>/.opencode/docs/plans/YYYY-MM-DD-remotion-<slug>.md`**; **prompt-only** v0 is valid when disk is unavailable — **`cro-loop`** still runs at execution intent (stable plan body in `Task` payload).

1. **Context** — what render/pipeline changes and why.
2. **Problem Framing** — constraints, unknowns.
3. **Scope** — corpus paths, compositions, asset outputs.
4. **Out of Scope** — explicit non-goals.
5. **Assumptions** — `verified` / `pending`.
6. **Remotion project** — root path (e.g. **`tools/remotion/`** in content-foundry), **Skia enabled** (yes/no), **`LoadSkia()`** / entry file, **pinned** `remotion`, `@remotion/skia`, `@shopify/react-native-skia` (exact versions).
7. **Entry composition** — id, props, duration.
8. **Render mode** — `ssr_headless_shell` (default) vs `experimental_csr` (needs explicit user sign-off in plan).
9. **Chromium / GL posture** — local vs CI, **`--gl`** / vendor flags if any.
10. **Output** — codec, resolution, **`assets/<channel>/`** paths (prefer **`assets/video/`** for encoded MP4 unless plan picks **`assets/instagram/`** for Reels-only).
11. **ffmpeg post-flight** — `none` | `remux` | `transcode` | `audio_mux` with **recipe id** or checked-in argv template; platform target (e.g. Reels).
12. **Font / asset credentials** — env var names only; no secret values.
13. **Risks & Mitigations** — table.
14. **Phase Dependency Graph** — disjoint **`touches`** across parallel siblings.
15. **Implementation Phases** — metadata: `id`, `depends_on`, `parallelizable_with`, `touches`, `rollback_scope`, `destructive`, `verification`, `rollback`.
16. **Verification Strategy** / **Rollback Strategy**.
17. **Open Questions** / **Open Risks** (CRO bookkeeping).
18. **Execution Gate (Post-Plan)** — `phase-by-phase` vs `all-phases-approved` after CRO (CRO runs when user signals implementation).

## Specialist consultation triggers

| Trigger | Specialist |
|--------|------------|
| Repo/composition boundaries | `vp-architecture` |
| Secrets, filter injection, supply chain | `ciso` |
| Render throughput, retries | `vp-engineering` |
| Disk, cache, observability | `sre-lead` |
| TS maintainability | `staff-engineer` |
| Templates / repeated renders | `vp-platform` |
| Vendor docs, version bumps | `vp-research` (always for external docs) |

## Post–v0 edit round

After v0: ask **once** whether to add/remove/change anything; revise until satisfied. **No** `approve v0 for CRO` phrase. When the user signals **implement / execute / proceed with implementation**, run **`cro-loop`** immediately (see [`remotion-builder` agent](../../agents/remotion-builder.md) Stage B).

## Cross-references

- [`remotion-builder` agent](../../agents/remotion-builder.md)
- [CRO runbook](../../docs/runbooks/remotion-builder-cro-loop.md)
- [Mode policy](../../configurations/remotion-builder-mode-policy.yml)
- [QA policy](../../configurations/remotion-builder-qa-policy.yml)
- [Governance](../../rules/remotion-builder-governance.md)
- [`cro-loop`](../cro-loop/SKILL.md)
