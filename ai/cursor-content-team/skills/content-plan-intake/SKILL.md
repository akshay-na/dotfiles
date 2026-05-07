---
name: content-plan-intake
description: Mandatory planner intake — brain-memory-kb + kb-query, repo/workdir corpus scan, merge into brief for CCO plans.
version: 1
---

# content-plan-intake

## When

Every **`cco`** planning pass (and deep read before **`content-lead`** execution when plan says “re-scan corpus”).

## Steps

1. **Project identity** — [`kb-identity`](../kb-identity/SKILL.md) / workspace root / `project_root` from payload. Treat this root as **`<project>`** for **plan output**: **`cco`** must write plans under `<project>/.cursor/docs/plans/` only. If the workspace also includes **`~/.cursor`** opened as a project folder, or **org-pack source** checkouts for editing the pack itself, **do not** choose those as `<project>` for content plans unless the brief is explicitly about editing that pack.
2. **Memory + KB** — [`brain-memory-kb`](../brain-memory-kb/SKILL.md): `mode: memory` for constraints; `mode: kb-query` for structured overview when available.
3. **Repo / workdir** (mandatory):
   - Directory layout: `drafts/`, `published/`, `topics/`, `briefs/`, `_meta/`, `brand/` (adapt to repo).
   - Indices: slug maps, frontmatter conventions.
   - Bounded **`git log`/`git diff`** for recency (token cap per project rule).
4. **Merge** into a short **corpus digest** in the plan: what exists, what to avoid duplicating, voice/brand pointers.

## Output

Structured bullet block **`## Corpus digest`** (or equivalent) inside the plan file or scratch artifact reference — never skip repo scan when git checkout is the source of truth.
