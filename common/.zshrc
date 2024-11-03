# Load custom aliases if available
[ -f ~/.custom_alias.sh ] && source ~/.custom_alias.sh

# Aliases
alias zi="zoxide query -ls | fzf | xargs -I {} zoxide cd '{}'"

# ---------------------------------------------------------------
# Homebrew Initialization (macOS specific)
# ---------------------------------------------------------------
if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------
# Pyenv Initialization and Installation
# ---------------------------------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Check if pyenv is installed; if not, clone it from GitHub
if ! command -v pyenv >/dev/null 2>&1; then
  git clone https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
fi

# Initialize pyenv
if command -v pyenv >/dev/null; then
  eval "$(pyenv init --path)"
fi

# ---------------------------------------------------------------
# NVM (Node Version Manager) Initialization and Installation
# ---------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"

# Check if nvm is installed; if not, clone it from GitHub
if [ ! -d "$NVM_DIR" ]; then
  git clone https://github.com/nvm-sh/nvm.git "$NVM_DIR"
  cd "$NVM_DIR" && git checkout `git describe --abbrev=0 --tags`
  popd
fi

# Load nvm and its bash completion if available
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ---------------------------------------------------------------
# Zinit Plugin Manager Initialization and Plugins
# ---------------------------------------------------------------
export ZINIT_HOME="${XDG_DATA_HOME:-${HOME}}/.zinit"

# Download Zinit if not already installed
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname $ZINIT_HOME)"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

# Define Zinit plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light MichaelAquilina/zsh-you-should-use
zinit light zsh-users/zsh-history-substring-search

# OMZ plugins (via Zinit snippets)
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

# Load completions
autoload -Uz compinit && compinit

# Zinit replay history quietly
zinit cdreplay -q

# ---------------------------------------------------------------
# Keybindings
# ---------------------------------------------------------------
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# ---------------------------------------------------------------
# Shell History Settings
# ---------------------------------------------------------------
HISTSIZE=10000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# ---------------------------------------------------------------
# Completion Styling and Options
# ---------------------------------------------------------------
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache/
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':autocomplete:*' async true
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'
zstyle ':vcs_info:git:*:-all-' get-revision true
zstyle ':completion:*:*:docker:*' option-stacking yes
zstyle ':completion:*:*:docker-*:*' option-stacking yes

# ---------------------------------------------------------------
# Additional Environment Settings
# ---------------------------------------------------------------
export YSU_MESSAGE_POSITION="after"
export PATH="$PATH:$HOME/.pyenv/bin:$HOME/bin:/opt/nvim-linux64/bin"

# ---------------------------------------------------------------
# Initialize Starship, Zoxide, and Fzf if available
# ---------------------------------------------------------------
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh >/dev/null 2>&1

# ---------------------------------------------------------------
# Directory Navigation Helper
# ---------------------------------------------------------------
fcd() {
  local dir
  dir=$(zoxide query -i --exclude "$HOME") && cd "$dir"
}

# ---------------------------------------------------------------
# Automatically Start Tmux if Not Already Inside a Session
# ---------------------------------------------------------------
if command -v tmux >/dev/null 2>&1; then
  if [[ -z "$TMUX" ]]; then
    tmux attach -t default || tmux new -s default
  fi
fi
