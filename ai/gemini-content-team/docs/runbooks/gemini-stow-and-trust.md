# Gemini stow and workspace trust

## Stow (DotMate)

From dotfiles repo root:

```bash
./scripts/DotMate.sh stow_with_target ai/gemini-content-team .gemini
```

Agents are **copied** (not symlinked) for Gemini per `DotMate.sh` — expect refresh after edits.

## Trust / fingerprint

- Headless / CI: **`GEMINI_CLI_TRUST_WORKSPACE=true`** when documented for unattended runs (`GEMINI.md`).
- After **`git pull`** changes hook definitions, Gemini may treat hooks as **untrusted** until approved — use **`/hooks panel`** or CLI trust flow per current Gemini docs (`gemini-hooks-parity.md`).
