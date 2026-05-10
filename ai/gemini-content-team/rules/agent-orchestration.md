# Content agent orchestration

Hard limits on **file tools**, **shell**, and **MCP** live in **`strict-tool-boundaries.md`** — read both when editing or dispatching.

**Terminology — Gemini CLI:** **`dispatch`** = invoke the target agent via the **Gemini CLI agent-delegation tool** registered for that agent (see **`mode-auto-selection.md`** — not Cursor IDE’s **`Task`** tool). Policy below is **identical** to Cursor packs; only the **mechanism** differs.

- **User-requested agent = real dispatch, not persona:** When the user explicitly asks to **use / invoke / run / call / dispatch** a named agent (colloquial “Task” counts), the assistant **must** **dispatch** that agent (see **`mode-auto-selection.md`**). **Never** substitute in-chat imitation of **`cco`**, **`content-lead`**, or specialist tone for a missing **delegation tool call**.

- **Dispatch-first contract (parent session — non-negotiable):** When **`mode-auto-selection.md`** says the user **invoked** an agent (including **delegate / assign / hand off / orchestrate with** patterns), the **parent** **must** emit the **delegation tool call** for that agent **before** any **mutating** file or git operation on the corpus for that request. **Violations** are **routing failures** — **stop**, **admit the miss**, **dispatch** the named agent with the original brief. **Entrypoints** never get parent-session **substitute execution**.

- **Subagent orchestration — zero-gap (hard):** A **hop** = one completed **dispatch** (or explicit protocol **`malformed`/`degraded`** stub) before the parent claims that agent’s work. **No gap** means: (1) every slice attributed to **`cco`**, **`content-lead`**, **`sme-*`**, **CVO**, **`vp-research`**, etc. was produced by that agent’s **dispatch** (parent may **merge** only per **`subagent-response-protocol.md`** — **no** new copy, claims, or paths); (2) **no** parent turn interleaves corpus **writes** with **pending** child work on the same atoms; (3) **`cco`** / **`content-lead`** **never** impersonate **`editorial-cro`** or internal personas — **dispatch** or block; (4) parallel dispatches = **disjoint `touches[]`** only; overlap → **stop**, redispatch. **Impersonation** of a child = **always** a violation.

## Entrypoints

- **`cco`** — plan mode; writes `<project>/.gemini/docs/plans/*.md` (content work repo — not dotfiles pack paths); may parallel-invoke content specialists; runs **`editorial-cro-loop`** once after plan v0; may **dispatch** **`chief-visual-officer`** when visual deliverables are in scope; may **dispatch** **`video-editor`** for programmatic-video planning; **`remotion-builder`** execution is **Cursor-only** in v1 — surface **`video-editor-handoff`** payload for the user or invoke **`remotion-builder`** in Cursor only when the user explicitly asks **`cco`** to do so; may **dispatch** **`chief-profile-metrics`** / **`chief-growth-strategy`** when the plan names browser profile capture or growth intelligence phases.
- **`content-lead`** — execution; discovers `{root}/.gemini/agents/` via **`content-team-discovery`**, **and** registers org singleton **`chief-visual-officer`** when **`chief-visual-handoff`** applies; when **`approved_plan_path`** names a programmatic-video phase, satisfy **`video-editor-handoff`** and hand off to **`remotion-builder`** in **Cursor**; runs **`generate-content-pipeline`** stages, **`content-git-workflow`** when policy says push; may **dispatch** **`chief-profile-metrics`** / **`chief-growth-strategy`** when the approved plan’s phase lists them.

## Org singleton: `chief-visual-officer` (CVO)

- **Location:** **`~/.gemini/agents/chief-visual-officer.md`** when this pack is stowed — **do not** duplicate the role in `<project>/.gemini/agents/`.
- **Callers:** **`cco`**, **`content-lead`**, org **`vp-*`**, **`cpo`**, **`staff-editor`**, **`editorial-ops-lead`**, and **project** SMEs — all may **dispatch** CVO with a payload meeting [**`chief-visual-handoff`**](../skills/chief-visual-handoff/SKILL.md). This is **not** a lateral project→`vp-*` violation; CVO is the designated visual execution agent.
- **Model:** **`composer-2`**, pinned in CVO frontmatter.

## No Atlassian / no org QA

- **`atlassian-pm`** is **not** part of this pack.  
- No org-tier **`qa-*`**; human reviews after automation; optional plan-only critic is **`editorial-cro`**.

## Subagent protocol

Child **dispatch** returns: **`subagent-response-protocol.md`** + YAML envelope per inject hook. Parent parse contract same as org standard.

## Execution approval

- **Interactive:** explicit checkpoint wording per phase (silence ≠ approval).  
- **Automation (`execution_mode: automation`):** no chat gates; **`content-git-workflow`** + n8n payloads per **`orchestration.md`**.

## Escalation

- Project agents → **`cco`** for replanning (no lateral org dispatch chains from project tier **to `vp-*` / `cpo` / `staff-editor`** for new strategy).
- **Exception:** project agents **may** **dispatch** org **`chief-visual-officer`** for visual execution when **`chief-visual-handoff`** preconditions are met (same as **`content-lead`**).
- **`editorial-cro`** findings with `bounce_target` → only **`cco`** issues specialist dispatches.

## Brain

Canonical data: `~/.gemini/ai-brain/` (see **`brain-conventions.md`**). Both tech and content packs may share this **data** path when switched; rules are not merged.

## Docs

Plans/decisions under **`<project>/.gemini/docs/`** per **`docs-and-decisions.md`** (`<project>` = content corpus git root, not org-pack-only trees).

## Agent responsibility matrix (hard boundaries)

| Tier | Owns | Must **not** |
|------|------|--------------|
| **`cco`** | Plans under `<project>/.gemini/docs/plans/`; planning swarm **dispatches**; one **`editorial-cro-loop`** after plan v0; **dispatch** **CVO** when visuals are in plan scope | Execute routine corpus edits unless the brief explicitly names **`cco`** as executor; skip **`editorial-cro`** critic gate; invent dispatch targets outside plan/skill allowlists |
| **`content-lead`** | **`content-team-discovery`**, pipeline stages (**`generate-content-pipeline`**), **`content-git-workflow`** when policy allows; register **CVO** when **`chief-visual-handoff`** applies | Author net-new **CCO** plans (that is **`cco`**); **dispatch** org **`vp-*`** for fresh strategy without **`cco`** context; push without idempotency / payload checks per **`orchestration.md`** |
| **Org specialists** (`vp-*`, **`staff-editor`**, **`cpo`**, **`editorial-ops-lead`**, etc.) | Their slice inside a **`cco`** swarm or explicit user/org invoke | Peer-to-peer dispatch chains with each other without **`cco`** (or stated parent) orchestration; write arbitrary `<project>` paths outside plan **`touches[]`** / role scope |
| **Project agents** (per-repo `sme-*`, `reviewer-*`) | Paths and gates defined in **that** repo’s rules | **dispatch** **`cco`** / **`content-lead`** / **`vp-*`** for new strategy mid-task; redefine **CVO** locally |
| **`chief-visual-officer`** (**CVO**) | Raster and asset paths per **`chief-visual-handoff`** | Claim ownership of copy, legal, metrics ingestion, or non-visual corpus strategy |
| **`chief-profile-metrics`** | Browser-assisted **profile** / surface metrics when **no API**; **`metrics/`** files matching **`metric-event.schema.json`**; **`<project>`** git sync per **`content-git-workflow`** + **`--no-gpg-sign`** | Generic web fetch; credentials; post-level API pipelines owned by **`sme-channel-growth`**; **`curl`** to analytics endpoints without runbook |
| **`chief-growth-strategy`** | Growth intel, creator benchmarks, experiment backlogs; **dispatch** **`vp-research`** for all off-corpus facts; durable notes under **`~/ai-brain/`**; optional **`<project>`** staging/ideas + git when user/plan asks | Direct HTTP/docs MCP calls; promise growth outcomes; lateral dispatch to project **`sme-*`** without **`cco`** / **`content-lead`** plan |
| **`video-editor`** | Programmatic video briefs; **`video-editor-handoff`** payload for Cursor | **dispatch `remotion-builder`** from Gemini CLI (v1: execution is Cursor-only); skip handoff payload |
| **`remotion-builder`** | **Cursor tech singleton** (`~/.cursor/agents/remotion-builder.md`) — Remotion + Skia + ffmpeg | Invoked by project **`sme-*`**; treated as if it were a Gemini-local agent without Cursor |
| **`editorial-cro`** | Structured critique; **`bounce_target`** suggestions | **Specialist dispatch** as **`editorial-cro`** (**`cco`** alone runs **`bounce_target`** follow-ups) |

## Tool and integration boundaries

Execution details for **file tools**, **terminal**, and **subagent dispatch**: **`strict-tool-boundaries.md`** (read together with this section).

- **HTTP, web fetch, search, docs MCP:** **only** **`vp-research`** — **`vp-research.md`**. All other agents delegate through **`cco`** (planning) or user-invoked **`vp-research`**; no side-door fetch for “just checking the platform.”
- **Atlassian:** **not** in this pack — **no** `plugin-atlassian-atlassian` writes; treat missing tooling as out-of-scope.
- **Brain / memory:** **`brain-conventions.md`** only; **no** secrets in writes; bounded fields per skill.
- **Dispatch:** subagents obey **`subagent-response-protocol.md`**; parents **must not** dispatch agents absent from routing table / plan / this rule’s allowlists.
- **Shell:** prefer **`content-git-workflow`** for pull/commit/push; **no** destructive git (**`--force`**, **`reset --hard`**) unless user explicitly orders; **no** ad-hoc **`curl`** / **`wget`** to third-party editorial or analytics endpoints unless a **skill or runbook** authorizes that integration.

## Violations

- On boundary breach (wrong **dispatch target**, direct web from non-**`vp-research`**, writes outside **`touches[]`**): **stop**, report briefly, and let user or **`cco`** correct course — **do not** silently continue.
