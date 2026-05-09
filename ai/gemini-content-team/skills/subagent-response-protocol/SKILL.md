---
name: subagent-response-protocol
description: >
  Content org: subagent → parent is one JSON object (no YAML). Validate against
  contracts/schemas/subagent-response.schema.json. Applies to every Task child.
---

# Subagent Response Protocol (thin skill)

Child replies are **one JSON object** only — validate against **`contracts/schemas/subagent-response.schema.json`**. See **`rules/subagent-response-protocol.md`**.

## Pointers

- **Schema:** `contracts/schemas/subagent-response.schema.json`
- **Example:** `templates/subagent-response.example.json`
- **Injected contract:** `contracts/subagent-contract-block.md`
- **Hooks:** `hooks/subagent-protocol-{inject,lint}.sh`

## Compression

- **Verbatim:** `schema_version`, `contract`, `_marker`, `status`, `agent`, paths, `fix`, `errors[]`, line numbers.
- **Caveman-ultra:** `summary`, non-security `findings[].note`, `next_actions[]`, `open_questions[]`.
- **Security-autoclarity:** full sentences when category/severity triggers (see rule).

## JSON string safety

No raw secrets; no executable HTML in strings; large tool dumps → `artifacts[]` refs only.

## Parents

`cco` / `content-lead` parse child JSON, one reformat retry, then stub. Never forward `_marker` to users.

## Spawn / respond

- Spawning `Task`: hook injects contract + `_marker`.
- Responding as subagent: final message = JSON object only.
