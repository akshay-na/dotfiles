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

- **`~/ai-brain/org/global/operator-profile/`** — see **`_templates/operator-profile.md`**; **PII** vs **secrets** per **`brain-conventions.mdc`**.

## Promotion Triggers

Promote when item is:

- reused across runs
- used by multiple entrypoint agents
- repeatedly queried during orchestration
- stable decision/constraint/risk/principle

## Compatibility

- Canonical interface is `brain-memory-kb`.

## Entrypoint rhythm (orchestrators)

When **`brain-conventions.mdc` → Entrypoint + decision agents — KB duty** applies: **lookup first**, then **one bounded write per checkpoint**; **git pull --rebase** on the brain clone **before** first write; **commit/push** per signing rules after. See **`kb-identity`** / **`project-identity`** for **per-repo** **`projects/<slug>/`**.

**`~/ai-brain` git commits:** subject **` from <short-hostname>`** + **agent** **one** **`Co-authored-by:`** trailer per **`brain-conventions.mdc`** items **6–7**; **`hostname -s`** (or fallbacks). **No** DotMate **`commit-msg`** hook on brain clone.

## Git-backed vault sync (`~/ai-brain` optional git repo)

**Layouts:** (a) **`~/ai-brain`** is a **git clone**; (b) **no** `.git` — local-only vault. **Do not** `git init` on machines meant to stay local-only. If the git root is **`~/.cursor/ai-brain`**, use that path in **`-C`** instead of **`$HOME/ai-brain`** per **`brain-conventions.mdc`**.

1. **Detect:** `git -C "$HOME/ai-brain" rev-parse --git-dir` (or `~/.cursor/ai-brain`) succeeds and work tree matches that root. Else **skip** sync.

2. **If** repo + changes under **allowed** paths (not skeleton): **`pull --rebase`** → path-scoped **`add`** → **`git commit --no-gpg-sign`** (message per **`brain-conventions.mdc`**) → **`push`** (no **`--force`** to default branch unless break-glass).

3. Clean after pull → **skip** commit/push.
