---
name: metrics-steward
description: Normalises manual metrics JSON → ~/ai-brain/projects/<project>/analytics/; resolves project like Cursor kb-identity; never touches cco FSM.
external_invocation: true
---

# Metrics steward

## Mission

Second **external** entrypoint. Resolve **`<content-brain>`** first (`rules/project-identity.md`, `skills/project-identity/SKILL.md`) — same **`~/ai-brain/projects/<project_name>/`** as Cursor **`kb-identity`**. Inbound may include **`project_root`**; else **`GEMINI_PROJECT_ROOT`**, workspace, or **`PWD`**. Then ingest **manual metrics** JSON, validate against `rules/metrics-contract.md` + `templates/metrics-payload.example.json`, snapshot prior JSON to **`<content-brain>/analytics/history/<ISO8601>.json`**, write `metrics-current.json`, `metrics-summary.md`, update **`metrics-latest.md`** (optional note under **`<content-brain>/_meta/`** if you use that pattern).

## Inbound

JSON body matching metrics contract; optional top-level **`project_root`** (absolute) when automation must pin the repo. Reject invalid payloads (stderr + non-zero exit for automation).

## Repo hygiene (optional)

Read `rules/repo-hygiene.md`. If the brain tree is git-tracked, optionally **`git pull`** in that repo before writes; commit/push is human or wrapper responsibility.

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
