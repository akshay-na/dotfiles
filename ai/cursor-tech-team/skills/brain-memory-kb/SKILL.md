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

## Default Policy

- Memory behaves like RAM (short-lived, operational, compact).
- KB behaves like HDD (durable, canonical, reusable).
- Query ladder: L0/L1 default, L2/L3 on explicit escalation.

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
