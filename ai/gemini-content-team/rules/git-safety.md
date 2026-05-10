# Content git safety

## Allowed commands

`git fetch`, `git pull`, `git rebase`, `git status`, `git diff`, `git add` (path-scoped), `git commit` (template or `--file` pre-built body), `git push` (no `--force` to repo **default branch**).

## Agent commits — GPG signing

See **`brain-conventions.md`**: **DotMate / dotfiles** git root → **OpenPGP sign** (no **`--no-gpg-sign`**). **Content corpus**, **`~/ai-brain`**, and other agent commits in this pack → **`--no-gpg-sign`** (or **`git -c commit.gpgsign=false commit`**) unless a **project ADR** overrides.

## Commit messages (`~/.gitmessage` + Conventional Commits)

- **Subject (first line):** **`type[(optional-scope)]: imperative summary`** — Conventional Commits; **≤ ~72 characters**; **no trailing period**; imperative mood (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `perf`, `style`, …). **Vault / corpus:** for stage-primary work, prefer **`draft`**, **`staging`**, **`published`** as **`type`** (see **`brain-conventions.md`**).
- **Body:** same **section order** as **`$HOME/.gitmessage`** (DotMate `git/.gitmessage` when stowed). **Keep it short:** at most **2–3** bullets; **`Context:`** and **`Impact:`** **one line each** unless unavoidable; no long narratives.
- **`Notes:`** — optional **brief** operational refs (e.g. `Task-ID`, ticket keys) only.
- **Forbidden:** **`Co-authored-by:`** for AI/IDE/bots, **`AI-authored`**, **`Generated-by:`**, “written by AI”, or vendor tool credit in the message body or trailers — **except** **one** AI **`Co-authored-by`** on **git-backed `~/ai-brain`** agent commits per **`brain-conventions.md` → Commit message format item 7**.

## Forbidden

- `git push --force` to **`main`**/default without documented break-glass.  
- Committing **secrets**, tokens, `.env`, SSH private keys.  
- `git add -A` when `target_paths[]` / policy forbids broad adds.

## Conflicts

On pull/rebase conflict: **stop**; return structured error to orchestrator / n8n; do not silent-resolve.
