# Remotion + Skia programmatic video — cross-pack orchestration

## Context

DotMate currently separates **Cursor tech pack** (planning/execution agents such as `cto`, `tech-lead`, `n8n-builder`) from **Cursor/Gemini content packs** (`cco`, `content-lead`, CVO, editorial-cro). **Programmatic video** via **Remotion** with **Skia-backed compositions** (`@remotion/skia` + `@shopify/react-native-skia`) is engineering-heavy (TypeScript project, WASM/Skia bootstrap, CLI render, **Chrome Headless Shell** for standard SSR, dependency installs, optional CI) but often triggered from **content workflows** (Reels, explainers, corpus-linked renders). This plan introduces **`remotion-builder`**: an **org-level, user-invoked, all-in-one** tech entrypoint (pattern-aligned with `n8n-builder`), wires **content org** orchestration so **`cco`**, the **user**, and **plan-gated `content-lead`** may hand off to it—**never** project `sme-*` directly—mirrors the same **CVO / `chief-visual-handoff`** precedent, and extends **Gemini content pack** docs/rules/skills for parity. **Source of truth for Remotion composition code** lives in the **content corpus repo** (e.g. `content-foundry`) under paths allowed by **`_schema/path-conventions.md`** (prefer **no new top-level dir**); **rendered binaries** land under **`assets/<channel>/`** with schema/registry hygiene.

## Remotion + Skia stack (renderer reality — plan invariant)

**Composition (Skia):** Canonical graphics path for new work is **Remotion Skia**: packages **`@remotion/skia`** and **`@shopify/react-native-skia`**, **`enableSkia`** / Webpack override in `remotion.config.ts`, **`LoadSkia()`** before `registerRoot`, compositions using **`<SkiaCanvas>`** per [Remotion Skia docs](https://www.remotion.dev/docs/skia). Pin **`remotion`**, **`@remotion/*`**, and **`@remotion/skia`** to the **same version** (avoid carets that drift).

**SSR / CLI (Chromium):** Per vendor docs, **Skia does not replace Chromium** for normal **`npx remotion`** / server renders: React Native Skia runs as **WebAssembly inside the same Headless Chrome / Chrome Headless Shell** Remotion already uses. So **“without Chrome”** in the sense of *no full desktop browser UI* is satisfied by **headless** operation; **“without any Chromium-class binary on the machine”** is **not** the default supported path. The documented alternative for non-Node SSR is **experimental** [**client-side rendering**](https://www.remotion.dev/docs/client-side-rendering) (`@remotion/web-renderer`, WebCodecs) which still runs in a **real browser** client-side—not a Skia-native offline renderer.

**Plan consequence:** **`remotion-builder`** plans and **`remotion-builder-governance.mdc`** must **not** promise a Chromium-free server pipeline unless **`vp-research`** confirms a new upstream option and the plan is revised. Default assumption: **Headless Shell** + **Skia WASM** + optional **`--gl`** / [`gl` options](https://www.remotion.dev/docs/gl-options) for CI (e.g. `swangle` on Lambda, `angle` caveats on GitHub Actions). **`remotion browser ensure`** / Linux deps per [chrome-headless-shell](https://www.remotion.dev/docs/miscellaneous/chrome-headless-shell) and [Linux dependencies](https://www.remotion.dev/docs/miscellaneous/linux-dependencies).

**Homelab runner:** Nightly/automation paths that use **`n8n-runner`** on the home-server stack should get the same toolchain during **Ansible user bootstrap** (`ansible_user_setup` role) so renders do not depend on manual `apt` / `npm` / browser downloads on the VM.

**ffmpeg:** After (or alongside) Remotion’s encoded output, the pipeline may **remux, transcode, resize, or lay in audio** with **ffmpeg** (platform targets, bitrate caps, silent-safe previews). **`remotion-builder`** owns **when** ffmpeg runs, **documented** filter graphs, and **no** secret-bearing CLI args in logs. **High-risk:** arbitrary user-supplied filter strings — governance must gate.

## Content org name vs tech pack name (invariant)

| Surface | Agent / skill | Role |
|--------|----------------|------|
| **Cursor tech pack** (`ai/cursor-tech-team`) | **`remotion-builder`** (`~/.cursor/agents/remotion-builder.md`) | Single **implementation** entrypoint: Remotion + Skia + **ffmpeg** post-steps, plans under `<project>/.cursor/docs/plans/YYYY-MM-DD-remotion-*.md`, tech **`cro-loop`**. |
| **Content Cursor + Gemini packs** | **`video-editor`** (`ai/cursor-content-team/agents/video-editor.md` + Gemini twin) | **Editorial / orchestration** name: CCO diagrams, user invoke “use **video-editor**”, briefs, phases. Does **not** replace tech agent on disk in tech pack. |
| **Content handoff skill** | **`video-editor-handoff`** | Same contract as prior `remotion-builder-handoff` design; payload still ends in **`Task` → `remotion-builder`** with handoff preconditions. |

**Explicit invoke mapping:** User or orchestrator may say **video-editor** in content sessions; **`content-lead`** / **`cco`** satisfy **`video-editor-handoff`** then dispatch **`Task` with `subagent_type` / agent target `remotion-builder`** (tech pack). **Do not** add a second tech agent file named `video-editor` under **`ai/cursor-tech-team`**.

### Invocation matrix — who may `Task` `remotion-builder` (CRO v1)

| Actor | When `Task` → `remotion-builder` is allowed | Forbidden |
|--------|-----------------------------------------------|-----------|
| **User** | Anytime explicit user invokes tech agent or approves dispatch text | — |
| **`content-lead`** | **`approved_plan_path`** lists phase + **`video-editor-handoff`** satisfied | Silent inference from generic pipeline; **`sme-*`** proxy |
| **`cco`** | **Only** when user explicitly asks **`cco`** to dispatch **`remotion-builder`** in planning chat (same bar as naming an agent), or plan records a one-off planning-swarm need with user sign-off — **not** automatic from routing-table classification alone | Auto-**`Task`** from **`content_article`** / default pipeline without user naming render |
| **Routing tables** | Must **not** set `default_agents: [remotion-builder]` for broad content tasks | Implicit “content + video” → **`remotion-builder`** without `requires_plan` + handoff |

**n8n / automation:** Workflows (e.g. **Execute Command**, shell nodes) must **not** pass arbitrary user- or payload-derived strings as **`remotion`** / **`ffmpeg`** argv. Only **checked-in** wrappers under corpus (e.g. `make render-*`, `scripts/*.sh` in allowlisted paths) with frozen interfaces — align with **`remotion-builder-governance`** and **CISO** review for any new n8n surface.

## Scope

| Area | Path |
|------|------|
| Tech — agent + skills + governance + routing | **dotfiles:** `ai/cursor-tech-team/agents/remotion-builder.md`, `skills/remotion-builder-planning-gate/`, `skills/remotion-builder-execution-gate/`, `rules/remotion-builder-governance.mdc`, `configurations/routing-table.yml`, optional `configurations/remotion-builder-{mode,qa}-policy.yml`, `docs/runbooks/remotion-builder-*.md` |
| Tech — orchestration hardening | **dotfiles:** `ai/cursor-tech-team/rules/agent-orchestration.mdc` (explicit non-auto-invoke + deny-list for peer `Task`); **`ai/cursor-tech-team/rules/observability.mdc`** (add **`remotion-builder`** to orchestration entrypoint audit list per CRO pass 2) |
| Content Cursor — **video-editor** + handoff + orchestration | **dotfiles:** `ai/cursor-content-team/agents/video-editor.md`, `skills/video-editor-handoff/SKILL.md`, `agents/cco.md`, `agents/content-lead.md`, `skills/content-team-discovery/SKILL.md`, `rules/agent-orchestration.mdc`, `rules/strict-tool-boundaries.mdc`, `README.md` (optional one-liner) |
| Content Gemini — parity | **dotfiles:** `ai/gemini-content-team/` twins per `hooks/manifest-pairs.txt` for touched **content-pack** files; `GEMINI.md`, `rules/agent-orchestration.md`, `docs/runbooks/gemini-agent-registry.md` if registry lists entrypoints |
| Reference corpus (separate git root) | **content-foundry:** `tools/remotion/**` (ADR `2026-05-10-tools-remotion-root`); `.cursor/rules/content-foundry-visual.mdc`, `content-foundry-agent-boundaries.mdc`, optional `_schema` + `_meta/SCHEMAS.md` if new frontmatter fields (e.g. `asset_video`) |
| **n8n-runner bootstrap (homelab)** | **home-server:** `infra/roles/ansible_user_setup/tasks/n8n_runner_bootstrap.yml`, **new** `tasks/n8n_runner_remotion_prereqs.yml` (or equivalent name), `defaults/main.yml` (**includes `ffmpeg` APT**); optional Molecule scenario / docs under `infra/tests/ansible/molecule/` or `.cursor/docs/` |

**Out of scope:** shipping a full Remotion starter **in this markdown plan** (P6/P7 describe scaffold + Ansible hooks only); CI vendor choice for **content-foundry** git repo (delegate to `vp-research`); duplicating **`remotion-builder.md`** into `gemini-content-team/agents/` (canonical definition stays **`ai/cursor-tech-team`** — see Open Questions).

## Risks & mitigations

| Risk | Impact | Mitigation | Owner |
|------|--------|------------|--------|
| New `tools/**` root in `content-foundry` without ADR | Schema/policy violation | **`tools/remotion/`** requires ADR + `path-conventions.md` row (see `2026-05-10-tools-remotion-root`); do not add sibling tool trees without same pattern | execution |
| `sme-*` or `tech-lead` auto-`Task`s `remotion-builder` | Policy breach, bypass gates | Tech: `agent-orchestration.mdc` deny-list; content: `agent-orchestration` + `content-foundry-agent-boundaries` clarify allowlist unchanged for SMEs | execution |
| Secrets in render (font CDN tokens, private assets) | Leak via logs/commits | `remotion-builder-governance.mdc`: env-only refs, `<REDACTED>`, no credentials in plans; optional `beforeShellExecution` redaction (existing hooks) | execution |
| Dual CRO confusion | Wrong critic applied to wrong artifact | **Editorial-cro** only on **CCO** plan; **tech cro-loop** only on **remotion-builder** plan (see below) | planners |
| Gemini drift vs Cursor content pack | Broken parity | Apply paired edits; run `ai/gemini-content-team/hooks/verify-gemini-manifest.sh` after changes | execution |
| Large binaries in git | Repo bloat | Prefer **Git LFS** or **ephemeral CI artifacts** + pointer path in frontmatter; document in governance | execution |
| Stakeholder expects **zero** Chromium on server | Wrong architecture / blocked CI | Document **renderer reality** section in agent + handoff skill; default = Headless Shell; optional track **experimental CSR** only with explicit user approval and separate runbook | planners + `remotion-builder` |
| Skia / Remotion **version skew** | Broken WASM or build | Lockfile + same minor on `remotion`, `@remotion/skia`, `@shopify/react-native-skia` per install docs; `vp-research` before major bumps | execution |
| **n8n-runner** missing Node / Chromium deps | Render fails on homelab | Bootstrap installs **Debian packages** from [Remotion Linux dependencies](https://www.remotion.dev/docs/miscellaneous/linux-dependencies) + ensures **Node** (reuse or extend existing NodeSource path); **`npm ci`** in `tools/remotion`; **`npx remotion browser ensure`** (non-interactive env) | `dev-infra` / Ansible |
| Bootstrap runs **before** `content-foundry` has `tools/remotion` | `npm ci` fails | Tasks **stat** `package.json` / lockfile and **skip** Remotion npm/browser steps until present; document ordering: deploy P6 (or merge scaffold) then re-run playbook; optional `homelab_n8n_runner_remotion_install: false` to disable | execution |
| **ffmpeg** filter injection / path traversal | RCE or data exfil | Governance: **allowlisted** post-render recipes only; no paste-through of untrusted strings into `-filter_complex`; paths under corpus **`assets/`** only; **`vp-research`** for dangerous flag history on upgrades | `remotion-builder` + `ciso` consult |
| **Headless Shell / browser ensure** supply chain | Compromised or drifting binary | P7 + governance: pin **Remotion major/minor** to match `package.json`; document **official** Remotion download path / `browser ensure` behavior per vendor docs; optional **cache dir** env (`REMOTION_CACHE` or doc-linked) on runner; **CISO** sign-off on any alternate mirror; prefer **air-gapped** pre-seeded cache only with written procedure | `ciso` |
| **Ansible / npm logs** | Token or env leak in stderr | **`no_log: true`** on `npm ci`, `npx remotion browser ensure`, and any task printing tool stderr; controller redaction policy per **`secrets-bitwarden`** / homelab rules | `dev-infra` |

## Operational expectations (SRE — CRO v1)

- **Disk:** Document budget for **Headless Shell** cache, **`node_modules`**, and **output mp4** under `n8n-runner` home or corpus; add cleanup or rotation note in P7 / runbook (e.g. cap cache dir, `make clean-remotion-cache` optional target).
- **`npm ci` idempotency:** Ansible should use explicit **`changed_when`** / return codes so second playbook run does not falsely churn; on failure, document **partial `node_modules`** recovery (re-run `npm ci` or delete + retry).
- **Observability:** **`remotion-builder`** execution episodes append **`agent-observability`** / brain audit entries with **`task_id`**, **`trace_id`**, render outcome, **bytes out**, duration — per org **`observability.mdc`** (same family as **`n8n-builder`** audit).

## CRO vs editorial-cro (explicit)

| Layer | Artifact | Critic | Patcher |
|-------|----------|--------|---------|
| **Editorial** | `<project>/.cursor/docs/plans/*.md` (or `.gemini/docs/plans/`) from **`cco`** | **`editorial-cro-loop`** (2 passes) | **`cco`** only |
| **Tech / Remotion + Skia** | `<project>/.cursor/docs/plans/YYYY-MM-DD-remotion-*.md` from **`remotion-builder`** | **`cro-loop`** (tech `cro`, same contract as `n8n-builder` / `cto`) | **`remotion-builder`** only |

**Both** apply when a content initiative includes a named **programmatic render** phase: CCO plan describes *what* gets rendered and *when* handoff occurs (phase may name **`video-editor`**); **`remotion-builder`** (after user invocation or plan-gated **`Task`** from **`content-lead`** / user) owns *how* (composition with **Skia**, **headless** CLI, WASM load, Chromium/GL flags, **ffmpeg** post-process, outputs). **No** editorial-cro pass on raw Remotion TS / ffmpeg scripts unless a human explicitly folds that into CCO scope (not default).

## Phase dependency graph

| Group | Phase ID | Depends on | Parallel siblings | Touches (disjoint across siblings) |
|-------|----------|------------|-------------------|-----------------------------------|
| G1 | P1 | — | — | `ai/cursor-tech-team/agents/remotion-builder.md`, `configurations/routing-table.yml`, `rules/agent-orchestration.mdc`, `rules/observability.mdc` |
| G2 | P2a | P1 | P2b | `ai/cursor-tech-team/skills/remotion-builder-planning-gate/**`, `docs/runbooks/remotion-builder-cro-loop.md` |
| G2 | P2b | P1 | P2a | `ai/cursor-tech-team/skills/remotion-builder-execution-gate/**`, optional `configurations/remotion-builder-*.yml` |
| G3 | P3 | P2a, P2b | — | `ai/cursor-tech-team/rules/remotion-builder-governance.mdc` |
| G4 | P4a | P3 | P4b | `ai/cursor-content-team/agents/video-editor.md`, `skills/video-editor-handoff/SKILL.md`, `agents/cco.md`, `skills/content-team-discovery/SKILL.md` |
| G4 | P4b | P3 | P4a | `ai/cursor-content-team/agents/content-lead.md`, `rules/agent-orchestration.mdc`, `rules/strict-tool-boundaries.mdc` |
| G5 | P5 | P4a, P4b | — | `ai/gemini-content-team/**` (paired files), `GEMINI.md`, `docs/runbooks/gemini-agent-registry.md` |
| G6 | P6 | P5 | — | `content-foundry/.cursor/**` (remotion subtree, rule tweaks, optional schema) |
| G7 | P7 | P6 | — | **home-server** `infra/roles/ansible_user_setup/**` (n8n-runner Remotion prereqs) |

---

## Implementation phases

### Phase P1: Tech entrypoint + routing + orchestration hardening

**Metadata:**  
`id: P1` · `depends_on: []` · `parallelizable_with: []` ·  
`touches: [ai/cursor-tech-team/agents/remotion-builder.md, ai/cursor-tech-team/configurations/routing-table.yml, ai/cursor-tech-team/rules/agent-orchestration.mdc, ai/cursor-tech-team/rules/observability.mdc]` ·  
`rollback_scope: same` · `destructive: false`

**Goal:** Define **`remotion-builder`** and prevent any other tech-pack entrypoint from `Task`-invoking it.

**Steps:**

1. **Add** `ai/cursor-tech-team/agents/remotion-builder.md` with frontmatter aligned to `n8n-builder.md`:
   - `name: remotion-builder`
   - `description:` explicit user invocation + programmatic video / **Remotion + Skia** + **ffmpeg** post-process / headless render / corpus-linked renders (see renderer reality in plan)
   - `model: inherit` (or pin per org policy)
   - `parallelizable: false`
   - `entrypoint: true`
   - `all_in_one: true`
   - `version: 2026.05.10` (date stamp)
   - Body: lifecycle **Stage A–E** analogous to `n8n-builder` (plan v0 → user approve → **tech `cro-loop`** → execution gate → verification); **delegate all Remotion API/version/CI research to `vp-research`**; **no** direct fetch tools in agent prose; workspace = **content corpus `<project>`** for plans under `<project>/.cursor/docs/plans/YYYY-MM-DD-remotion-<slug>.md`; composition/repo files under corpus as per handoff.
2. **Extend** `ai/cursor-tech-team/configurations/routing-table.yml`:
   - New `entrypoints[]` item `id: remotion-builder` with `invocation_phrases` e.g. `use remotion-builder`, `remotion-builder`, `render remotion video`.
   - New `task_types.remotion_programmatic_video` (or `programmatic_video`) with `default_agents: [remotion-builder]`, `requires_plan: true`, signals like `remotion`, `skia`, `ffmpeg`, `programmatic video`, `@remotion`.
3. **Patch** `ai/cursor-tech-team/rules/agent-orchestration.mdc`:
   - New subsection: **`remotion-builder` (user-invoked only)** — `cto`, `tech-lead`, `staff-engineer`, `code-reviewer`, `vp-*`, `sre-lead`, `ciso`, `vp-platform`, `vp-onboarding` **must not** `Task` `remotion-builder`. **Exception:** none from tech pack; **content org** handoff is not a tech-pack peer (document cross-pack pattern per **Invocation matrix** above: **user**, plan-gated **`content-lead`**, and **`cco`** only under explicit user-approved planning dispatch — not routing-table auto-select).
4. **Patch** `ai/cursor-tech-team/rules/observability.mdc` — extend the fail-closed bullet that lists orchestration entrypoint agents so **`remotion-builder`** is included alongside **`cto`**, **`tech-lead`**, **`code-reviewer`** for required swarm audit fields (finding **cro-rmt-p02-03**). If org policy exempts all-in-one entrypoints, record **ADR** under `.cursor/docs/decisions/` instead — default here is **extend the list**.

**Verification:** Grep shows no other `Task remotion-builder` from tech agents; YAML parses; agent frontmatter passes existing Cursor agent lints if any; **observability** rule mentions **`remotion-builder`** where entrypoint audit is defined.

**Rollback:** Revert the three files.

---

### Phase P2a: Planning gate + CRO runbook (tech)

**Metadata:**  
`id: P2a` · `depends_on: [P1]` · `parallelizable_with: [P2b]` ·  
`touches: [ai/cursor-tech-team/skills/remotion-builder-planning-gate/SKILL.md, ai/cursor-tech-team/docs/runbooks/remotion-builder-cro-loop.md]` ·  
`rollback_scope: same`

**Goal:** Standardize plan v0 structure and tech CRO handoff for Remotion episodes.

**Steps:**

1. **Add** `ai/cursor-tech-team/skills/remotion-builder-planning-gate/SKILL.md` — mirror `n8n-builder-planning-gate` sections but replace n8n-specific fields with: Remotion **root path**, **Skia enabled** (yes/no + `LoadSkia` / entry path), **pinned dependency set** (`remotion`, `@remotion/skia`, `@shopify/react-native-skia`), **entry composition**, **render mode** (`ssr_headless_shell` default vs `experimental_csr` — if latter, explicit user sign-off), **Chromium / GL posture** (local vs CI, `--gl` if any), **output codec/resolution**, **asset output paths**, **ffmpeg post-flight** (none / remux / transcode / audio mux — **recipe id** or frozen argv template, platform target e.g. Reels), **font/asset credential posture** (env vars only), **parallel phases** over disjoint compositions or disjoint corpus notes. Include one-line **renderer reality** (Skia WASM inside Headless Shell for default SSR).
2. **Add** `ai/cursor-tech-team/docs/runbooks/remotion-builder-cro-loop.md` — adapt from `n8n-builder-cro-loop.md`: singleton loop, ledger path `~/ai-brain/session/<task-id>/critic-ledger.md`, patcher = `remotion-builder`.

**Verification:** Skill lists required plan sections; runbook references `cro-loop` skill and `subagent-response-protocol`.

**Rollback:** Delete added files.

---

### Phase P2b: Execution gate + optional policies (tech)

**Metadata:**  
`id: P2b` · `depends_on: [P1]` · `parallelizable_with: [P2a]` ·  
`touches: [ai/cursor-tech-team/skills/remotion-builder-execution-gate/SKILL.md, ai/cursor-tech-team/configurations/remotion-builder-mode-policy.yml, ai/cursor-tech-team/configurations/remotion-builder-qa-policy.yml]` ·  
`rollback_scope: same` (optional YAMLs may be omitted in minimal v1)

**Goal:** Gate shell/render execution and optional QA checklist.

**Steps:**

1. **Add** `remotion-builder-execution-gate/SKILL.md` — group checkpoints, `npx remotion` / `npm run render` invocation pattern, **`remotion browser ensure`** (or documented `ensureBrowser`) when applicable, **Skia WASM** load verified (smoke frame), optional **`--gl`** per environment, **`ffmpeg` invocation** only from approved plan recipe / wrapper script (version pin, `ffmpeg -version` smoke), **fail-closed** if CRO incomplete; **destructive** = overwriting published assets without approval.
2. **Optional:** `remotion-builder-mode-policy.yml` — e.g. `local` vs `ci` render targets, `ssr_headless` vs `experimental_csr` (lighter than n8n `mcp-live`); `remotion-builder-qa-policy.yml` — smoke frame, duration cap, file size bounds, **Skia canvas** sanity check, **ffmpeg** output duration / loudness spot-check when audio mux applies.

**Verification:** Skill cross-links governance + planning gate.

**Rollback:** Remove new files.

---

### Phase P3: Governance rule (tech)

**Metadata:**  
`id: P3` · `depends_on: [P2a, P2b]` · `parallelizable_with: []` ·  
`touches: [ai/cursor-tech-team/rules/remotion-builder-governance.mdc]` ·  
`rollback_scope: same`

**Goal:** Non-bypass rule for secrets, prod render, dependency install, font licensing.

**Steps:**

1. **Add** `remotion-builder-governance.mdc` — pattern from `n8n-builder-governance.mdc`: no secrets in plans/output; **high-risk** gates for `npm install` from untrusted sources, **arbitrary shell**, **network fetch** of assets without allowlist; **production render** = explicit approval; **Skia / WASM** supply chain (pinned versions, lockfile); **Chromium / Headless Shell**: only **vendor-documented** `remotion browser ensure` (or equivalent) paths; pin Remotion version to downloaded browser major; **no** ad-hoc third-party browser binaries; cache directory documented; **ffmpeg**: treat **ad hoc `-vf` / `-filter_complex`** from untrusted input as **high-risk** (named approval per phase); prefer **checked-in** scripts or makefile targets; **n8n / automation** must not construct remotion/ffmpeg argv from untrusted workflow fields; **audit** optional append-only `~/ai-brain/org/global/orchestration/remotion-builder-audit.md` for headless/CI; align **Ansible `no_log`** on npm/browser tasks with home-server role.

**Verification:** Rule `description` frontmatter set; stow exposes `~/.cursor/rules/remotion-builder-governance.mdc`.

**Rollback:** Delete rule file.

---

### Phase P4a: Content pack — **video-editor** agent + handoff + CCO / discovery

**Metadata:**  
`id: P4a` · `depends_on: [P3]` · `parallelizable_with: [P4b]` ·  
`touches: [ai/cursor-content-team/agents/video-editor.md, ai/cursor-content-team/skills/video-editor-handoff/SKILL.md, ai/cursor-content-team/agents/cco.md, ai/cursor-content-team/skills/content-team-discovery/SKILL.md]` ·  
`rollback_scope: same`

**Goal:** Content-org **name** **`video-editor`** with **`video-editor-handoff`**; execution remains **`Task` → `remotion-builder`**.

**Steps:**

1. **Add** `ai/cursor-content-team/agents/video-editor.md` — content-pack agent (frontmatter `name: video-editor` or display equivalent per pack conventions):
   - **Role:** Editorial video pipeline owner in content org — briefs, phase text, optional storyboard notes; **does not** redefine tech **`remotion-builder`** lifecycle.
   - **Invoke:** User may **`Task` `video-editor`** for planning/brief help; for **render + ffmpeg execution**, orchestration uses **`video-editor-handoff`** then **`Task` `remotion-builder`** (same as CVO pattern: specialist vs executor).
   - **Body:** Point to **`video-editor-handoff`**, **`~/.cursor/agents/remotion-builder.md`**, renderer reality (Headless Shell), **ffmpeg** mentioned as post-step owned by **`remotion-builder`**.
2. **Add** `video-editor-handoff/SKILL.md` — parallel `chief-visual-handoff`:
   - **When:** plan phase names **`video-editor`**, **programmatic video**, **Skia** / **ffmpeg** deliverable, or `touches` include video output paths under `assets/video/` or `assets/<channel>/`.
   - **Preconditions:** `workspace_root`, `content_id`, `target_note_path`, `approved_plan_path`, **brief** (script/beats, brand refs), **output spec** (resolution, duration cap), **render mode** (`ssr_headless_shell` default), **Skia** yes/no, **ffmpeg recipe** id or “none”.
   - **Dispatch:** **`Task` target = `remotion-builder`** (tech pack) — payload block must name `remotion-builder` explicitly for runtime routing.
   - **Explicit:** project **`sme-*`** must **not** call `Task` → **`remotion-builder`**; they prepare briefs for **`video-editor`** / **`content-lead`**; **user / `cco` / plan-gated `content-lead`** only for tech **`Task`**.
3. **Update** `cco.md` org diagram — add branch **`video-editor`** (programmatic video: Remotion + Skia + ffmpeg) + **`video-editor-handoff`** → execution **`Task` `remotion-builder`** (tech pack); footnote default SSR uses **Headless Shell**.
4. **Update** `content-team-discovery/SKILL.md` — register **`video-editor`** from **`{root}/.cursor/agents/`** when project copies agents; register **`remotion-builder`** as **stowed tech singleton** (`~/.cursor/agents/remotion-builder.md`) when handoff applies (**not** merged from project roster).

**Verification:** `video-editor.md` + handoff skill exist; CCO diagram names **video-editor** and **`Task` `remotion-builder`**; discovery distinguishes project vs org agents.

**Rollback:** Revert files.

---

### Phase P4b: Content pack — content-lead + orchestration rules

**Metadata:**  
`id: P4b` · `depends_on: [P3]` · `parallelizable_with: [P4a]` ·  
`touches: [ai/cursor-content-team/agents/content-lead.md, ai/cursor-content-team/rules/agent-orchestration.mdc, ai/cursor-content-team/rules/strict-tool-boundaries.mdc]` ·  
`rollback_scope: same`

**Goal:** Plan-gated execution path for `content-lead`.

**Steps:**

1. **Update** `content-lead.md` — in **Discovery**, add bullet: when approved plan phase names **`video-editor`**, **programmatic video**, or **ffmpeg** / Remotion deliverable, satisfy **`video-editor-handoff`** then **`Task` `remotion-builder`** (same gating as CVO: only if **`approved_plan_path`** lists the phase).
2. **Update** `agent-orchestration.mdc` — matrix rows:
   - **`video-editor`** — **content-pack agent** (`agents/video-editor.md`); **callers:** user, **`cco`**, **`content-lead`** for briefs / planning; **forbidden:** **`sme-*`** → **`Task` `remotion-builder`**.
   - **`remotion-builder`** — **org tech singleton** (`~/.cursor/agents/remotion-builder.md`); **callers:** **user**, **`cco`** (planning swarm when explicitly invoking tech agent), **`content-lead`** (execution, plan-gated after **`video-editor-handoff`**). **Forbidden:** tech-pack peer `Task`; **`sme-*`** direct `Task`.
3. **Update** `strict-tool-boundaries.mdc` — corpus-facing **programmatic video** execution: **`video-editor-handoff`** → **`Task` `remotion-builder`**; briefs from SMEs only.

**Verification:** Grep **`video-editor`** and **`remotion-builder`** in content pack consistent; no `sme-*` → **`remotion-builder`** allowlist expansion.

**Rollback:** Revert.

---

### Phase P5: Gemini content pack parity

**Metadata:**  
`id: P5` · `depends_on: [P4a, P4b]` · `parallelizable_with: []` ·  
`touches: [ai/gemini-content-team/agents/video-editor.md, ai/gemini-content-team/agents/cco.md, ai/gemini-content-team/agents/content-lead.md, ai/gemini-content-team/skills/video-editor-handoff/SKILL.md, ai/gemini-content-team/skills/content-team-discovery/SKILL.md, ai/gemini-content-team/rules/agent-orchestration.md, ai/gemini-content-team/rules/strict-tool-boundaries.md, ai/gemini-content-team/GEMINI.md, ai/gemini-content-team/docs/runbooks/gemini-agent-registry.md]` ·  
`rollback_scope: same`

**Goal:** Mirror Cursor content edits; document Gemini plan paths (`.gemini/docs/plans`).

**Steps:**

1. **Port** paired files (manual or script): same semantic edits as P4a/P4b with `.gemini` path wording where rules already differ (**`video-editor`**, **`video-editor-handoff`**).
2. **Update** `GEMINI.md` — table or subsection: **Programmatic video** — content org **`video-editor`**; tech execution **`remotion-builder`** in **`ai/cursor-tech-team/agents/remotion-builder.md`** (Cursor stow); **ffmpeg** post-process owned by **`remotion-builder`**; Gemini sessions **hand off** via user invocation in Cursor or repeated brief in Gemini with user executing render in Cursor (document explicitly).
3. **Run** `hooks/verify-gemini-manifest.sh` from repo root per `CONVENTIONS.md`.
4. **Update** `gemini-agent-registry.md` if it lists orchestration agents — add **`video-editor`** (content) + **`remotion-builder`** (external / Cursor tech) pointers.

**Verification:** Manifest verifier passes.

**Rollback:** Revert gemini tree files.

---

### Phase P6: Content-foundry corpus contracts

**Metadata:**  
`id: P6` · `depends_on: [P5]` · `parallelizable_with: []` ·  
`touches: [content-foundry/tools/remotion/**, content-foundry/.cursor/rules/content-foundry-visual.mdc, content-foundry/.cursor/rules/content-foundry-agent-boundaries.mdc, optional content-foundry/_schema/*, content-foundry/_meta/SCHEMAS.md]` ·  
`rollback_scope: scoped to created files`

**Goal:** Allow Remotion project + outputs without violating path conventions.

**Steps:**

1. **Create** `content-foundry/tools/remotion/` — `package.json` (**`remotion`**, **`@remotion/skia`**, **`@shopify/react-native-skia`** pinned compatibly per [Remotion Skia install](https://www.remotion.dev/docs/skia)), `remotion.config.ts` (**`enableSkia`**), `src/Root.tsx` with **`LoadSkia()`** before `registerRoot` (or minimal scaffold **in execution**, not in this planning doc), optional **`scripts/`** or **`Makefile`** targets wrapping **ffmpeg** post-steps (or document corpus-level **`bin/`** if allowed by path-conventions), **README** pointing to **`video-editor-handoff`** + one paragraph on **Headless Shell** vs “no Chromium” expectations + **ffmpeg** recipe policy.
2. **Prefer** output paths **`assets/video/{cf-id}-<slug>.mp4`** (channel `video` exists in schema) or **`assets/instagram/`** if Reels-specific—pick one convention in `_meta/SCHEMAS.md` + visual rule.
3. **Update** `content-foundry-visual.mdc` — subsection **Programmatic video (Remotion + Skia + ffmpeg)**; CVO still owns **static raster**; **encoded video files** via content **`video-editor`** briefs and tech **`remotion-builder`** execution (headless CLI; Skia; optional **ffmpeg** post).
4. **Update** `content-foundry-agent-boundaries.mdc` — **`Task` allowlist** remains **`chief-visual-officer` only** for org agents from project tier; add line: **programmatic video** → **`Task` `remotion-builder`** only via **user / `cco` / `content-lead`** after **`video-editor-handoff`** (not `sme-*` direct **`remotion-builder`** `Task`); **`video-editor`** may appear in project `.cursor/agents/` when onboarded.
5. **If** frontmatter needs **`asset_video`**: add ADR + `content-atom.schema.json` patch + `content-foundry-validate` checklist update.

**Verification:** Manual schema check per `content-foundry-validate` skill; registry line for touched atoms; `00-INDEX` / wikilinks if new notes.

**Rollback:** Delete scaffold; revert rules.

---

### Phase P7: home-server — n8n-runner Remotion / Skia bootstrap

**Metadata:**  
`id: P7` · `depends_on: [P6]` · `parallelizable_with: []` ·  
`touches: [home-server/infra/roles/ansible_user_setup/tasks/n8n_runner_bootstrap.yml, home-server/infra/roles/ansible_user_setup/tasks/n8n_runner_remotion_prereqs.yml, home-server/infra/roles/ansible_user_setup/defaults/main.yml]` ·  
`rollback_scope: same` · optional Molecule / docs in **home-server** repo

**Goal:** When **`homelab_n8n_runner_enabled`**, provisioning installs everything **`remotion-builder`** / CLI renders need on the runner host: **OS libraries** for Headless Shell, **Node + npm** (consistent major with Remotion’s supported range — align with `homelab_nodejs_major_version` or document override), **project dependencies**, **Chrome Headless Shell** via Remotion’s ensure step, and **`ffmpeg`** (Debian package **`ffmpeg`**) for post-render steps.

**Canonical role entry:** Today **`n8n_runner_bootstrap.yml`** is imported from `tasks/main.yml` after **`n8n_runner_ssh.yml`**. Extend with **`import_tasks: n8n_runner_remotion_prereqs.yml`** at end of `n8n_runner_bootstrap.yml` (or from `main.yml` immediately after bootstrap — keep one import site).

**Steps:**

1. **`defaults/main.yml`** — add toggles and lists, for example:
   - `homelab_n8n_runner_install_remotion_prereqs: true` (when `homelab_n8n_runner_enabled`, default **true** once feature ships).
   - `homelab_n8n_runner_remotion_project_dir: "{{ homelab_n8n_runner_content_foundry_dest }}/tools/remotion"` (must match P6 layout).
   - `homelab_n8n_runner_remotion_apt_packages: [...]` — **mirror** [Linux dependencies](https://www.remotion.dev/docs/miscellaneous/linux-dependencies) for Debian/Ubuntu **plus** **`ffmpeg`**; re-validate with **`vp-research`** when Remotion bumps docs.
   - Optional: `homelab_n8n_runner_remotion_npm_ci: true`, `homelab_n8n_runner_remotion_browser_ensure: true`.
2. **`tasks/n8n_runner_remotion_prereqs.yml`** (new) — all blocks guarded by `homelab_n8n_runner_enabled | bool` and `homelab_n8n_runner_install_remotion_prereqs | bool`:
   - **APT** (Debian family): install `homelab_n8n_runner_remotion_apt_packages`.
   - **Node present:** If **`homelab_install_gemini_cli`** is false or Node install tasks do not run on this host, **ensure** Node/npm for `n8n-runner` (reuse same NodeSource pattern as `main.yml` **or** extract shared task include — avoid duplicating version drift). Document in role README that **Remotion requires Node** ≥ minimum per Remotion docs.
   - **Stat** `{{ homelab_n8n_runner_remotion_project_dir }}/package.json` (and optionally `package-lock.json`). If absent, **skip** npm/browser tasks (idempotent no-op until P6 lands in cloned repo).
   - **`npm ci`** (preferred) or `npm install`: `become_user: "{{ homelab_n8n_runner_user }}"`, `chdir: homelab_n8n_runner_remotion_project_dir`, `HOME: homelab_n8n_runner_home`, non-interactive env.
   - **`npx remotion browser ensure`** (or documented equivalent for pinned Remotion major): same user/env; set `CI=true` or flags Remotion documents for non-interactive download; **`no_log: true`** on this task (and **`npm ci`**) to reduce credential leakage via tool stderr; document **`changed_when`** so re-runs are idempotent when binary already present.
   - Optional smoke: `npx remotion compositions` or `npx remotion versions` — **when** `package.json` exists — to fail playbook early; **`ffmpeg -version`** as `n8n-runner` to verify binary.
3. **`n8n_runner_bootstrap.yml`** — append single **`import_tasks: n8n_runner_remotion_prereqs.yml`** (or inline `include_tasks` with `name:`) so Remotion prereqs run **after** dotfiles stow and **after** content-foundry clone (order already: SSH clone → bootstrap). **Ordering invariant:** content-foundry clone (`n8n_runner_ssh.yml`) must complete before Remotion dir exists; if clone is empty branch without `tools/remotion`, P7 skips npm until next run.
4. **home-server docs / tests:** Add short note under `infra/roles/ansible_user_setup/meta/main.yml` description or **home-server** `.cursor/docs/` ADR: “n8n-runner Remotion prereqs” including **disk budget** for browser cache + `node_modules`. Extend **Molecule** default scenario if present (`infra/tests/ansible/molecule/`) with assert Node + stat remotion dir **or** document manual verification (`make test-fast` / `make test` per repo Makefile).

**Verification:**

- Idempotent second run: no spurious `changed` on npm/browser when already satisfied (use `creates` / check mode where applicable).
- On a test host with cloned `content-foundry` containing P6 scaffold: playbook completes; `sudo -u n8n-runner -H bash -lc 'cd ~/content-foundry/tools/remotion && npx remotion browser ensure'` exits 0 (or already cached).

**Rollback:** Remove `import_tasks`, delete `n8n_runner_remotion_prereqs.yml`, revert defaults.

---

## CCO / content-lead — video branch (diagram)

**Updated narrative (for `cco.md`):**

```
User
 │
CCO ── editorial-cro-loop
 │     ├─ … vp-*, staff-editor, cpo, …
 │     ├─ chief-visual-officer (static raster: hero/card/thumb) + chief-visual-handoff
 │     └─ video-editor (briefs / editorial video phase) + video-editor-handoff → Task remotion-builder
 │           (tech pack: Remotion + Skia + ffmpeg; headless; plan-gated only)
 ▼
content-lead (execution; registers CVO when chief-visual-handoff applies; video-editor-handoff → Task remotion-builder when approved plan names phase)
```

---

## Skills justification

| Approach | Rationale |
|----------|-----------|
| **Two skills** (`remotion-builder-planning-gate`, `remotion-builder-execution-gate`) | Matches **`n8n-builder`** proven split; keeps Stage A/B vs C/D boundaries testable and mirrors existing org mental model. |
| **One consolidated skill** | Lower file count; acceptable if team wants less surface—tradeoff: longer single doc. **Recommendation:** **two skills** for parity with `n8n-builder`. |
| **`video-editor-handoff` (content pack)** | Required mirror of **`chief-visual-handoff`**; cross-pack contract names **`video-editor`** editorially and **`Task`s `remotion-builder`** for execution. |

---

## Verification checklist (post-implementation)

**Dotfiles / stow**

- [ ] `make stow` (or DotMate equivalent) installs `~/.cursor/agents/remotion-builder.md`, rules, skills, configurations.
- [ ] `ai/cursor-tech-team/configurations/routing-table.yml` validates (YAML load).
- [ ] `ai/gemini-content-team/hooks/verify-gemini-manifest.sh` exits 0 after parity edits.

**Tech orchestration**

- [ ] `grep -R "Task.*remotion-builder" ai/cursor-tech-team/agents` — only `remotion-builder.md` self-reference if any; **no** `cto`/`tech-lead`/`staff-engineer` matches.

**Content orchestration**

- [ ] `content-lead` and `cco` reference **`video-editor`** + **`video-editor-handoff`**; **`sme-*`** rules do **not** allow direct `Task` → `remotion-builder`.
- [ ] **`video-editor.md`** present in content packs; user can invoke **video-editor** by name.

**content-foundry**

- [ ] All writes under `path-conventions.md` allowlist.
- [ ] If schema extended: `_schema/content-atom.schema.json` + atom passes validation.
- [ ] `00-INDEX/registry.jsonl` updated for atoms receiving `asset_*` / video outputs.
- [ ] Rendered file exists at declared **`assets/<channel>/`** path; note body or frontmatter links asset.
- [ ] **Skia:** `LoadSkia` ordering and **`enableSkia`** config present; pinned `@remotion/skia` / `remotion` versions match.
- [ ] **Headless:** `remotion browser ensure` (or equivalent) succeeds in target environment; GL mode documented if non-default.
- [ ] **ffmpeg:** `ffmpeg -version` on runner / dev host; post-render recipe documented and governance-approved if non-trivial.

**home-server / n8n-runner**

- [ ] Ansible role applies: `homelab_n8n_runner_remotion_apt_packages` matches current Remotion Linux-deps doc **and includes `ffmpeg`** (re-check after upgrades).
- [ ] After playbook: `n8n-runner` can run `npm ci` path under `~/content-foundry/tools/remotion` without manual installs.
- [ ] `npx remotion browser ensure` succeeds as `n8n-runner` (or documents cache path / disk budget).
- [ ] `make test-fast` / Molecule (if extended) passes for **`ansible_user_setup`**.
- [ ] **Observability:** `remotion-builder` run records **`task_id`** / outcome per **`agent-observability`** / org audit path.
- [ ] **Disk:** Runbook or role docs state cache + artifact retention for runner.

---

## Tech `cro-loop` review record (this plan)

| Pass | Ledger / notes |
|------|----------------|
| **1** | **Findings:** `cro-rmt-s01` (supply-chain / browser ensure + logs + n8n argv), `cro-rmt-o01` (disk, npm idempotency, observability), `cro-rmt-c01` (`cco` vs `content-lead` invoke clarity), `cro-rmt-g01` (Gemini execution hole). **Ledger:** `~/ai-brain/session/remotion-plan-cro-2026-05-10/critic-ledger.md` |
| **2** | **New findings:** `cro-rmt-p02-01` (doc glue / G7 timing), `cro-rmt-p02-02` (resolved-decisions xref), `cro-rmt-p02-03` (observability entrypoint list). **Status:** addressed in **Pass 2 residual** + P1 step 4. **`next_actions`:** `cro_loop_complete`. |

**Plan versions:** **v0** — initial draft; **v1** — after CRO pass 1 (Invocation matrix, SRE expectations, supply-chain + `no_log`, Gemini default); **v2** — after CRO pass 2 (Pass 2 residual, **`observability.mdc`** touch, doc xref cleanup).

### Pass 2 residual (applied in v2)

| ID | Fix in plan / execution |
|----|-------------------------|
| **cro-rmt-p02-01** | Filled pass-2 row in this table; **G7** references completed loop only after this section exists. |
| **cro-rmt-p02-02** | **Resolved decisions** references **`cro-rmt-g01`** only (no stale “Open Q1” label). |
| **cro-rmt-p02-03** | **P1** step 4 + **Scope** + **`observability.mdc`** patch — **`remotion-builder`** in entrypoint swarm-audit list. Optional **`Task` `sre-lead`** during implementation if ADR exemption preferred. |

---

## Open questions

1. **Output channel:** Default **`assets/video/`** vs **`assets/instagram/`** for Reels—single convention vs dual?
2. **Schema:** Is **`asset_video`** (and optional **`video_alt`**) worth a formal schema bump vs storing path only in markdown body?
3. **CI:** Is **GitHub Actions** (or other) in-scope for `content-foundry` in v1, or **local-only** render until `vp-research` recommends?
4. **True Chromium-free server:** If product still requires **no** Chromium-class binary after this plan, **`vp-research`** must re-validate Remotion roadmap; until then treat as **non-default** / research spike only.
5. **Node policy on runner:** If **`homelab_install_gemini_cli`** is ever **false**, should **`n8n_runner_remotion_prereqs`** own a dedicated NodeSource install, or is Gemini+Node mandatory on all n8n-runner hosts?

### Resolved decisions (CRO v1)

- **Gemini vs Cursor execution:** **`remotion-builder`** = **Cursor-only** for v1; Gemini **`video-editor`** = briefs / planning. Expand only via future ADR (**cro-rmt-g01**).

---

## Checkpoint — Group G1

> **Checkpoint:** Group G1 complete (phase: P1).  
> Reply **"proceed"** to continue to G2, or provide feedback.

---

## Checkpoint — Group G2

> **Checkpoint:** Group G2 complete (phases: P2a, P2b).  
> Reply **"proceed"** to continue to G3, or provide feedback.

---

## Checkpoint — Group G3

> **Checkpoint:** Group G3 complete (phase: P3).  
> Reply **"proceed"** to continue to G4, or provide feedback.

---

## Checkpoint — Group G4

> **Checkpoint:** Group G4 complete (phases: P4a, P4b).  
> Reply **"proceed"** to continue to G5, or provide feedback.

---

## Checkpoint — Group G5

> **Checkpoint:** Group G5 complete (phase: P5).  
> Reply **"proceed"** to continue to G6, or provide feedback.

---

## Checkpoint — Group G6

> **Checkpoint:** Group G6 complete (phase: P6).  
> Reply **"proceed"** to continue to G7 (home-server bootstrap), or provide feedback.

---

## Checkpoint — Group G7

> **Checkpoint:** Group G7 complete (phase: P7 — **home-server** `ansible_user_setup` / n8n-runner Remotion prereqs).  
> **CRO note:** **Tech `cro-loop` completed** (2 passes) — see **Tech `cro-loop` review record**. This file is **plan v2** for cross-repo work (dotfiles + content-foundry + home-server) after pass 2 edits. **`dev-infra`** may own P7 with the same checkpoint discipline.

---

## Execution handoff (after plan approval + CRO if applicable)

Choose one:

- **(A)** Phase-by-phase with **`tech-lead`** (dotfiles + content-foundry) and **`dev-infra`** / human (home-server P7) + group checkpoints.  
- **(B)** All phases pre-approved: **`tech-lead`** + home-server execution in one coordinated run (`execution_mode: all_phases`) with explicit sign-off for Ansible against prod homelab.

**Do not** auto-start execution.

---

## Agent frontmatter reference (`remotion-builder`)

Suggested YAML frontmatter (finalize in P1):

```yaml
name: remotion-builder
description: Org-level Remotion + Skia + ffmpeg programmatic video builder. All-in-one planning + execution in the content corpus repo; headless SSR via Chrome Headless Shell (Skia WASM inside Chromium per vendor); ffmpeg for post-render mux/transcode per approved recipes; mandatory tech CRO loop before implementation. Use only when the user explicitly invokes this agent or when a documented video-editor-handoff / content-plan handoff applies. Delegates external docs to vp-research.
model: inherit
version: 2026.05.10
parallelizable: false
entrypoint: true
all_in_one: true
```

### Content pack frontmatter reference (`video-editor`)

Suggested YAML frontmatter for **`ai/cursor-content-team/agents/video-editor.md`** (Gemini twin mirrors); finalize in P4a:

```yaml
name: video-editor
description: Content-org video pipeline — briefs, editorial phases, and video-editor-handoff. Execution of Remotion + Skia + ffmpeg is via Task remotion-builder (tech pack); do not bypass handoff gates.
model: inherit
version: 2026.05.10
```

---

## References consulted

- `ai/cursor-tech-team/agents/n8n-builder.md` — entrypoint / lifecycle pattern  
- `ai/cursor-content-team/agents/cco.md`, `content-lead.md`, `skills/chief-visual-handoff/SKILL.md` — CVO / handoff precedent; **`video-editor`** + **`video-editor-handoff`** mirror  
- `ai/cursor-content-team/rules/agent-orchestration.mdc` — singleton registration  
- `ai/gemini-content-team/rules/agent-orchestration.md`, `hooks/manifest-pairs.txt` — parity expectations  
- `content-foundry/_schema/path-conventions.md`, `content-foundry-visual.mdc`, `content-foundry-agent-boundaries.mdc`
- **home-server:** `infra/roles/ansible_user_setup/tasks/main.yml`, `tasks/n8n_runner_bootstrap.yml`, `tasks/n8n_runner_ssh.yml`, `defaults/main.yml`
- Remotion: [Skia](https://www.remotion.dev/docs/skia), [Enable Skia](https://www.remotion.dev/docs/skia/enable-skia), [Skia Canvas](https://www.remotion.dev/docs/skia/skia-canvas), [Chrome Headless Shell](https://www.remotion.dev/docs/miscellaneous/chrome-headless-shell), [GL options](https://www.remotion.dev/docs/gl-options), [Client-side rendering](https://www.remotion.dev/docs/client-side-rendering), [Linux dependencies](https://www.remotion.dev/docs/miscellaneous/linux-dependencies)
