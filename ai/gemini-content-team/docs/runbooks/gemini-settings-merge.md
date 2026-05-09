# Merging Gemini `settings.json` hooks

**Do not** overwrite an operator’s full **`settings.json`**.

## Steps

1. Open **`~/.gemini/settings.json`** (create minimal `{}` if absent).
2. Add or merge a top-level **`"hooks"`** object using snippets from this pack’s runbooks.
3. For repo-local behavior, prefer **`content-foundry/.gemini/settings.json`** (project layer wins over user per Gemini merge rules).

## Example: SessionStart pass-through (dotfiles-relative)

After stow, the hook path resolves under **`~/.gemini/hooks/`**. From the **dotfiles repo** working copy during development, use the absolute path to the script under your home:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "$HOME/.gemini/hooks/gemini-hook-json-pass-through.sh",
        "name": "json-pass-through-smoke"
      }
    ]
  }
}
```

Adjust **`command`** to match your install location if not stowed to **`~/.gemini`**.

See **`gemini-hooks-parity.md`** for event names and JSON stdout rules.
