# Gemini observability fallback

When Gemini CLI native telemetry and hook NDJSON coexist:

- **Fail-open:** observability hooks must never block operator workflows.
- **Canonical durable metrics** still flow through **`brain-memory-kb`** / **`~/ai-brain/`** per **`rules/brain-conventions.md`**.
- **Ephemeral run logs:** `~/.gemini/memory/observability/events.jsonl` and per-run logs under `~/.gemini/memory/pipelines/`.

Consolidate narratives with Cursor **`agent-observability`** expectations using the same **stage ids** where practical (`cco.run.*`, pipeline phases).
