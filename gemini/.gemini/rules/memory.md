# Memory — content pipeline

Agent memory lives at `~/.gemini/memory/` → `~/content-knowledge-base/memory/`.

## Schema

- Entry frontmatter: `memory/_schema/entry.schema.md`
- Namespaces: `memory/_schema/namespaces.md`
- Observability NDJSON: `memory/_schema/observability-event.schema.md`

## Writers

- **`cco`** updates `memory/pipelines/**`, append-only `memory/observability/events.jsonl`, run summaries.
- **`metrics-steward`** updates `memory/org/metrics-latest.md` (and optional `memory/decisions/`).
- Internal personas write only paths allowed in `rules/orchestration.md` for their phase.
