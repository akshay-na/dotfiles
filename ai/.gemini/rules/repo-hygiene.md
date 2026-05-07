# Repo hygiene — workspace git (optional)

There is **no** separate content KB repository or kb-sync script. Durable pipeline files live under **`<content-brain>`** = **`~/ai-brain/projects/<project_name>/`** (see `rules/project-identity.md`, `rules/content-brain-paths.md`).

## When the workspace is a git repo

If **`cco`** or **`metrics-steward`** runs with an open workspace that is a git checkout (for example the repo you use to version `~/ai-brain` or a project that tracks marketing assets):

1. **Start (optional):** `git pull --rebase --autostash` in **that** workspace root when you need an up-to-date tree before reads/writes.
2. **End:** commit and push **normal** git workflow yourself — agents write files only; they do not run automated sync scripts.

If the model runtime cannot run shell, the human or n8n wrapper may run the same git commands for the **active** repo.

## n8n / headless

Same rule: any `git pull` / commit / push targets the **workspace** or the repo where ai-brain (or content project) files are tracked — not a hard-coded second repo.

## Conflicts

On merge conflicts, stop the run, surface stderr, leave the tree for a human (`rules/orchestration.md` failure classes).
