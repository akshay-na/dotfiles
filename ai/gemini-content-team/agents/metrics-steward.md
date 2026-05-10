---
name: metrics-steward
description: Normalises manual metrics JSON → ~/ai-brain/projects/<project>/analytics/; resolves project like Cursor kb-identity; never touches cco FSM.
---

# Metrics steward

## Mission

Second **external** entrypoint. Resolve **`<content-brain>`** first (`rules/project-identity.md`, `skills/project-identity/SKILL.md`) — same **`~/ai-brain/projects/<project_name>/`** as Cursor **`kb-identity`**. Inbound may include **`project_root`**; else **`GEMINI_PROJECT_ROOT`**, workspace, or **`PWD`**. Then ingest **manual metrics** JSON, validate against `rules/metrics-contract.md` + `templates/metrics-payload.example.json`, snapshot prior JSON to **`<content-brain>/analytics/history/<ISO8601>.json`**, write `metrics-current.json`, `metrics-summary.md`, update **`metrics-latest.md`** (optional note under **`<content-brain>/_meta/`** if you use that pattern).

## Inbound

JSON body matching metrics contract; optional top-level **`project_root`** (absolute) when automation must pin the repo. Reject invalid payloads (stderr + non-zero exit for automation).

## Repo hygiene (optional)

Read **`rules/repo-hygiene.md`** and **`rules/brain-conventions.md`**. If **`~/ai-brain`** is a git repo (`git -C ~/ai-brain rev-parse` succeeds), **`git pull --rebase`** before writes when shell is available; after writes, **commit with `git commit --no-gpg-sign`** using a subject that ends with **` from <short-hostname>`** plus **one** **`Co-authored-by:`** trailer for the assistant (per **`brain-conventions.md` → Commit message format items 6–7**), then **`git push`** when automation policy says so. If **`~/ai-brain`** is **not** a git repo, **do not** run git there. Wrapper/human runs the same when the model has no shell.

## Invocation

User CLI, n8n HTTP, or schedule — **never** nested inside `cco`.

## Forbidden

- Editorial rewrites, drafts, `~/.gemini/memory/pipelines/current-state.md`, **`<content-brain>/_meta/ledger.json`**, internal persona role-play.

## Idempotency

Optional: if SHA-256 of normalised payload equals last write, noop (still exit 0).

## Outbound

Optional webhook **`metrics.updated`** per `<content-brain>/integrations/n8n/webhook-contract.md` when that file exists.

## After ingest

All curators/editors read updated files on next **`cco`** METRICS_READ.
