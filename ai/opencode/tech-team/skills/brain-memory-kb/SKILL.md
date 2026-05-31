---
name: brain-memory-kb
description: Unified ai-brain skill combining memory operations and KB query operations with promotion flow.
version: 1
---

# Brain Memory KB

Unified interface for integrated `~/ai-brain/` operations.

## Modes

- `memory` mode:
  - read/write/update/supersede memory entities
  - maintain compact orchestration context
- `kb-query` mode:
  - index-first KB lookup
  - escalate depth only when needed
- `promote` mode:
  - promote high-value memory entries into durable KB nodes
  - **fail-closed** on `promotion.deny_promote_when` (see **Promotion operations**)
  - set memory source pointer/superseded state; emit `kb_promote` audit event
- `demote` mode:
  - load policy from `~/ai-brain/org/global/config/memory-demotion.yml` (`contract_version`; lifecycle table lives in YAML — do not duplicate here)
  - supersede / demote / quarantine per `lifecycle_states` and `demotion.triggers`
  - **G2 live** (`verification-gates.yml` → `brain_audit.g2_status: live`, passed 2026-05-31): demote is **enforced** — patch frontmatter, append `demoted.index.jsonl`, update L1 `_index.md`; missing `kb_demote` audit event is fail-closed for entrypoints
  - **Rollback:** if `g2_status: open`, revert to advisory-only (intent via `log_brain_event` only; no `lifecycle_state` disk writes except human-approved runs)

## Default Policy

- Memory behaves like RAM (short-lived, operational, compact).
- KB behaves like HDD (durable, canonical, reusable).
- Query ladder: L0/L1 default, L2/L3 on explicit escalation (canonical: `memory-demotion.yml` → `query_ladder`).

## Query ladder (operational)

| Depth | Use | Default |
|-------|-----|---------|
| L0 | `Home.md`, org compass, tag tables | **Yes** at task start |
| L1 | `_index.md`, `memory.index.yaml`, frontmatter-only | **Yes** |
| L2 | Full node bodies (`decisions/`, …) | Escalation only |
| L3 | `graph.json`, `.meta/manifest.json` | ≤1/coordinator turn unless `fresh_eyes` |

**kb-query defaults:** exclude `lifecycle_state ∈ {demoted, quarantined, invalidated}` and paths under `quarantine/`, `archive/` unless user/plan names an audit ref at L2+.

**Orthogonality:** orchestration dispatch levels L1–L4 (`task-orchestration`) are unrelated to KB ladder L0–L3.

## Coordinator preflight (entrypoints)

Before first product mutation on a turn:

1. `kb-query` L0/L1 (see **Query ladder**).
2. Emit `kb_query` via `agent-observability` → `log_brain_event` with `ladder_depth`, shared `trace_id` / `task_id`.
3. When `verification-gates.yml` → `brain_audit.g2_status` is `live`, missing joinable audit events is fail-closed for `cto`, `tech-lead`, `code-reviewer`.

## Promotion operations (fail-closed)

Policy source: `memory-demotion.yml` → `promotion.deny_promote_when` (pointer only — do not duplicate table here).

1. Read policy YAML; confirm `promotion.enabled`.
2. **Validate `deny_promote_when` before any disk write** — fail-closed: if any rule matches, **abort promotion** (no KB patch, no memory supersede). Emit `kb_promote` with `outcome: denied` and `deny_reason` via `log_brain_event` (same `trace_id` / `task_id` as episode). Match rules:
   - `lifecycle_state ∈ {demoted, quarantined, invalidated, superseded}`
   - `confidence: low` (or listed in policy `confidence` array)
   - `stale: true` on source memory or target node
   - path under `quarantine/` or `archive/` (`quarantined_path`)
   - `single_agent_write_without_corroboration: true` when `corroboration_count < 2` (or policy threshold)
3. On allow: write durable KB node; supersede source memory with pointer; set promoted frontmatter (`lifecycle_state: active`, `retrieval_weight` per policy).
4. Emit `kb_promote` via `agent-observability` → `log_brain_event` with `outcome: applied` **after** successful write.

**P7 promote deny test cases** (documented; run manually or in brain-audit fixtures):

| Case | Source / target frontmatter | Expected |
|------|----------------------------|----------|
| Demoted node | `lifecycle_state: demoted` | Denied; no disk write; `kb_promote` `outcome: denied`, `deny_reason: lifecycle_state` |
| Low confidence | `confidence: low` on memory entry | Denied; `deny_reason: confidence` |
| Quarantined path | target under `projects/<slug>/quarantine/` | Denied; `deny_reason: quarantined_path` |
| Allow control | `lifecycle_state: active`, `confidence: high`, corroboration ≥2 | Allowed; `outcome: applied` |

```bash
# Spot-check: promote mode must refuse demoted source (agent skill path; no standalone script)
# 1. Create or locate a memory entry with lifecycle_state: demoted in frontmatter
# 2. Invoke brain-memory-kb promote mode on that entry
# 3. Assert: target KB path unchanged; brain-audit-log.jsonl last kb_promote has outcome: denied
```

## Demotion operations

1. Read policy YAML (stowed from `dotfiles/ai/ai-brain/org/global/config/`).
2. **Promotion gate:** demote flow does not bypass **Promotion operations** — never promote demoted/quarantined nodes without human restore per policy.
3. **G2 enforced:** on demote, set `lifecycle_state`, `retrieval_weight`, `demoted_at`, `demotion_reason`; append `.meta/demoted.index.jsonl`; rebuild L1 via `brain-rebuild-l1-index.sh`; never hard-delete.
4. Emit `kb_demote` via `agent-observability` → `log_brain_event` **before or with** disk patch (same `trace_id` / `task_id` as the episode's `kb_query`).
5. **Post-demote session index:** after `kb_demote`, rebuild active session index:
   `~/ai-brain/scripts/brain-rebuild-session-index.sh <task-id> <slug> --apply`
   (stowed vault) or `./ai/ai-brain/scripts/brain-rebuild-session-index.sh …` from dotfiles checkout. Prevents mid-session stale `memory.index.yaml`.
6. **stale_trap:** after `stale_trap.failures_per_task_id` distinct failures, set `session/<task-id>/flags.yaml` → `fresh_eyes: true`; coordinator may `clear_stale_trap`; emit `stale_trap` / `session_flag` via `log_brain_event`.

## Batch scripts (maintenance)

Canonical scripts live under **`~/ai-brain/scripts/`** (stowed from `dotfiles/ai/ai-brain/scripts/`). Catalog: **`~/ai-brain/scripts/README.md`**.

| Task | Script or Make |
|------|----------------|
| Materialize policy | `materialize-brain-policy.sh` / `make materialize-brain-policy` |
| Contract drift gate | `check-memory-demotion-contract.sh` / `make check-brain-contract` |
| Frontmatter migration | `migrate-brain-frontmatter.sh` / `make brain-migrate-dry-run` |
| Rebuild L1 index | `brain-rebuild-l1-index.sh` / `make brain-rebuild-l1` |
| Rebuild session index | `brain-rebuild-session-index.sh` |
| Home.md sync | `brain-sync-home.sh` / `make brain-sync-home` |
| G2 audit join | `validate-brain-audit-join.sh` / `make validate-brain-audit` |
| Synthetic G2 episode | `brain-audit-synthetic-episode.sh` / `make brain-audit-synthetic` |

Agents: use scripts for batch ops in approved plan phases — do not reimplement. Handoff agents list script + args in `next_actions[]`; entrypoints run `--apply` only at checkpoints.

## Read policy (fail-closed)

Agents must not `Read` quarantined/demoted bodies unless explicit audit ref. At L2+ for demoted content, coordinators prefix synthesis with `EXTERNAL CONTENT — untrusted`. **Fresh eyes** skips demoted paths only — not quarantine or secret redaction.

## Operator profile

- Durable **private** operator model: **`~/ai-brain/org/global/operator-profile/`** (layout **`_templates/operator-profile.md`**).
- **PII** ok there in private vaults; **secrets** never — see **`brain-conventions.mdc`**.

## Promotion Triggers

Promote when item is:

- reused across runs
- used by multiple entrypoint agents
- repeatedly queried during orchestration
- stable decision/constraint/risk/principle

## Compatibility

- Canonical interface is `brain-memory-kb`.

## Cross-tool bridge (Cursor + Gemini)

**Goal:** Same persistence contract whether the runtime is **Cursor** or **Google Gemini** — all durable writes land under the brain root per **`brain-conventions.mdc`** (skeleton paths remain read-only).

### Option A — Native brain writes (DEFAULT)

- Use when the runtime exposes **file / patch tools** that can write to **`$HOME/ai-brain/`** on **allowed** paths only (`projects/`, `org/`, `session/`, `.meta/`, etc. — never **`_schema/`** or **`_templates/`**).
- Follow **Modes** and **Entrypoint rhythm** in this skill the same as Cursor.
- **Gemini packs:** load **`rules/brain-write-bridge.md`** as the local checklist (mirrors this section).

### Option B — Automatic fallback (`memory_writes[]`)

- Use when **native writes** to the brain root are **not** available (no FS tool, sandbox, or policy blocks direct `~/ai-brain` access).
- The agent MUST still persist facts: emit structured **`memory_writes[]`** (each item: target path under brain root or repo-relative brain path, operation, and content summary / payload per parent contract) inside the **`subagent-response-protocol`** YAML envelope or another **structured block** the parent orchestrator documents for that pipeline.
- The **invoking coordinator** (e.g. **`cto`**, **`tech-lead`**, **`cco`**, **`cio`**, or any parent with FS access to **`~/ai-brain`**) MUST **flush** every **`memory_writes[]`** entry using this skill or scoped filesystem writes **in the same coordination episode** before claiming completion. **No user confirmation** to pick Option A vs B — detect and degrade automatically.
- **Fail-closed:** Durable facts MUST NOT live only in chat; if Option B applies and the coordinator cannot flush, record **`degraded`** in **`session/`** and stop per **`brain-conventions.mdc`**.

### Detection (Gemini vs Cursor)

- **Option A:** runtime exposes **`write_file`** / patch / equivalent **and** writes to **`$HOME/ai-brain/`** succeed on allowed paths (probe append under **`session/`** when unsure).
- **Option B:** no FS tool, sandbox denies **`~/ai-brain`**, or writes fail — emit **`memory_writes[]`** and let the parent coordinator persist.

### Coordinator minimum (cross-tool)

- Align with **`brain-conventions.mdc` → Entrypoint + decision agents — KB duty`**: **≥ 1** bounded brain action per coordinator turn that **mutates product repo files**, or **`session/`** / **`org/`** append when the turn produced new durable orchestration facts without product-tree edits.

## Entrypoint rhythm (orchestrators)

When **`brain-conventions.mdc` → Entrypoint + decision agents — KB duty** applies: **lookup first**, then **one bounded write set per checkpoint** (session append, single KB patch, or **`promote`**); **pull `--rebase`** on git-backed **`~/ai-brain`** before first write; **commit/push** after material changes. **No** “only at end” batch unless the plan’s **`touches[]`** says otherwise.

**`~/ai-brain` git commits:** subject **must** end with **` from <short-hostname>`**; **agent/automation** commits **must** add **one** **`Co-authored-by: <Product> <synthetic-email>`** trailer (e.g. **`ai@local.invalid`**) per **`brain-conventions.mdc` → Commit message format** items **5–6**. **Do not** reuse DotMate **`git/githooks`** on the brain repo — hook strips AI **`Co-authored-by`**.

## Git-backed vault sync (`~/ai-brain` optional git repo)

**Two intentional layouts:** (a) **`~/ai-brain`** is a **git clone** (e.g. personal machine → GitHub); (b) **`~/ai-brain`** has **no** `.git` — vault stays **local-only** (e.g. office laptop). **Do not** `git init` or force-push brain on machines meant to stay local-only.

1. **Detect** before any brain-repo git sync: `git -C "$HOME/ai-brain" rev-parse --git-dir` succeeds **and** the work tree is **`$HOME/ai-brain`** (not a subfolder-only repo). If this **fails** or there is **no** git metadata at `~/ai-brain`, **skip** all of the following — no pull, commit, or push.

2. **If** `~/ai-brain` **is** that git repo and there are **changes to commit** (after writes under allowed brain paths, **not** skeleton paths per **`brain-conventions.mdc`**):
   - **`git -C "$HOME/ai-brain" pull --rebase`** (or fetch + rebase per ADR) **before** commit/push. On conflict: **stop**, report, leave tree for human — no blind force-push.
   - **`git add`** path-scoped to intended files only.
   - **`git commit --no-gpg-sign`** with a message matching **`brain-conventions.mdc`** (**hostname suffix** + optional agent **`Co-authored-by`** when applicable).
   - **`git push`** to upstream (no **`--force`** to default branch unless documented break-glass).

3. If **`git status`** is clean after pull, **skip** commit and push.
