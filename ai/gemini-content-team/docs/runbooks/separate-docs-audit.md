# Separate documentation trees (audit)

## Global (org packs)

| Client | Agent-written docs root |
|--------|-------------------------|
| Cursor | `~/.cursor/docs/**` |
| Gemini | `~/.gemini/docs/**` |

**Rule:** no cross-writing — plans, reviews, ADRs from Gemini runs land only under **`~/.gemini/docs/`** (and repo **`…/.gemini/docs/`**).

## Repo-local (example: content-foundry)

| Client | Path |
|--------|------|
| Cursor | `content-foundry/.cursor/docs/**` |
| Gemini | `content-foundry/.gemini/docs/**` |

Physical directories — **not** symlinks. Mitigate drift with dual-pack maintenance (same PR when templates change).
