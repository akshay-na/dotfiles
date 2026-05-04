---
name: subagent-observability
description: Format one NDJSON audit line per inter-persona event (hashes, paths — no raw secrets or full draft bodies).
---

# Subagent observability (audit lines)

## Append target

`memory/observability/events.jsonl` (and optionally `memory/observability/runs/<run_id>.jsonl`).

## One line = one JSON object

No wrapping array. Use `jq -c` to build lines if tooling allows.

## Field population

- `payload_sha256`: SHA-256 of UTF-8 bytes of caveman handoff blob when applicable; omit if no payload.
- `artifact_paths`: repo-relative strings only (e.g. `kb/40-Drafts/blog/foo.md`).
- `event_id`: fresh UUID v4 per line.

## Never include

Secrets, tokens, emails, phone numbers, full model outputs, raw subscriber lists.

## Example shape (illustrative)

`{"schema_version":1,"ts":"2026-05-04T12:00:00Z","run_id":"…","event_id":"…","phase":"DRAFT","from_persona":"cco","to_persona":"editor-blog","event":"handoff","artifact_paths":["kb/40-Drafts/blog/…"],"payload_sha256":"abc…"}`
