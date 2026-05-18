# Org global config (runtime)

Canonical policy files stowed from `dotfiles/ai/ai-brain/org/global/config/`.

| File | Purpose |
|------|---------|
| `memory-demotion.yml` | Memory/KB lifecycle, query ladder L0–L3, demotion, promotion deny-list, `storage.forbidden_paths` |

**Contract version:** `contract_version` in YAML must match `schema_versions.memory_demotion` in project `.meta/manifest.json` after onboarding.

Agents: **read-only** on skeleton; touch-writes under `projects/`, `org/` (not `_schema/`) per `brain-conventions`.
