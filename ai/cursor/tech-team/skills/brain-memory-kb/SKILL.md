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
  - set memory source pointer/superseded state
- `demote` mode:
  - load policy from `~/ai-brain/org/global/config/memory-demotion.yml` (`contract_version`)
  - supersede / demote / quarantine per `lifecycle_states` and `demotion.triggers`
  - **Until G2 brain-audit e2e join passes:** demote is **advisory-only** (record intent via `log_brain_event`; no `lifecycle_state` disk writes except human-approved runs)
  - after contract live: patch frontmatter, append `demoted.index.jsonl`, update L1 `_index.md`

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

## Demotion operations

1. Read policy YAML (stowed from `dotfiles/ai/ai-brain/org/global/config/`).
2. Validate promotion deny-list before any `promote`.
3. On demote: set `lifecycle_state`, `retrieval_weight`, `demoted_at`, `demotion_reason`; append `.meta/demoted.index.jsonl`; never hard-delete.
4. Emit `kb_demote` via `agent-observability` → `log_brain_event`.
5. **stale_trap:** after `stale_trap.failures_per_task_id` distinct failures, set `session/<task-id>/flags.yaml` → `fresh_eyes: true`; coordinator may `clear_stale_trap`.

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
