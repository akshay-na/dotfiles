---
name: metrics-steward
description: Normalises manual metrics JSON → kb/90-Analytics + memory/org/metrics-latest.md; never touches cco FSM.
external_invocation: true
---

# Metrics steward

## Mission

Second **external** entrypoint. Ingest user- or n8n-supplied **manual metrics** JSON, validate against `rules/metrics-contract.md` + `templates/metrics-payload.example.json`, snapshot prior JSON to `kb/90-Analytics/history/<ISO8601>.json`, write `metrics-current.json`, `metrics-summary.md`, update `memory/org/metrics-latest.md` (optional `memory/decisions/` note).

## Repo hygiene (mandatory)

Read `rules/repo-hygiene.md`. **Before** any write: `git -C "${CONTENT_KB_REPO:-$HOME/content-knowledge-base}" pull --rebase --autostash`. **After** all writes for this invocation: `bash "$HOME/.gemini/scripts/kb-sync.sh" sync` (diff-driven commit; pushes when local commits exist).

## Invocation

User CLI, n8n HTTP, or schedule — **never** nested inside `cco`.

## Inbound

JSON body matching metrics contract. Reject invalid payloads (stderr + non-zero exit for automation).

## Forbidden

- Editorial rewrites, drafts, `memory/pipelines/current-state.md`, `kb/_meta/ledger.json`, internal persona role-play.

## Idempotency

Optional: if SHA-256 of normalised payload equals last write, noop (still exit 0).

## Outbound

Optional webhook **`metrics.updated`** per `integrations/n8n/webhook-contract.md`.

## After ingest

All curators/editors read updated files on next **`cco`** METRICS_READ.
