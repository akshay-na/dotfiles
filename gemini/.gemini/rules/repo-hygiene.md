# Repo hygiene — every external agent run (`cco`, `metrics-steward`)

No LaunchAgent: **Git pull and kb-sync are part of each agent invocation** (human runs commands in the same environment as Gemini, or n8n runs them before/after the model step).

## Content repo

Default: `CONTENT_KB_REPO` → `~/content-knowledge-base`.

## 1) Start of run (before reads/writes)

From any cwd:

```bash
git -C "${CONTENT_KB_REPO:-$HOME/content-knowledge-base}" pull --rebase --autostash
```

On unresolvable conflict: stop the run, emit failure webhook / stderr, leave working tree for human (see `runbooks/disaster-recovery.md`).

## 2) End of run (after all KB/memory writes for this invocation)

```bash
bash "${HOME}/.gemini/scripts/kb-sync.sh" sync
```

`kb-sync.sh sync` already: acquires lock → `pull` (again, safe noop if up to date) → stages per policy → **commits only if the index has changes** → `push`. So commits are **diff-driven**; no empty commit.

If the run made **no** file changes since last push, you still get a quick pull + empty staging + push (fast-forward no-op on remote).

## 3) `metrics-steward`

Same **(1)** then ingest metrics then **(2)**.

## 4) `cco` internal phases

`cco` runs **(1)** once at the very beginning of the outer run and **(2)** once after terminal success (`completed` / `failed`) or after a safe pause boundary if your transport requires mid-run sync — default contract: **sync at end of each `cco` HTTP/CLI invocation** (one pull at start, one `kb-sync.sh sync` at end).
