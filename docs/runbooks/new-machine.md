# New machine runbook (DotMate)

Living checklist of **manual** steps automation cannot finish. Primary: fresh Mac. Notes call out Debian/Ubuntu where DotMate supports it.

Do **not** paste secrets, tokens, or private keys into this file or chat.

---

## 1. Prerequisites / before clone

- [ ] Working network + power
- [ ] **macOS:** Apple ID ready (iCloud / App Store as needed)
- [ ] **macOS:** Xcode Command Line Tools if `git`/`clang` missing: `xcode-select --install`
- [ ] **macOS:** [Homebrew](https://brew.sh) installed (or let `install_common` install it during `make install`)
- [ ] **Debian/Ubuntu:** `sudo` + `apt` access; `git`/`make`/`curl` available (or install via `install_debian`)
- [ ] Decide clone path (canonical default: `~/dotfiles`)
- [ ] First clone over **HTTPS** if SSH keys not on this host yet (chicken/egg)

---

## 2. Clone & bootstrap (automated)

```bash
git clone https://github.com/akshay-na/dotfiles.git ~/dotfiles
cd ~/dotfiles
make install
```

What `make install` → `scripts/DotMate.sh install` already does:

| Step | macOS | Debian/Ubuntu |
| --- | --- | --- |
| OS packages | `scripts/resources/macos.sh` → `pinentry-mac`, `pam-reattach`, `zsh`; `brew bundle --file=scripts/resources/Brewfile.macos` | `scripts/resources/debian.sh` → apt deps (`zsh`, `tmux`, `stow`, …); Linuxbrew PATH snippet |
| Shared CLI | `scripts/resources/common.sh` → Homebrew/`scripts/resources/Brewfile` (incl. `gitleaks`, `gnupg`, `starship`, `tmux`, `stow`, …), `mise`, `bws` binary under `~/.local/bin` | same common path after brew exists |
| Defaults | `default_mac_settings.sh` (log: `~/.macos_defaults.log`) | n/a |
| Stow | all top-level packages except `ai/` (and `scripts/` is not a stow package in the default loop) | same |
| Post | `~/.gnupg` / `~/.ssh` modes; `fc-cache`; `chsh` → zsh | same |

Configs-only (no brew):

```bash
cd ~/dotfiles
make stow
# selective: make stow CONFIGS="git shell ssh"
```

Optional AI agent pack (not in default `make stow`):

```bash
make stow-with-target TOOL_PATH="ai/cursor/tech-team" TARGET_NAME=".cursor"
# private packs: git submodule update --init ai/private-teams  (when needed)
```

Optional local override tree: `make bootstrap_local` from the **canonical** clone (see README).

Restart the terminal (or log out/in) after `make install` so zsh + stowed configs load.

### Manual only starts below

---

## 3. Ordered manual steps

Do these in order when possible. Skip rows that do not apply.

### 3.1 Apple / App Store / iCloud (macOS)

- [ ] Sign in to **System Settings → Apple ID / iCloud** if you rely on Keychain sync, Find My, etc.
- [ ] Sign in to **Mac App Store** (needed for any App Store–only apps; DotMate `Brewfile.macos` is cask-based and does **not** drive `mas` formulas today)

### 3.2 Bitwarden desktop + Secrets Manager (`bws`)

Automation installs the **Bitwarden** cask (`Brewfile.macos`) and the **`bws`** CLI (`install_common`). It does **not** log you in.

- [ ] Open Bitwarden desktop → log in → unlock vault
- [ ] In Bitwarden Secrets Manager UI: create/copy a machine **access token** (never commit it)
- [ ] In a new shell with GPG pinentry working: `store_bws_token` (from stowed `shell/.functions`)
  - Stores encrypted blob at `~/.local/share/bws/.bws_access_token.gpg`
- [ ] Verify: `load_secrets` then `evict_secrets` (or `exec_with_secrets <cmd>`)
- [ ] Confirm `command -v bws` → usually `~/.local/bin/bws`

### 3.3 Hammerspoon permissions (macOS)

Cask + stow place the app and `~/.hammerspoon/` config. OS still gates input.

- [ ] Open **Hammerspoon** once
- [ ] **System Settings → Privacy & Security → Accessibility** → enable Hammerspoon
- [ ] If prompts appear: **Input Monitoring** (and related) for Hammerspoon
- [ ] Reload config (Hammerspoon menu → Reload, or restart app) — expect “Hammerspoon Config Loaded” alert from `utilities/.hammerspoon/init.lua`

### 3.4 SSH keys → Git hosts

Tracked `ssh/.ssh/config` defines `github.com`, `gitlab.com`, `bitbucket.org` (plus `Include ~/.ssh/config_local`). No private keys are shipped; put keys under `~/.ssh/` (typical `id_ed25519` / `id_ed25519.pub`). `shell/.commonrc` attempts `ssh-add` for `~/.ssh/id_*` (non-`.pub`).

- [ ] Generate or restore key: `ssh-keygen -t ed25519 -C "<you@example>" -f ~/.ssh/id_ed25519`
- [ ] Set modes: `chmod 700 ~/.ssh` and `chmod 600 ~/.ssh/id_*` (non-`.pub`)
- [ ] Add **public** key in each host you use:
  - GitHub → SSH keys
  - GitLab → SSH keys
  - Bitbucket → SSH keys
- [ ] Optional host/key overrides: edit **`~/.ssh/config_local`** (scaffolded via `bootstrap_local` / local tree) — do **not** put secrets in the tracked repo
- [ ] Verify: `ssh -T git@github.com` (and `git@gitlab.com` / Bitbucket as needed)
- [ ] Prefer switching remotes to SSH when ready: `git set-ssh` (alias in `git/.gitconfig`) inside clones

### 3.5 GPG / OpenPGP signing

`Brewfile` installs `gnupg`; macOS install adds `pinentry-mac`; stow applies `gnupg/.gnupg/` (`pinentry-program` → `~/.local/bin/pinentry-wrapper.sh`). Global git sets `commit.gpgsign = true`. Dotfiles commits expect OpenPGP signing.

- [ ] Import or generate your signing key; ensure private key is available on this machine
- [ ] Trust / ultimate-trust as you normally do for your own key
- [ ] Set `user.signingkey` (and name/email) in **`~/.gitconfig_local`** — tracked `git/.gitconfig` leaves signingkey commented
- [ ] Confirm agent: `gpgconf --launch gpg-agent` and `echo $GPG_TTY` (set in `.commonrc`)
- [ ] Test: `echo test | gpg --clearsign` and a signed commit in a scratch repo
- [ ] Dotfiles repo: do **not** use `--no-gpg-sign` for commits here

### 3.6 Cursor / editor login

- [ ] Open **Cursor** (cask in `Brewfile.macos`) → sign in
- [ ] If you use the tech pack: apply `make stow-with-target … TARGET_NAME=".cursor"` then reopen Cursor
- [ ] Optional: other editors/IDEs you rely on (VS Code, etc.) — not all are in Brewfile

### 3.7 Terminal Full Disk Access / Automation (macOS)

Grant when macOS prompts, or pre-emptively if tools fail reading protected paths:

- [ ] **Privacy & Security → Full Disk Access** for your daily terminal (**Alacritty** cask and/or Terminal / iTerm)
- [ ] Approve **Automation** prompts (Terminal/Hammerspoon controlling other apps) as they appear
- [ ] Re-open the terminal after grants

### 3.8 First-run cask permissions (macOS)

From `Brewfile.macos` — open once and clear TCC prompts:

- [ ] **Alfred** — Accessibility / Automation as prompted; set as default launcher if desired
- [ ] **Espanso** — Accessibility / Input Monitoring; register expansion service
- [ ] **Obsidian** — folder access for vaults (often under `~/ai-brain` after AI pack stow)
- [ ] Others you use from the same Brewfile (Chrome, Discord, etc.) as needed

### 3.9 Touch ID + `pam-reattach` (macOS)

`macos.sh` installs **`pam-reattach`** but does **not** edit PAM. Wire Touch ID yourself:

- [ ] Follow current [pam-reattach](https://github.com/fabianishere/pam-reattach) docs for `/etc/pam.d/sudo_local` (Apple’s supported override file on recent macOS)
- [ ] Typical intent: `pam_reattach` before `pam_tid` so Touch ID works inside tmux/ssh-ish sessions
- [ ] Verify: `sudo -k` then `sudo -v` → Touch ID prompt
- [ ] Keep a working password path; bad PAM edits can lock out sudo

### 3.10 Shell / agent smoke (quick)

- [ ] New login shell is **zsh** (`echo $SHELL`)
- [ ] `starship --version` and prompt renders
- [ ] `tmux -V` then `tmux new -s smoke` / detach
- [ ] `command -v gitleaks` (from `Brewfile`; pre-push hook at `~/.githooks/pre-push` fail-closed if missing)
- [ ] Optional: `make lint-syntax` from repo root

---

## 4. Post-install verification

- [ ] `cd ~/dotfiles && make help` works
- [ ] Stow packages present as symlinks under `$HOME` (spot-check `.zshrc`, `.gitconfig`, `.ssh/config`)
- [ ] `gitleaks version` (or `gitleaks --version`) on `PATH`
- [ ] `bws --version` and `load_secrets` / `evict_secrets` succeed
- [ ] `ssh -T git@github.com` (plus other hosts you use)
- [ ] Signed git commit works (`gpgsign` + pinentry)
- [ ] Hammerspoon reload OK; Alfred/Espanso not blocked by TCC
- [ ] Optional AI pack: `~/.cursor` linked via `stow-with-target`
- [ ] Optional: `bash -n scripts/DotMate.sh` and/or `./scripts/verify-bootstrap-local.sh` (see README Verification)
- [ ] Optional: `make lint-syntax` / `make lint` when developing DotMate itself

---

## 5. What scripts already cover (do not redo)

Humans should **not** re-run these by hand unless install failed mid-way:

- Homebrew install attempt + `brew bundle` for **`scripts/resources/Brewfile`** and (macOS) **`scripts/resources/Brewfile.macos`**
- `bws` download into `~/.local/bin` when missing
- `pinentry-mac`, `pam-reattach`, `zsh` formula install (macOS)
- macOS defaults script (`default_mac_settings.sh`)
- Full-tree **`stow`** of top-level packages (except **`ai/`**)
- `~/.ssh` / `~/.gnupg` permission hardening after install
- `chsh` to zsh
- `make prep` permission fixes on repo-side `ssh/` and `gnupg/` trees
- Global git **`core.hooksPath = ~/.githooks`** once `git` package is stowed (hook scripts themselves are stowed; `gitleaks` must still be on `PATH`)

Re-run narrowly if needed: `make stow`, `make install` (heavy), or `bash "$DOTFILES_DIR/scripts/resources/default_mac_settings.sh"` for defaults only.

---

## Related

- Root install docs: [`README.md`](../../README.md)
- Entrypoint: `scripts/DotMate.sh` (`install`, `stow`, `stow_with_target`, `bootstrap_local`, …)
- Make targets: `make help`
