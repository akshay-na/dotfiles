# Conventions — Gemini content pipeline + content-knowledge-base

Canonical names for scripts, paths, and automation. Phases P1–P6 of the architecture plan reference this file.

## Paths

| Symbol | Path |
|--------|------|
| Capability root | `~/.gemini/` (stowed from `dotfiles/gemini/.gemini/`) |
| Content repo | `~/content-knowledge-base/` (`CONTENT_KB_REPO` overrides) |
| Vault | `~/.gemini/kb` → `~/content-knowledge-base/kb/` |
| Memory | `~/.gemini/memory` → `~/content-knowledge-base/memory/` |
| Docs | `~/.gemini/docs` → `~/content-knowledge-base/docs/` |
| Runbooks | `~/.gemini/runbooks` → `~/content-knowledge-base/runbooks/` |
| Pipeline-state skill (repo-backed) | `~/.gemini/skills/pipeline-state` → `~/content-knowledge-base/docs/skills/pipeline-state/` |

## Git remote

`git@github.com:akshay-na/content-knowledge-base.git`  
Optional SSH host alias after deploy-key bootstrap: `git@github-content-kb:akshay-na/content-knowledge-base.git`

## Agents

- **External:** `~/.gemini/agents/cco.md`, `~/.gemini/agents/metrics-steward.md` (`external_invocation: true`).
- **Internal:** `~/.gemini/agents/internal/*.md` (`external_invocation: false`), loaded only inside `cco`.

## Rules and skills

- Rules: `~/.gemini/rules/<topic>.md`
- Skills: `~/.gemini/skills/<name>/SKILL.md` except **`pipeline-state`** (symlink to content repo, above).

## Scripts (callable without Make)

| Script | Purpose |
|--------|---------|
| `~/.gemini/scripts/kb-bootstrap.sh` | Clone/init content repo, hooks, symlinks (no vault copy from dotfiles) |
| `~/.gemini/scripts/kb-sync.sh` | `pull` \| `commit` \| `push` \| `sync` \| `status` |
| `~/.gemini/scripts/kb-status.sh` | Human/agent status + staleness exit codes |
| `~/.gemini/scripts/kb-lock.sh` | Bracket multi-file writes with repo lock |
| `~/.gemini/scripts/kb-log.sh` | Structured append to `~/Library/Logs/kb-sync.log` |
| `~/.gemini/scripts/auth/keychain-helper.sh` | Keychain get/set wrappers |
| `~/.gemini/scripts/auth/deploy-key-bootstrap.sh` | SSH deploy key + `github-content-kb` host |

## Git sync (no LaunchAgent)

**`cco`** and **`metrics-steward`** must drive the repo on every run: `git pull` at start, `kb-sync.sh sync` at end (diff-driven commit inside `kb-sync`). See `rules/repo-hygiene.md`.

- **Structured log (rotation):** `~/Library/Logs/kb-sync.log` via `kb-log.sh`

## Idempotency (n8n / HTTP)

- **`run_id`:** UUID per pipeline run.
- **`event_id`:** UUID per outbound webhook emission; duplicates must be safe no-ops or replays per `memory/pipelines/runs/<run_id>.*` ledger.

## Keychain services (examples)

- `gemini-cli` — API material for Gemini CLI (if used).
- `content-kb-deploy-key` — optional metadata pointer (prefer SSH key files).
- `n8n-webhook-secret` — HMAC for inbound/outbound webhooks (`X-Gemini-KB-Signature`).

## Metrics artefacts (write policy)

- **Writers:** `metrics-steward` (primary), optional documented human edit.
- **Readers:** `cco` and all internal curators/editors at **METRICS_READ** gates.
- **Paths:** `kb/90-Analytics/metrics-current.json`, `metrics-summary.md`, `history/*.json`, `memory/org/metrics-latest.md`.

## Observability

- **Append-only NDJSON:** `memory/observability/events.jsonl` (and optional `memory/observability/runs/<run_id>.jsonl`).
- **Schema:** `memory/_schema/observability-event.schema.md`

## Native Gemini CLI files (do not collide)

Gemini CLI may own `~/.gemini/settings.json`, `extensions/`, `oauth_creds.json`, `GEMINI.md`. This package uses parallel trees: `agents/`, `rules/`, `skills/` (except symlinked `pipeline-state`), `templates/`, `scripts/`.
