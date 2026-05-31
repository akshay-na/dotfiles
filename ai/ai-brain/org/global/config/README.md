# Org global config (runtime)

Canonical policy files stowed from `dotfiles/ai/ai-brain/org/global/config/`.

| File | Purpose |
|------|---------|
| `memory-demotion.yml` | Memory/KB lifecycle, query ladder L0–L3, demotion, promotion deny-list, `storage.forbidden_paths` |

**Contract version:** `contract_version` in YAML must match `schema_versions.memory_demotion` in project `.meta/manifest.json` after onboarding.

### Materialize into `~/ai-brain` (portability)

Stow may place `memory-demotion.yml` as a symlink to dotfiles. On machines that only clone the brain git repo, copy the canonical file from dotfiles (when available):

```bash
~/ai-brain/scripts/materialize-brain-policy.sh --dry-run   # default: show plan only
~/ai-brain/scripts/materialize-brain-policy.sh --apply     # cp source; remove symlink first
DOTFILES_DIR=~/dotfiles ~/ai-brain/scripts/check-memory-demotion-contract.sh
```

See **`~/ai-brain/scripts/README.md`** for full catalog and `make` targets.

Canonical editor path: `dotfiles/ai/ai-brain/org/global/config/memory-demotion.yml`. ADR: `.cursor/docs/decisions/2026-06-01-brain-portability.md`.

Agents: **read-only** on skeleton; touch-writes under `projects/`, `org/` (not `_schema/`) per `brain-conventions`.
