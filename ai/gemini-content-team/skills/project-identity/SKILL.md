---
name: project-identity
description: Derive ai-brain project name and KB path from git remote or folder name — same algorithm as Cursor kb-identity (worktree-safe). Use before resolving content-brain paths.
---

# project-identity (Gemini)

**Parity:** Same resolution as Cursor **`~/.cursor/skills/kb-identity/SKILL.md`** (after DotMate stow) → durable path **`~/ai-brain/projects/<project_name>/`**. Keep algorithm aligned if you edit either skill.

## Inputs

- **`project_root`:** absolute path to the working copy (git repo root, worktree checkout, or non-git folder).

## Outputs (conceptual)

- **`project_name`:** lowercase slug (from `origin` URL last segment or directory basename).
- **`content_brain` / `kb_path`:** `~/ai-brain/projects/<project_name>/` with `~` expanded to `$HOME`.

## Algorithm (summary)

### 1) Locate git config

- If **`project_root/.git`** is a **directory** → read **`project_root/.git/config`**.
- If **`project_root/.git`** is a **file** (worktree) → parse `gitdir:` line → find main repo’s **`.git/config`** (path up to and including `.git` before `/worktrees/`) and read that config.

### 2) `remote_url`

- Parse INI: **`[remote "origin"]`** → **`url = ...`**
- If missing → **`derived_from = folder_name`**

### 3) `project_name`

- If **`remote_url`** set → last path segment of repo path, strip **`.git`**, **lowercase** (HTTPS, `git@host:`, `ssh://` — same rules as **`kb-identity`**).
- Else → **`basename(project_root).toLowerCase()`**

### 4) KB path

```
content_brain = $HOME/ai-brain/projects/<project_name>/
```

Use **`project_name`** only (not `full_identity` hash) for the directory name — matches **`kb-identity`** Step 5 / `kb_path`.

### 5) Errors

- No **`.git`** at **`project_root`:** still allow **`project_name = basename(project_root)`** for non-git folders (optional: treat as `not_git_repo` if policy forbids — default **allow** folder fallback).

## Overrides (env, already applied before this skill)

Handled in **`rules/brain-paths.md`** / **`rules/project-identity.md`**:

- **`GEMINI_CONTENT_BRAIN`** — absolute path bypasses derivation.
- **`GEMINI_PROJECT_ROOT`** — forces **`project_root`** for derivation.

## Caching

Agents may cache **`(project_root → content_brain)`** for the invocation; invalidate if **`project_root`** or **`origin`** changes.
