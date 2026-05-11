# DotMate

DotMate is a GNU Stow–based dotfiles layout for macOS and Debian/Ubuntu: one **canonical** git clone (often `~/dotfiles`) plus an optional **local** clone (default `~/dotfiles-local`) for machine-only overrides without polluting upstream history.

---

## Install

**Prerequisites**

- macOS with Homebrew, or Debian/Ubuntu with `apt`
- GNU Stow, `make`, `git`

**Clone and full setup**

```bash
git clone https://github.com/akshay-na/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install
```

(Upstream may also advertise the repository as “DotMate”; the auto-clone path in `shell/.commonrc` uses the `dotfiles` remote name above.)

`make install` runs `scripts/DotMate.sh install`: OS-specific packages, shared installers, then `stow` into `$HOME`, permission fixes, and optional `chsh` to zsh.

**Configs only (no package install)**

```bash
cd ~/dotfiles
make stow
```

---

## First install and auto-clone

Tracked `shell/.commonrc` exports `DOTFILES_DIR` (default `~/dotfiles`) and, on an **interactive local TTY** with network reachability, may run a background `git fetch` in that directory. If the directory is missing, it runs **`git clone`** to populate it (see `shell/.commonrc` for the exact remote URL).

Treat that behavior like any other auto-clone: use only on hosts and networks you trust.

---

## Update

```bash
cd ~/dotfiles
make update
```

This backs up, optionally runs `check_dotfiles_update` when defined in `shell/.functions`, then re-stows. If `.functions` is missing or the function is undefined, the update check is skipped with a warning (no hard failure).

### `DOTFILES_DISABLE_UPDATE`

Set `DOTFILES_DISABLE_UPDATE=true` in the environment or in `~/.commonrc_local` to skip the interactive fetch / behind-origin prompt path (agents, CI, or slow links).

---

## Stow and unstow (selective)

| Goal | Command |
|------|---------|
| Stow everything (see package list note below) | `make stow` |
| Stow specific packages | `make stow CONFIGS="git shell ssh"` |
| Stow one path to a custom target under `$HOME` | `make stow-with-target TOOL_PATH="ai/cursor-tech-team" TARGET_NAME=".cursor"` |
| Unstow all | `make unstow` |
| Unstow specific packages | `make unstow CONFIGS="git shell"` |

**Package list note:** Full `stow` walks **immediate subdirectories** of the active dotfiles root and stows each package name, except **`ai`** and **`scripts`** (those are excluded from the default loop). Add new top-level packages by adding a new directory; no hard-coded package list in `make`.

---

## `bootstrap-local` and the two-root contract

Use a **second** git repository for overrides (default path `~/dotfiles-local`).

### Rules

1. **Run `make bootstrap-local` from the upstream clone** (or pass an explicit canonical root). The Makefile sets `DOTMATE_CANONICAL_ROOT` to the directory containing this `Makefile` (`abspath` of `Makefile`’s directory), not your shell `pwd`, so `make -f ~/dotfiles/Makefile bootstrap-local` still points at the real upstream tree.
2. **`bootstrap_local` copies only from `DOTMATE_CANONICAL_ROOT`** (`scripts/DotMate.sh`, `Makefile`, `.stowrc`). It must **not** copy from the operational `DOTFILES_DIR` when that points at the local tree, or you would self-copy stale files.
3. Manual script use without Make must export **`DOTMATE_CANONICAL_ROOT`** to that upstream path, or the script exits with:  
   `Run via \`make bootstrap-local\` from upstream clone or set \`DOTMATE_CANONICAL_ROOT\`.`

**Optional environment**

| Variable | Purpose |
|----------|---------|
| `LOCAL_DIR` | Target tree (default `~/dotfiles-local`). Example: `make bootstrap-local LOCAL_DIR=~/src/dotfiles-local` |
| `SKIP_GIT_INIT=1` | Skip `git init -b main` (CI or hosts without Git). Default runs `git init` when `git` is on `PATH`. |
| `DOTMATE_CANONICAL_ROOT` | Normally set by Make; required for direct `./scripts/DotMate.sh bootstrap_local`. |

**Git version:** `git init -b main` needs Git **2.28+**. Older Git: set `SKIP_GIT_INIT=1` and initialize manually.

**Idempotency:** Existing scaffold files are not overwritten; `cp -n` is used for the three copied artifacts. If a run half-fails, you can remove the new tree when it has no custom edits, or re-run bootstrap (skips existing files).

---

## Trust boundary for `DOTFILES_DIR`

`scripts/DotMate.sh` resolves **`DOTFILES_DIR`** as:

1. The **`DOTFILES_DIR` environment variable** if set, or  
2. The directory containing **`scripts/DotMate.sh`** (repository root of the script you invoked).

Sourcing `shell/.functions` from that tree is equivalent to trusting that directory like a git checkout. Before sourcing, the script checks that the directory is **owned by your current euid** and is **not world-writable**; otherwise it logs and exits. Point `DOTFILES_DIR` only at trees you trust.

---

## Backup

```bash
make backup
```

Backs up files that would be replaced under `$HOME` into a timestamped directory under `~/dotfiles_backup/`.

---

## Cleanup

There is **no** `make uninstall` target. Use:

- `make unstow` / `make unstow CONFIGS="…"` to drop symlinks managed by Stow  
- `make clean` to remove broken symlinks under `$HOME` and common config paths  

Review `~/dotfiles_backup/` manually when reclaiming disk space.

---

## Troubleshooting

| Symptom | Suggestion |
|---------|------------|
| Broken symlinks after removals | `make clean` |
| Stow conflicts between two trees | Stow **disjoint** packages where possible; stow order matters when both trees own the same path |
| Permission errors on SSH/GPG dirs | `make install` (prep) adjusts repo-side `ssh/` and `gnupg/` permissions; ensure `~/.ssh` / `~/.gnupg` modes are 700 / 600 as needed |
| `bootstrap-local` refuses to copy | Confirm you are in the **canonical** clone or set `DOTMATE_CANONICAL_ROOT` |
| Update path errors after trimming repo | Missing `shell/.functions` is allowed; `check_dotfiles_update` is optional |

---

## Local override files (Included list)

These paths are **created empty on first bootstrap** under your **local** repo if missing (same layout under `$HOME` after you `stow` that tree). Tracked upstream configs merge them as shown.

| Local repo path (under `LOCAL_DIR`) | Merged from (tracked) |
|------------------------------------|------------------------|
| `shell/.commonrc_local` | `shell/.commonrc` |
| `shell/.functions_local` | `shell/.functions` |
| `shell/.aliases_local` | `shell/.aliases` |
| `shell/.zshrc_local` | `shell/.zshrc` |
| `shell/.bashrc_local` | `shell/.bashrc` |
| `shell/.tmux_local.conf` | `shell/.tmux.conf` (loads `~/.tmux_local.conf`) |
| `git/.gitconfig_local` | `git/.gitconfig` (`include.path`) |
| `ssh/.ssh/config_local` | `ssh/.ssh/config` (`Include`) |
| `utilities/.taskrc_local` | `utilities/.taskrc` (`include`) |

**Starship:** There is no `*_local` merge file. Use a branch, `STARSHIP_CONFIG`, or a separate stow tree.

### Audit: other `*_local` references in this repo

- `shell/.tmux.conf` — loads **`~/.tmux_local.conf`** (same basename as scaffold `shell/.tmux_local.conf` once stowed).
- `starship/.config/starship.toml` — **`hostname_local`** is a **Starship custom module name**, not a dotfile merge path.
- Comments in `shell/.functions` / `shell/.aliases` mention legacy `.functions_local.sh` / `.alias_local.sh` wording; runtime paths are **`~/.functions_local`** and **`~/.aliases_local`**.

---

## Verification

```bash
bash -n scripts/DotMate.sh
./scripts/verify-bootstrap-local.sh
```

The verifier uses a temp `HOME` snapshot for `stow -n` only; your real `$HOME` directory listing must stay byte-for-identical (sorted `ls -A`). CI without Git: `VERIFY_SKIP_GIT_INIT=1 ./scripts/verify-bootstrap-local.sh`.

---

## `make help`

Targets are documented in the `Makefile` `help` target. After changes, keep README and `make help` aligned (`bootstrap-local`, `stow`, `unstow`, `backup`, `update`, `install`, `clean`, `stow-with-target`, `help`).

---

## Contributing and license

Contributions welcome via fork and PR. License: **GPL-3.0** — see `LICENSE`.

---

## Acknowledgments

GNU Stow, Homebrew, Mise, Nerd Fonts, Zinit, and the wider dotfiles community.
