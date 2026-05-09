# Conventions — Gemini content pipeline + ai-brain

Canonical names for paths and automation. Durable pipeline artefacts live under **`~/ai-brain/projects/<project_name>/`** where **`project_name`** matches Cursor **`kb-identity`** (git `origin` basename or folder name — **`rules/project-identity.md`**, **`skills/project-identity/SKILL.md`**). Override: **`GEMINI_CONTENT_BRAIN`** (absolute path). Ephemeral run state: **`~/.gemini/memory/`**.

## Paths

| Symbol | Path |
|--------|------|
| Capability root | `~/.gemini/` (stowed from `dotfiles/ai/gemini-content-team/`) |
| Content brain (`<content-brain>`) | `$HOME/ai-brain/projects/<project_name>/` after resolution, or `GEMINI_CONTENT_BRAIN` |
| Project root hint | `GEMINI_PROJECT_ROOT`, inbound `project_root`, workspace root, or `PWD` |
| Unified ai-brain | `~/ai-brain/` (`rules/brain-conventions.md`) |
| Gemini local memory | `~/.gemini/memory/` — pipelines, observability |

## Agents

- **External:** `~/.gemini/agents/cco.md`, `~/.gemini/agents/content-lead.md`, `~/.gemini/agents/metrics-steward.md` — selectable CLI entrypoints (`experimental.enableAgents`).
- **Internal:** `~/.gemini/agents/internal/*.md` (`external_invocation: false` behavior described in `GEMINI.md`), loaded inside `cco`.

## Rules and skills

- Rules: `~/.gemini/rules/<topic>.md`
- Skills: `~/.gemini/skills/<name>/SKILL.md` — include **`project-identity`** for ai-brain path parity with Cursor.

## Scripts (callable without Make)

| Script | Purpose |
|--------|---------|
| `~/.gemini/scripts/auth/keychain-helper.sh` | Keychain get/set wrappers |

## Git

Optional `git pull` for the **active** workspace when files are git-tracked (`rules/repo-hygiene.md`).

## Idempotency (n8n / HTTP)

- **`run_id`:** UUID per pipeline run.
- **`event_id`:** UUID per outbound webhook emission; duplicates must be safe no-ops or replays per `~/.gemini/memory/pipelines/runs/<run_id>.*` ledger.

## Keychain services (examples)

- `gemini-cli` — API material for Gemini CLI (if used).
- `n8n-webhook-secret` — HMAC for webhooks.

## Metrics artefacts (write policy)

- **Writers:** `metrics-steward` (primary), optional human edit.
- **Readers:** `cco` and internal curators at **METRICS_READ** gates.
- **Paths:** `<content-brain>/analytics/metrics-current.json`, `metrics-summary.md`, `history/*`, `metrics-latest.md`.

## Observability

- **Append-only NDJSON:** `~/.gemini/memory/observability/events.jsonl` (and optional `runs/<run_id>.jsonl`).
- **Schema:** `~/.gemini/memory/_schema/observability-event.schema.md` when present.

## Native Gemini CLI files (do not collide)

Gemini CLI may own `~/.gemini/settings.json`, `extensions/`, `oauth_creds.json`, `GEMINI.md`. This package uses `agents/`, `rules/`, `skills/`, `templates/`, `scripts/`, `hooks/`. **Hooks** merge into `settings.json` per **`docs/runbooks/gemini-settings-merge.md`** (see official [Hooks](https://geminicli.com/docs/hooks/) doc).
