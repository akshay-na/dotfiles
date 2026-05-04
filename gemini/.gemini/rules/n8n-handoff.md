# n8n handoff contract (summary)

Full payload tables live in `~/content-knowledge-base/integrations/n8n/webhook-contract.md` and JSON Schemas under `integrations/n8n/event-schemas/`.

## Git (no LaunchAgent)

Orchestration should run **`git pull`** on `~/content-knowledge-base` immediately before invoking **`cco`** / **`metrics-steward`**, and **`bash ~/.gemini/scripts/kb-sync.sh sync`** after the model step completes (diff-driven commit inside `kb-sync`). Same pattern if n8n uses Execute Command around Gemini CLI.

## Hard rule

**n8n never calls internal personas** (`agents/internal/*`). HTTP / CLI entrypoints for Gemini work are only:

- **`cco`** — pipeline (`action`: `start` | `continue` | `revise` | `abort`).
- **`metrics-steward`** — metrics ingest (manual JSON body).

## HMAC

Header `X-Gemini-KB-Signature` (secret in Keychain `n8n-webhook-secret`; optional second secret for metrics route). Implementations must constant-time compare.

## Outbound events (canonical)

- `cco.run.started`, `cco.run.progress` (optional), `cco.run.awaiting_user` (carries **`CcoRunReport`** — human gate),
- `cco.run.completed`, `cco.run.failed`, `cco.run.revision_applied`,
- `metrics.updated` after successful **`metrics-steward`** (`metrics_path`, `summary`, optional `channels_delta`).

## Human gate

`cco.run.awaiting_user` carries stable JSON only — n8n must not parse free-form model prose for routing.
