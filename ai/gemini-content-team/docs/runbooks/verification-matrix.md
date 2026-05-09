# Verification matrix — Gemini content pack rollout

**Automation:** `make verify-gemini-pack` (hook JSON stdout + agent frontmatter + Cursor↔Gemini drift). Individual gates: `make verify-gemini-hooks`, `make verify-gemini-frontmatter`, `make verify-gemini-manifest [GEMINI_MANIFEST_BASE=<ref>]`.

## Scenarios × client × artifacts

| Scenario | Cursor client | Gemini client | Expected artifacts / paths |
|----------|---------------|---------------|------------------------------|
| Hook JSON stdout | N/A (Gemini substrate) | Run `./ai/gemini-content-team/hooks/verify-gemini-hooks.sh` | Exit 0; compact JSON only |
| Pack drift detection | N/A | `./ai/gemini-content-team/hooks/verify-gemini-manifest.sh` (or `--against origin/main` in CI) | Exit 0 when paired paths in sync; clear DRIFT lines when not |
| Draft LinkedIn atom | `.cursor` agents + vault rules | `.gemini` agents + vault rules | `content-foundry/draft/linkedin/` atoms; indexes updated per schema |
| Promote staging | `dev-content-promote` under Cursor policy | Same workflow under Gemini policy | Path moves + registry — **`dev-content-promote`** user-approved |
| Metrics ingest | `metrics-steward` / SMEs | `metrics-steward` | `<content-brain>/analytics/metrics-*` |
| `content-lead` dispatch | `{root}/.cursor/agents/` discovery | `{root}/.gemini/agents/` discovery | Pipeline stages per **`generate-content-pipeline`** |
| Editorial critic ledger | `~/ai-brain/session/cursor-<task-id>/critic-ledger.md` | `~/ai-brain/session/gemini-<task-id>/critic-ledger.md` | Namespaced session dirs (OR-04 / OR-09) |
| Org plan / review doc write | `~/.cursor/docs/**`, `content-foundry/.cursor/docs/**` | `~/.gemini/docs/**`, `content-foundry/.gemini/docs/**` | No cross-client writes |
| MCP allowlist | `mcp.json` + broker rules | Gemini MCP settings + **`mcp-usage.md`** / **`vp-research.md`** | Broker policy documented; technical enforcement TBD (OR-05) |
| Trusted folder / ignore | Trusted folders + `.cursorignore` patterns | Trusted folders + `.geminiignore` | Vault/brain noise excluded per repo policy |

## Tier labeling

Publish **max enforcement tier** achieved (see parity plan § Enforcement parity tier table) — do **not** claim full Cursor hook parity until matchers are verified.
