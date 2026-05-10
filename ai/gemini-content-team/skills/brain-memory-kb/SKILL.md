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

- **`~/ai-brain/org/global/operator-profile/`** — see **`_templates/operator-profile.md`**; **PII** vs **secrets** per **`brain-conventions.md`**.

## Promotion Triggers

Promote when item is:

- reused across runs
- used by multiple entrypoint agents
- repeatedly queried during orchestration
- stable decision/constraint/risk/principle

## Compatibility

- Canonical interface is `brain-memory-kb`.

## Entrypoint rhythm (orchestrators)

When **`brain-conventions.md` → Entrypoint + decision agents — KB duty** applies: **lookup first**, **one bounded write per DAG checkpoint**; promote from **`~/.gemini/memory/`** to **`<content-brain>`** / **`~/ai-brain/org/`** as policy says; **git pull --rebase** / **commit** / **push** on a git-backed **`~/ai-brain`** so **origin** stays current.

**`~/ai-brain` git commits:** subject **` from <short-hostname>`** + **agent** **one** **`Co-authored-by:`** trailer per **`brain-conventions.md`** items **6–7**; **`hostname -s`** (or fallbacks). **No** DotMate **`commit-msg`** hook on brain clone.

## Git-backed vault sync (`~/ai-brain` optional git repo)

**Layouts:** git clone vs local-only; **`~/.gemini/ai-brain`** may substitute for **`$HOME/ai-brain`** per **`brain-conventions.md`**.

1. **Detect** git root + work tree match.
2. **If** changes on allowed paths: **`pull --rebase`** → scoped **`add`** / **`commit --no-gpg-sign`** / **`push`**.
3. Clean tree → skip commit/push.
