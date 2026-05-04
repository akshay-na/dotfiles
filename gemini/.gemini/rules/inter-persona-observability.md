# Inter-persona observability (audit NDJSON)

## Stores (Git-tracked)

- `memory/observability/events.jsonl` — append-only, one JSON object per line (NDJSON).
- Optional: `memory/observability/runs/<run_id>.jsonl` per run.

## Writer

**`cco`** appends exactly one line on: `phase_enter`, `phase_exit`, `handoff`, `metrics_snapshot_read`, `error`.

## Required fields

See `memory/_schema/observability-event.schema.md`. Minimum: `schema_version`, `ts`, `run_id`, `event_id`, `phase`, `from_persona`, `to_persona`, `event`.

## Forbidden in audit lines

- Raw secrets, tokens, API keys, full draft bodies, subscriber emails.
- Use `payload_sha256` for handoff blob hash, `artifact_paths[]` for file pointers only.
- Security findings: `severity`, `category`, path — not exploit PoC text.

## Rotation

Monthly (or size >50MB): move to `memory/observability/archive/<YYYY-MM>.jsonl.gz` with prior commit on `main`. Document in `runbooks/observability.md`.

## Human editing

Do not hand-edit `events.jsonl` during normal runs; emergency forensic copy only.
