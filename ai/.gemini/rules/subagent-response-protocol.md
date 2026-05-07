# Subagent-style envelope (internal personas, Gemini)

Internal steps use a **single fenced YAML block** as machine-readable handoff when `cco` sequences personas. Compressed natural-language fields inside the envelope follow **`skills/caveman/SKILL.md`**: default **`ultra`** for persona→persona; **security-autoclarity** (normal prose) for auth, secrets, defamation, PII, compliance findings per caveman skill.

## Outbound to n8n

Uses JSON **`CcoRunReport`** only — not caveman — for `summary` and structured fields.

## Verbatim fields

Paths, `slug`, `run_id`, `errors[]`, quoted code, and severity labels must stay uncompressed inside the envelope.
