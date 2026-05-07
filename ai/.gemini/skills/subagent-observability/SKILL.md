---
name: subagent-observability
description: Format one NDJSON audit line per inter-persona event (hashes, paths — no raw secrets or full draft bodies).
---

# Subagent observability (audit lines)

## Append target

`~/.gemini/memory/observability/events.jsonl` (and optionally `~/.gemini/memory/observability/runs/<run_id>.jsonl`).

## One line = one JSON object

No wrapping array. Use `jq -c` to build lines if tooling allows.

## Field population

- `payload_sha256`: SHA-256 of UTF-8 bytes of caveman handoff blob when applicable; omit if no payload.
- `artifact_paths`: paths relative to `<content-brain>/` or absolute under `~/ai-brain/` (e.g. `drafts/blog/foo.md` or full path for clarity).
- `event_id`: fresh UUID v4 per line.

## Never include

Secrets, tokens, emails, phone numbers, full model outputs, raw subscriber lists.

## Example shape (illustrative)

`{"schema_version":1,"ts":"2026-05-04T12:00:00Z","run_id":"…","event_id":"…","phase":"DRAFT","from_persona":"cco","to_persona":"editor-blog","event":"handoff","artifact_paths":["drafts/blog/…"],"payload_sha256":"abc…"}`
