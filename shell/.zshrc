# ---------------------------------------------------------------
# Zsh Environment Initialization Script
# ---------------------------------------------------------------
# Purpose:
# This script customizes the Zsh environment by:
# - Setting up path configurations and aliases.
# - Managing plugins via Zinit.
# - Configuring history options and keybindings.
# - Initializing various tools (Starship, Zoxide, Fzf).
# - Loading additional local configurations if present.
# ---------------------------------------------------------------

# Usage:
# Place this file in the home directory as `.zshrc`. Make sure to install necessary plugins
# and tools such as Starship, Zoxide, and Fzf for complete functionality. For local customizations,
# define additional configurations in `.aliases_local` or `.zshrc_local` as needed.
# ---------------------------------------------------------------


# ---------------------------------------------------------------
# Source Common Configuration and Aliases
# ---------------------------------------------------------------
source ~/.commonrc

# ---------------------------------------------------------------
# Path Configuration
# ---------------------------------------------------------------
export YSU_MESSAGE_POSITION="after"                                  # Custom message positioning

# ---------------------------------------------------------------
# Zinit Plugin Manager Initialization and Plugins
# ---------------------------------------------------------------
export ZINIT_HOME="${XDG_DATA_HOME:-$HOME}/.zinit"

# Install Zinit if not already installed
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "${ZINIT_HOME}/zinit.zsh"

# Load essential Zinit plugins
zinit light-mode for \
  zsh-users/zsh-syntax-highlighting \
  zsh-users/zsh-completions \
  zsh-users/zsh-autosuggestions \
  Aloxaf/fzf-tab \
  MichaelAquilina/zsh-you-should-use \
  zsh-users/zsh-history-substring-search

# OMZ (Oh My Zsh) Plugins via Zinit snippets
zinit snippet OMZP::git
zinit snippet OMZP::kubectl
zinit snippet OMZP::npm
zinit snippet OMZP::vscode
zinit snippet OMZP::z
zinit snippet OMZP::sudo
zinit snippet OMZP::archlinux
zinit snippet OMZP::aws
zinit snippet OMZP::kubectx
zinit snippet OMZP::command-not-found

# Replay Zinit history quietly
zinit cdreplay -q

# ---------------------------------------------------------------
# Keybindings
# ---------------------------------------------------------------
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# ---------------------------------------------------------------
# Zsh History Settings
# ---------------------------------------------------------------
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase

# History options
setopt appendhistory           # Append to history file
setopt sharehistory            # Share history between sessions
setopt hist_ignore_space       # Ignore commands with leading spaces
setopt hist_ignore_all_dups    # Ignore all duplicates in history
setopt hist_save_no_dups       # Prevent duplicate entries when saving
setopt hist_ignore_dups        # Ignore duplicate entries during the session
setopt hist_find_no_dups       # Ignore duplicates during history search

# ---------------------------------------------------------------
# Completion Styling and Options
# ---------------------------------------------------------------
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache/
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':compinstall:*' skip 'yes'
zstyle ':autocomplete:*' async true
zstyle ':completion:*' menu no

# Fzf-tab completion preview
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Git VCS info styling
zstyle ':vcs_info:git:*:-all-' get-revision true

# Docker-specific completion options
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes


# ---------------------------------------------------------------
# Tool Initializations (Starship, Zoxide, Fzf)
# ---------------------------------------------------------------
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"  # Initialize Starship prompt
fi

autoload -Uz compinit && compinit -u &!

# Initialize Zoxide for quick directory navigation if available
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"  #Initialize Zoxide
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh >/dev/null 2>&1 &! # Initialize Fzf if available

# ---------------------------------------------------------------
# Load Additional Local Configurations
# ---------------------------------------------------------------
[ -f ~/.aliases_local ] && source ~/.aliases_local
[ -f ~/.zshrc_local ] && source ~/.zshrc_local

# ---------------------------------------------------------------
# Update Zinit Plugins
# ---------------------------------------------------------------
zinit self-update         # Update Zinit itself to the latest version
zinit update --parallel   # Update all Zinit-managed plugins in parallel for efficiency