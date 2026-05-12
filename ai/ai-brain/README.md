# AI Brain — tracked skeleton

Tracked in repo: `_schema/`, `_templates/`, `README.md`, `.gitignore` (template/instruction only).

Ignored after stow: `Home.md`, `.obsidian/`, `projects/`, `org/`, `session/`, `.meta/` (local content + migration).

## Operator profile (PII ok locally; no secrets)

For a durable **private** model of the user (identity prefs, working style, prompt-derived **non-secret** signals), use **`org/global/operator-profile/`**. See **`_templates/operator-profile.md`** for layout. **`brain-conventions`** in your Cursor/Gemini pack defines **PII vs secrets** for private vaults.

`dotfiles/ai/ai-brain/` is merged **into** `~/ai-brain/` with **`-t $HOME/ai-brain`** (never `-t $HOME`). The whole **`ai/`** tree is excluded from default `make stow`; **`ai-brain` is applied whenever you run `stow_with_target`** on any package under **`ai/`** except **`ai-brain`** itself (see `DotMate.sh`).

## If `~/ai-brain` is already a git repo

That is normal. Stow does **not** replace the directory or remove `.git`. It only creates symlinks **inside** `~/ai-brain` for paths shipped by this package (e.g. `_schema/`, `_templates/`, `README.md`, `.gitignore` from dotfiles).

- **No collision:** those paths are missing → stow adds symlinks next to your existing files (e.g. `projects/`, `org/`).
- **Collision:** the repo already has real `_schema/` or `_templates/` (not symlinks) → GNU Stow stops with a conflict. Then either align that tree with dotfiles, remove/relocate the conflicting paths once, or skip stowing `ai-brain` and maintain `_schema`/`_templates` only in the brain repo.

`mkdir -p ~/ai-brain` before stow only ensures the directory exists; it does not overwrite repo content.

## How to apply the skeleton (DotMate)

Do **not** use `make stow CONFIGS="ai-brain"` — DotMate rejects that; the canonical path is **`stow_with_target`**, which stows the pack to `~/.cursor` or `~/.gemini` and then runs **`ai-brain`** into `~/ai-brain`.

```bash
make stow-with-target TOOL_PATH="ai/cursor/tech-team" TARGET_NAME=".cursor"
# or: ./scripts/DotMate.sh stow_with_target ai/private-teams/cursor/content-team .cursor
# or: ./scripts/DotMate.sh stow_with_target ai/private-teams/gemini/content-team .gemini
```

If you run `stow` yourself (not recommended), the package dir is **`~/dotfiles/ai/ai-brain`** and the target must be **`~/ai-brain`**:  
`stow --no-folding --override=ai-brain -d ~/dotfiles/ai -t ~/ai-brain ai-brain`.
