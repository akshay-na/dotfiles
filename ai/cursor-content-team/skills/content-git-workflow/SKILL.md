---
name: content-git-workflow
description: Git pull, commit (~/.gitmessage), push for content-repo automation. SSH pre-provisioned; fail-closed on conflicts. Emits stages for agent-observability.
version: 1
---

# content-git-workflow

## Preconditions

- `workspace_root` is a **clone** with **SSH** remote (`git@…`) working in the environment.
- Optional payload: `git_branch`, `git_remote`, `commit_template_path` (default `$HOME/.gitmessage`), `pull_before` (default true), `push_after_commit` (default true for `execution_mode: automation`), `task_id`, `idempotency_key`.

## Sequence

1. **`git fetch`** (and **`git pull --rebase`** or merge per project ADR) when `pull_before` — abort with error payload to n8n on **merge conflict** or unexpected dirty tree unless policy allows stash.
2. Content agents **modify** allowed paths only (`target_paths[]` from pipeline).
3. **`git status`/`git diff`** — if no changes, skip commit (log `git.commit_skipped_empty`).
4. **`git add`** path-scoped; **`git commit --no-gpg-sign`** with **`--file`** composed message OR **`--template "$HOME/.gitmessage"`** (human may have global GPG signing; agent commits must not sign — see **`brain-conventions.mdc`**):
   - **Subject:** Conventional Commits — **`type[(optional-scope)]: imperative summary`**, **≤ ~72 chars**, no trailing period, imperative mood. For **content vault** commits, use lifecycle types **`draft`**, **`staging`**, **`published`** when the change is mainly that stage (per **`brain-conventions.mdc`**); otherwise `feat` / `chore` / … as usual.
   - **Body:** same sections as **`~/.gitmessage`** but **brief**: ≤ **2–3** bullets if any; **`Context:`** / **`Impact:`** one short line each by default.
   - **`Notes:`** — **AI block** (`AI-authored: yes`, `Generated-by: …`, `Task-ID: …`, `Workflow: …`) plus optional short caveats.
   - Optional **trailers** after blank line per **`git-safety.mdc`**.
5. **`git push`** to configured upstream; on non-FF → **one** retry with fetch/rebase/push; then fail closed (no `git push --force` to default branch).

## Error codes (for n8n)

Suggest stable strings: `git_pull_conflict`, `git_dirty_tree`, `git_commit_failed`, `git_push_rejected`, `git_ssh_failed`, `template_missing`.

## Idempotency

Same `idempotency_key` + clean tree + no new diff → no second empty commit; log skip observability row.

## Observability

`log_metric` stages: `git.sync`, `git.commit`, `git.push` with `task_id`, `branch`, `commit_sha` when known.
