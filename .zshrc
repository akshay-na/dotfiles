# .zshrc file

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the dir where we want to store the zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}}/.zinit"

# Download Zinit, if it's not there yet
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


# OMZ plugins with equivalent `zinit` snippets
zinit snippet OMZP::git            # Git plugin from OMZ
zinit snippet OMZP::kubectl        # Kubectl plugin from OMZ
zinit snippet OMZP::npm            # NPM plugin from OMZ
zinit snippet OMZP::vscode         # VSCode plugin from OMZ
zinit snippet OMZP::z              # Z plugin from OMZ for directory navigation

# Additional OMZ snippets
zinit snippet OMZP::sudo              # Adds functionality to re-run commands with `sudo`
zinit snippet OMZP::archlinux         # Arch Linux plugin for Arch-specific aliases
zinit snippet OMZP::aws               # AWS plugin for AWS CLI aliases and functions
zinit snippet OMZP::kubectx           # Kubectx plugin for Kubernetes context switching
zinit snippet OMZP::command-not-found # Suggests commands when not installed

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

# Keybindings
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
bindkey '^[w' kill-region

# History
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

# Completion styling
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

export YSU_MESSAGE_POSITION="after"

# Aliases
alias ls='ls --color -alh'
alias zi="zoxide query -ls | fzf | xargs -I {} zoxide cd '{}'"
alias vim='nvim'
alias c='clear'

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh >/dev/null 2>&1
[ -f ~/.custom_alias.sh ] && source ~/.custom_alias.sh

export NVM_DIR="$HOME/.nvm"
export PATH="$PATH:$HOME/.pyenv/bin:$HOME/bin:/opt/nvim-linux64/bin"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

fcd() {
  local dir
  dir=$(zoxide query -i --exclude "$HOME") && cd "$dir"
}

# Automatically start Tmux if not already inside a Tmux session
if command -v tmux >/dev/null 2>&1; then
  # Only start Tmux if not already in a Tmux session
  if [[ -z "$TMUX" ]]; then
    tmux attach -t default || tmux new -s default
  fi
fi

