# Gemini capability layer (DotMate `gemini` package)

Stows to `~/.gemini/` (agents, rules, skills, templates, scripts). Pairs with the **private** Git repo **`~/content-knowledge-base`** (Obsidian vault `kb/`, agent memory `memory/`, `docs/`, `runbooks/`, `integrations/`).

## Do not edit live symlinks

Edit files **in this repo** under `gemini/.gemini/`, then `make stow CONFIGS=gemini` (or full stow). Do not hand-edit targets under `$HOME/.gemini/` if they are symlinks into dotfiles.

## Bootstrap order

1. Stow this package: `make stow CONFIGS=gemini` from dotfiles root.
2. Run **`bash ~/.gemini/scripts/kb-bootstrap.sh`** — clones or prepares `~/content-knowledge-base` (vault/memory/docs live **only** in that repo), installs git hooks if `scripts/install-hooks.sh` exists there, creates **`memory`**, **`kb`**, **`docs`**, **`runbooks`**, and **`skills/pipeline-state`** symlinks under `~/.gemini/` (see `CONVENTIONS.md`).

If you previously installed the removed LaunchAgent plist, unload it once: `launchctl bootout gui/$(id -u)/com.akshaynagaraj.kb-sync` or `launchctl unload -w ~/Library/LaunchAgents/com.akshaynagaraj.kb-sync.plist`, then remove that plist file.

## Documentation index (Git-tracked in content repo)

After bootstrap, open **`~/content-knowledge-base/docs/README.md`** for runbooks, n8n contracts, pipeline-state skill, and cross-links to dotfiles.

## External agents (automation entrypoints)

Only **`agents/cco.md`** and **`agents/metrics-steward.md`** are production HTTP/CLI entrypoints. All other personas live under **`agents/internal/`** and run inside a `cco` invocation.
