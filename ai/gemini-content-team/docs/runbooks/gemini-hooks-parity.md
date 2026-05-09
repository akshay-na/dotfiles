# Gemini hooks parity (Cursor mimic)

**Official reference:** [Gemini CLI Hooks](https://geminicli.com/docs/hooks/)

## Contract

- Hooks run **synchronously**; **stdout = strict JSON only**; **stderr** logs; exit **0** parse JSON, **2** block, other non-zero warning.
- Configure under **`settings.json` → `"hooks"`** with merge order: **project** `.gemini/settings.json` **>** user **`~/.gemini/settings.json`** **>** system **>** extensions.
- **Matchers:** regex on tool names for `BeforeTool` / `AfterTool`; lifecycle events use exact strings or `*`.

## Cursor → Gemini event mapping (summary)

| Cursor (`hooks.json`) | Gemini |
|----------------------|--------|
| `sessionStart` | `SessionStart` |
| `sessionEnd` | `SessionEnd` |
| `preToolUse` | `BeforeTool` |
| `postToolUse` | `AfterTool` |
| `beforeShellExecution` / `afterShellExecution` | `BeforeTool` / `AfterTool` with shell tool regex (names vary by CLI version) |
| `beforeMCPExecution` / `afterMCPExecution` | `BeforeTool` / `BeforeToolSelection` / `AfterTool` — granularity differs |
| `subagentStart` / `subagentStop` | **No equivalent** — use skills + prompts |

## Known gaps

- No dedicated subagent lifecycle hooks.
- Tool name namespaces differ from Cursor — maintain matcher table against [Tools reference](https://geminicli.com/docs/reference/tools) per CLI version.

## Security / ops

- Hooks run as **user**; project hooks are **fingerprinted** — expect **untrusted** warnings after `git pull` until re-trusted (`/hooks panel`).

## Pack scripts

See **`hooks/README.md`**. **`gemini-hook-json-pass-through.sh`** validates JSON discipline (OR-02).
