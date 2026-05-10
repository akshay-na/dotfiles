# Gemini CLI — Dotfiles content pipeline

This file is stowed to `~/.gemini/GEMINI.md`. It describes the **ai-brain + Gemini** setup: external **`cco`** (planning + pipeline owner), **`content-lead`** (execution orchestrator), **`metrics-steward`** (metrics ingest), and **internal** personas that only run inside a single **`cco`** invocation.

Canonical paths: **`CONVENTIONS.md`**, **`rules/project-identity.md`**, **`skills/project-identity/SKILL.md`**, **`rules/brain-paths.md`** ( **`~/ai-brain/projects/<project_name>/`** — same derivation as Cursor **`kb-identity`**).

## Startup Checks

Before running orchestration commands:

1. Subagent prerequisite:
   - Verify `experimental.enableAgents` is `true` in `~/.gemini/settings.json`.
   - If missing, ask permission before proposing a manual settings update. This dotfiles tree does not mutate `settings.json`; the user or installer edits it.

2. Headless / non-interactive content runs (n8n, cron, scripts):
   - Invoke with **`-p` / `--prompt`** (or equivalent stdin flow) so the CLI does not open the interactive TUI. Prefer **`--output-format json`** or **`stream-json`** when the wrapper needs structured events instead of human prose.
   - In restricted environments, set **`GEMINI_CLI_TRUST_WORKSPACE=true`** so workspace trust does not block unattended runs (see Gemini CLI env reference).
   - **UI noise (when any TUI still appears):** in `settings.json` under `ui`, keep **`inlineThinkingMode`** **`"off"`** (suppresses inline model thinking), **`showStatusInTitle`** **`false`** (no thoughts in the terminal title), and optionally set **`hideBanner`**, **`hideContextSummary`**, **`hideTips`**, and **`hideFooter`** to **`true`** to trim banners, context chips, tips, and footer.
   - **API-level thoughts (thinking models):** to avoid emitting thought traces in the generation config, add a **`modelConfigs`** override for the models/agents you use with **`generateContentConfig.thinkingConfig`** — e.g. **`includeThoughts`: `false`** and **`thinkingBudget`: `0`** where the API supports it (see **`docs/reference/configuration.md`** and **`docs/cli/generation-settings.md`** in [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)). Prefer a **`modelConfigs.customOverrides`** (or alias) entry scoped to your headless profile so interactive sessions can keep different thinking defaults.
   - Do **not** enable debug verbosity for production headless jobs: avoid **`--debug`** / **`-d`** unless diagnosing a failure.

## Agent dispatch (Gemini CLI)

Subagents are **not** Cursor **`Task`** calls. With **`experimental.enableAgents`**, the CLI exposes **per-agent delegation tools** (see session tool list). **Dispatch** = invoke the tool bound to that agent’s definition under **`~/.gemini/agents/`** or **`<project>/.gemini/agents/`**. Policy: **`mode-auto-selection.md`** + **`agent-orchestration.md`** (zero-gap chain — no roleplay substitutes).

## External agents (selectable entrypoints)

| Agent             | File                        | Role                                                                                                                                                                                                                               |
| ----------------- | --------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `cco`             | `agents/cco.md`             | Chief Content Officer — planning entrypoint; editorial phases; **`editorial-cro-loop`** after plan v0; delegates to org specialists; does **not** replace **`content-lead`** for repo execution.                                      |
| `content-lead`    | `agents/content-lead.md`    | Execution orchestrator — **`content-team-discovery`**, **`generate-content-pipeline`**, **`content-git-workflow`**; discovers **`{root}/.gemini/agents/`** on Gemini runs; checkpoints per plan.                                        |
| `video-editor`    | `agents/video-editor.md`    | Programmatic video briefs + **`video-editor-handoff`**. **Render execution** = **`remotion-builder`** in **Cursor** (`ai/cursor-tech-team` stow) — not a Gemini-local agent in v1.                                                      |
| `metrics-steward` | `agents/metrics-steward.md` | Ingest/normalise manual metrics into `<content-brain>/analytics/`. **Never** run inside `cco`.                                                                                                                                      |

**Registry:** YAML frontmatter on agent files is **`name` + `description` only** — model pins and tool policy live here, in **`rules/`**, and in runbooks (`docs/runbooks/gemini-agent-registry.md`).

Do not expose `agents/internal/*` as separate HTTP/CLI products.

### Hooks (Gemini native)

Lifecycle automation uses **`settings.json` → `"hooks"`** (merge-only — see **`docs/runbooks/gemini-settings-merge.md`**). Adapter scripts live in **`hooks/`** and must emit **strict JSON on stdout** ([Gemini hooks](https://geminicli.com/docs/hooks/)).

## Internal personas (`cco` only)

Loaded from `agents/internal/*.md` only when their phase runs. Roster and phase mapping:

| Persona                     | Typical phases                    | KB focus                                          |
| --------------------------- | --------------------------------- | ------------------------------------------------- |
| `cmo`                       | TOPIC_DECISION, RESEARCH, BRIEF   | Strategy                                          |
| `vp-research`               | TOPIC_DECISION, RESEARCH          | Sources / claims                                  |
| `vp-brand`                  | BRIEF, BRAND_COMPLIANCE           | Voice + veto                                      |
| `vp-editorial`              | BRIEF                             | Line direction                                    |
| `editor-blog`               | DRAFT                             | `<content-brain>/drafts/blog/`                              |
| `editor-twitter`            | DRAFT                             | `<content-brain>/drafts/twitter/`                           |
| `editor-linkedin`           | DRAFT                             | `<content-brain>/drafts/linkedin/`                          |
| `editor-shorts`             | DRAFT                             | `<content-brain>/drafts/shorts/` (Instagram/Reels map here) |
| `editor-newsletter`         | DRAFT                             | `<content-brain>/drafts/newsletter/`                        |
| `qa-content`                | QA_SERIAL                         | Dedup + QA                                        |
| `vp-brand`, `ciso-content`  | BRAND_COMPLIANCE (parallel reads) | Brand + legal/safety                              |
| `archivist`, `kb-librarian` | PUBLISH                           | Ledger, `<content-brain>/published/`, metadata              |
| `repurposer`                | REPURPOSE                         | `<content-brain>/repurposed/`                               |

Authoritative table: `agents/internal/_index.md`. **`<content-brain>`** = **`~/ai-brain/projects/<project_name>/`** after **`rules/project-identity.md`** (git remote or folder name — Cursor **`kb-identity`** parity).

## Phase DAG (orchestration)

Execute the DAG in **`rules/orchestration.md`**: maximise parallel draft fan-out; serial QA; parallel brand + compliance; append audit on `phase_enter`, `phase_exit`, `handoff`.

Phase ids: `INTAKE` → `TOPIC_DECISION` → `RESEARCH` → `BRIEF` → `DRAFT` (per channel) → `QA_SERIAL` → `BRAND_COMPLIANCE` → `AWAITING_USER` → `PUBLISH` → `REPURPOSE`.

- **Topic discovery:** If `action:start` has no `source_idea` and no `brief_path`, choose topic from metrics + recent state, then continue (see `rules/cco-single-invocation.md`).
- **Channel aliases:** `instagram` / `reels` → internal `editor-shorts`.

## `cco` load order (mandatory)

1. `rules/repo-hygiene.md`
2. `rules/project-identity.md`
3. `skills/project-identity/SKILL.md`
4. `rules/brain-paths.md`
5. `rules/brain-conventions.md`
6. `rules/docs-and-knowledge.md`
7. `rules/agent-orchestration.md`
8. `rules/strict-tool-boundaries.md`
9. `rules/vp-research.md`
10. `rules/mode-auto-selection.md`
11. `rules/git-safety.md`
12. `rules/subagent-response-protocol.md`
13. `rules/orchestration.md`
14. `rules/cco-single-invocation.md`
15. `rules/inter-persona-observability.md`
16. `rules/n8n-handoff.md`
17. `skills/cco-orchestration/SKILL.md`
18. `skills/caveman/SKILL.md`
19. `skills/subagent-observability/SKILL.md`
20. Internal persona bodies from `agents/internal/*.md` when their phase runs.

Additional ported policies (**`docs-and-decisions.md`**, **`trusted-edit-zones.md`**, **`error-handling-and-security.md`**, **`mcp-usage.md`**, **`testing.md`**, **`observability.md`**) apply when the brief touches docs writes, trusted zones, MCP, or telemetry — load when relevant if context window allows.

## METRICS_READ

Before **BRIEF**: read `<content-brain>/analytics/metrics-current.json` and `metrics-latest.md`; append **`metrics_snapshot_read`** to `~/.gemini/memory/observability/events.jsonl` (and optional per-run log). Repeat before **DRAFT** on `continue` / `revise` or long wall-clock gaps per orchestration. Only **`metrics-steward`** writes `analytics/metrics-*` and related history files.

## Handoffs and reporting

- **Internal persona → persona:** `skills/caveman/SKILL.md` — default **`ultra`**; use normal clarity for security/compliance-sensitive content (see caveman skill).
- **Structured handoff envelope:** `rules/subagent-response-protocol.md` (single fenced YAML where applicable).
- **Automation / n8n:** outbound **`CcoRunReport`** JSON only — **no** caveman in machine JSON or user approval UI. Inbound shapes: `event-schemas/CcoInvokeRequest.json`, actions `start` | `continue` | `revise` | `abort`. Human-readable `summary` inside reports = normal prose.

## KB, brain, observability

- Path rules: **`rules/brain-paths.md`** + **`rules/brain-conventions.md`** + **`rules/docs-and-knowledge.md`**.
- Dedup and platform rules: `rules/dedup.md`, `rules/platform-engagement.md`, `rules/brand-voice.md`, `rules/metrics-contract.md` as relevant.
- Append-only audit: `~/.gemini/memory/observability/events.jsonl`; schema `~/.gemini/memory/_schema/observability-event.schema.md` when present.
- Pipeline state / failures: `~/.gemini/memory/pipelines/` (FSM, runs ledger, `failures/`).

## Content writes

Prefer normal editor tools. Do not use shell heredocs to author structured content unless a rule explicitly allows. **`metrics-steward`** alone writes analytics artefacts under `<content-brain>/analytics/metrics-*`.

## Parity with `cursor-content-team`

- **Canonical pack:** `dotfiles/ai/cursor-content-team/` — authoritative editorial behaviors ported here as **`rules/*.md`**, **`skills/`**, **`agents/`**, **`contracts/`**.
- **Exclusions:** documented in **`docs/runbooks/cursor-only-exclusions.md`** where the IDE or Cursor hooks have no Gemini twin.
- **Repo-local dual config:** content repos may carry **both** `.cursor/` and `.gemini/` (example: **`content-foundry`** vault) — same policies; **separate** `docs/` trees per client.
- **Brain:** single **`~/ai-brain/`** contract — critic ledgers under **`~/ai-brain/session/gemini-<task-id>/critic-ledger.md`** for Gemini editorial critic episodes (**`cursor-<task-id>`** reserved for Cursor-only flows).
- **Docs audit roots:** Gemini outputs **`~/.gemini/docs/**`** and **`…/.gemini/docs/`** only — never Cursor paths.

## Gemini CLI coexistence

Gemini CLI may also own `~/.gemini/settings.json`, `extensions/`, OAuth material. This tree uses **`agents/`**, **`rules/`**, **`skills/`**, **`templates/`**, **`scripts/`** — avoid colliding names with unrelated extensions.

## Context budget

- Internal personas are logical phases inside one `cco` run; keep orchestration state in repo files and compact run summaries rather than replaying full prior model turns.
- Deactivate skills you no longer need in long sessions.

## Publishing and failures

- Do not publish before FSM **`awaiting_user`** and approved **`continue`** unless a documented disaster override applies.
- On fatal errors: `~/.gemini/memory/pipelines/failures/<run_id>-<ts>.md`, FSM `failed`, `cco.run.failed`. Commit durable brain changes via normal git if your tree is versioned.
