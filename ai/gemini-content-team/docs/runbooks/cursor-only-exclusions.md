# Cursor-only exclusions (Gemini pack)

Cursor **`dotfiles/ai/cursor-content-team`** artifacts **without** a byte-for-byte Gemini twin. Each row notes substitute or residual gap.

| Area | Cursor artifact | Gemini posture |
|------|-----------------|----------------|
| IDE UX | Inline rules UI, Composer | CLI plan mode + `GEMINI.md` hierarchy |
| Hooks | `hooks.json` lifecycle names (`subagentStart` / `subagentStop`) | **Gap:** no direct twins — use skills + closest Gemini events (`BeforeTool` / `AfterAgent`) per **`gemini-hooks-parity.md`** |
| Hooks | `postToolUseFailure` | Approximate via `AfterTool` outcome parsing — document limitation |
| Config | Pack `mcp.json` file | Configure MCP via **Gemini MCP + `settings.json`** — broker rules unchanged (**`vp-research`** delegation policy-only unless Policy engine wired) |
| Telemetry | Cursor-only IDE telemetry fields | Gemini CLI telemetry doc + hook NDJSON — **`gemini-observability-fallback.md`** |
| Pre-commit | `subagent-protocol-lint.sh` in Cursor hooks | Remains **repo** pre-commit — not a Gemini session hook |

Update this file whenever Cursor pack gains behavior with no Gemini port.

## Machine-readable counterpart

The drift detector `verify-gemini-manifest.sh` consumes:

- **`hooks/manifest-exclusions.txt`** — Cursor-only paths (suppresses drift findings on the Cursor side).
- **`hooks/manifest-gemini-only.txt`** — Gemini-only paths (suppresses drift findings on the Gemini side).
- **`hooks/manifest-pairs.txt`** — declarative pair rules for human reference.

When you add or remove a row in this prose runbook, also update the matching line in the relevant manifest file so the automation tracks reality.
