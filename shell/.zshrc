# ------------------------------------------------------------------------------
# Zsh Environment Initialization Script
# ------------------------------------------------------------------------------
# Purpose:
#   - Sets up Zsh environment, paths, and aliases.
#   - Manages plugins via Zinit.
#   - Configures history options and keybindings.
#   - Initializes various tools (Starship, Zoxide, Fzf).
#   - Loads additional local config if present.
#
# Usage:
#   - Place this file in $HOME as ~/.zshrc.
#   - Ensure required tools (Starship, Zoxide, Fzf) and plugins are installed.
#   - Local overrides: create ~/.aliases_local or ~/.zshrc_local if desired.
# ------------------------------------------------------------------------------

# Initialize and run compinit quietly in the background
mkdir -p ~/.zsh/cache
autoload -Uz compinit bashcompinit
bashcompinit
compinit -d "${ZDOTDIR:-$HOME}/.zsh/cache/zcompdump"

# ------------------------------------------------------------------------------
# 1. Source Common Configuration
# ------------------------------------------------------------------------------
[ -f ~/.commonrc ] && source ~/.commonrc

# ------------------------------------------------------------------------------
# 2. Path / Environment Variables
# ------------------------------------------------------------------------------
export YSU_MESSAGE_POSITION="after"  # Example custom env var

# ------------------------------------------------------------------------------
# 3. Zinit Plugin Manager Setup
# ------------------------------------------------------------------------------
export ZINIT_HOME="${XDG_DATA_HOME:-$HOME}/.zinit"

# Install Zinit if not already installed
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source Zinit
source "${ZINIT_HOME}/zinit.zsh"

# ------------------------------------------------------------------------------
# 4. Zinit Plugin Loads
# ------------------------------------------------------------------------------
# Load essential plugins with optimized settings
zinit wait lucid light-mode for \
  zsh-users/zsh-history-substring-search \
  zsh-users/zsh-completions \
  zsh-users/zsh-autosuggestions \
  zdharma-continuum/fast-syntax-highlighting \
  Aloxaf/fzf-tab \
  MichaelAquilina/zsh-you-should-use \
  sunlei/zsh-ssh \
  hlissner/zsh-autopair \
  lukechilds/zsh-better-npm-completion

# Load Oh My Zsh plugin snippets with optimized settings
zinit wait lucid light-mode for \
  OMZP::git \
  OMZP::kubectl \
  OMZP::npm \
  OMZP::nvm \
  OMZP::terraform \
  OMZP::vscode \
  OMZP::z \
  OMZP::sudo \
  OMZP::jsontools \
  OMZP::archlinux \
  OMZP::aws \
  OMZP::azure \
  OMZP::brew \
  OMZP::gcloud \
  OMZP::kubectx \
  OMZP::command-not-found

# Replay Zinit's plugin history quietly
zinit cdreplay -q

# ------------------------------------------------------------------------------
# 5. Keybindings
# ------------------------------------------------------------------------------
bindkey -e                           # Use Emacs-style keybindings
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey "\e[A" history-substring-search-up
bindkey "\e[B" history-substring-search-down
bindkey "^[OA" history-substring-search-up
bindkey "^[OB" history-substring-search-down
bindkey "\eOA" history-substring-search-up
bindkey "\eOB" history-substring-search-down
bindkey '^[w' kill-region            # Example custom binding

# ------------------------------------------------------------------------------
# 6. Zsh Options & History Settings
# ------------------------------------------------------------------------------
HISTFILE=$HOME/.zsh_history              # Where to store history
SAVEHIST=$HISTSIZE                   # Number of history lines to save
HISTDUP=erase                        # Erase oldest duplicate when a command is repeated

# History-related options
setopt appendhistory            # Append commands to $HISTFILE instead of overwriting it
setopt sharehistory             # Share command history between all sessions
setopt inc_append_history       # Immediately append each command to the history file
setopt hist_ignore_space        # Don't record commands that start with a space
setopt hist_ignore_all_dups     # Remove all older duplicates when a new command is added
setopt hist_save_no_dups        # Don't write duplicate entries to the history file
setopt hist_ignore_dups         # Ignore the command if it matches the previous one
setopt hist_find_no_dups        # Skip duplicate entries when searching through history
setopt hist_expire_dups_first   # Expire duplicate entries first when trimming history
setopt hist_verify              # Load history line into the editor before executing

# Directory and navigation options
setopt auto_cd                  # Allow 'cd dir' by typing just 'dir'
setopt auto_pushd               # Use pushd when changing directories
setopt pushd_ignore_dups        # Don't store duplicates in the directory stack
setopt pushd_silent             # Don't print the directory stack after pushd/popd

# Globbing and redirection options
setopt extended_glob            # Enable advanced globbing patterns
setopt null_glob                # Allow unmatched globs to expand to null (empty string)
setopt multios                  # Allow multiple redirections (e.g., echo foo >f1 >f2)
setopt glob_dots                # Include dotfiles in glob expansions

# Miscellaneous options
setopt check_jobs               # Warn about running or stopped jobs when exiting the shell
setopt numeric_glob_sort        # Sort filenames with numbers in numerical order (e.g., 1 2 10)

# ------------------------------------------------------------------------------
# 7. Completion Styling and Options
# ------------------------------------------------------------------------------
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${ZDOTDIR:-$HOME}/.zsh/cache/"
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|.=* r:|=*' \
  'm:{[:digit:]}={[:digit:]}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':compinstall:*' skip 'yes'
zstyle ':autocomplete:*' async true
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:default' list-grouped true
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*' menu no
zstyle ':completion:*' use-ip true
zstyle ':completion:*' use-perl true
zstyle ':completion:*' rehash true

# Fzf-tab settings
zstyle ':fzf-tab:*' single true
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:*' fzf-minimum-chars 2
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'zoxide query --list'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -lhagH --color=auto --group-directories-first --icons --sort=filename $realpath'
zstyle ':fzf-tab:complete:rm:*' fzf-preview 'eza -lhagH --color=auto --group-directories-first --icons --sort=filename $realpath'

# Git VCS info styling
zstyle ':vcs_info:git:*:-all-' get-revision true

# Docker-specific completion
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# ------------------------------------------------------------------------------
# 8. Tool Initializations (Starship, Zoxide, Fzf, etc.)
# ------------------------------------------------------------------------------
# Starship prompt
if command -v starship >/dev/null; then
  eval "$(starship init zsh)"
fi

# Zoxide for quick directory jumping
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# mise for managing runtimes envs
if command -v mise >/dev/null; then
  eval "$(mise activate zsh)"
fi

# Fzf initialization (if installed)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh >/dev/null 2>&1 &!

# Set WORDCHARS to treat certain punctuation as part of words
# (i.e., do NOT treat '/' as part of a word, so you can easily jump across path segments)
WORDCHARS=".~&!#$%^[](){}<>"

# ------------------------------------------------------------------------------
# 9. Custom Funtions
# ------------------------------------------------------------------------------
_vscode_z() {
  local dir
  if [[ -n "$1" ]]; then
    dir=$(zoxide query "$1")  # Jump directly if an argument is provided
  else
    dir=$(zoxide query -l | fzf)  # Otherwise, show fzf selection
  fi

  if [[ -n "$dir" ]]; then
    code "$dir"
  else
    echo "No directory selected."
  fi
}

alias vz='_vscode_z'

compdef _vscode_z vz

# ------------------------------------------------------------------------------
# 10. Local Overrides
# ------------------------------------------------------------------------------
[ -f ~/.zshrc_local ] && source ~/.zshrc_local

# ------------------------------------------------------------------------------
# 11. Background Plugin Updates
# ------------------------------------------------------------------------------
# Update Zinit itself silently
zinit self-update &> /dev/null &!
zinit update --parallel 30 &> /dev/null &!

# End of ~/.zshrc
# ------------------------------------------------------------------------------
