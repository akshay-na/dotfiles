# KB conventions — content-knowledge-base (Gemini pipeline)

Distinct from Cursor `kb-conventions.mdc`. This vault is **private editorial + ops** data.

**Sync model:** no LaunchAgent — **`cco`** / **`metrics-steward`** (or their n8n wrapper) run `git pull` at run start and `~/.gemini/scripts/kb-sync.sh sync` at run end. See `rules/repo-hygiene.md`.

## Roots

- Vault: `~/.gemini/kb` → `~/content-knowledge-base/kb/`
- Docs: `~/.gemini/docs` → `~/content-knowledge-base/docs/`
- Runbooks: `~/.gemini/runbooks` → `~/content-knowledge-base/runbooks/`

## MOC folders

Numbered `kb/00-` … `kb/90-` plus `kb/_meta/` for machine-readable ledgers and schemas.

## Metrics (write policy)

- **Writers:** `metrics-steward` only (plus optional documented human out-of-band edit).
- **Readers:** `cco` and all internal personas at **METRICS_READ** gates.
- Paths: `kb/90-Analytics/metrics-current.json`, `metrics-summary.md`, `history/*.json`.

## Published / ledger

Logical writers to `kb/50-Published/`, `kb/60-Repurposed/`, `kb/_meta/` are internal **`kb-librarian`** / **`archivist`** personas **inside a `cco` run** after FSM allows publish — not standalone HTTP agents.

## Frontmatter

See `kb/_meta/frontmatter.schema.md` for content files under Briefs/Drafts/Published/Repurposed.
