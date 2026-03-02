# ---------------------------------------------------------------
# Zsh Environment Initialization Script
# ---------------------------------------------------------------
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

set +m

# ---------------------------------------------------------------
# Environment Variables
# ---------------------------------------------------------------
export PROMPT_EOL_MARK=""                          # Configure prompt behavior for clean output
export YSU_MESSAGE_POSITION="after"                # Example custom env var
export ZINIT_HOME="${XDG_DATA_HOME:-$HOME}/.zinit" # Zinit home directory
export SSH_CONFIG_FILE="${HOME}/.ssh/config_local" # SSH config file
export FUNCNEST=200                                # Increase function nesting limit to prevent recursion errors
if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
  export SSH_CONFIG_FILE="${HOME}/.ssh/config"
fi

# Profiling Zsh
alias profile-zsh="time ZSH_DEBUGRC=1 zsh -i -c exit"

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# Initialize and run compinit quietly in the background
mkdir -p $HOME/.zsh/cache $HOME/logs
autoload -Uz compinit bashcompinit add-zsh-hook
bashcompinit

_zn_compdump="${ZDOTDIR:-$HOME}/.zsh/cache/zcompdump"
_zn_compdump_stamp="${_zn_compdump}.timestamp"
_zn_compdump_max_age=$((60 * 60 * 24))

_zn_now=$(date +%s 2>/dev/null)
[[ -n $_zn_now ]] || _zn_now=${EPOCHSECONDS:-0}

if [[ ! -s $_zn_compdump || ! -f $_zn_compdump_stamp ]]; then
  compinit -u -d "$_zn_compdump"
  printf '%s\n' "$_zn_now" >|"$_zn_compdump_stamp"
  zcompile "$_zn_compdump" 2>/dev/null
else
  _zn_last_run=$(<"$_zn_compdump_stamp")
  [[ -n $_zn_last_run ]] || _zn_last_run=0
  compinit -u -d "$_zn_compdump"
  if ((_zn_now - _zn_last_run > _zn_compdump_max_age)); then
    (
      _zn_new_dump="${_zn_compdump}.new"
      compinit -u -d "$_zn_new_dump"
      mv "$_zn_new_dump" "$_zn_compdump"
      zcompile "$_zn_compdump" 2>/dev/null
      printf '%s\n' "$_zn_now" >|"$_zn_compdump_stamp"
    ) &
    command -v disown >/dev/null && disown
  elif [[ ! -s "${_zn_compdump}.zwc" || $_zn_compdump -nt "${_zn_compdump}.zwc" ]]; then
    zcompile "$_zn_compdump" 2>/dev/null
  fi
fi

# ---------------------------------------------------------------
# Non-Interactive and Interactive Zsh Options (Always Loaded)
# ---------------------------------------------------------------
# Globbing and redirection options (apply to all shells)
setopt extended_glob     # Enable advanced globbing patterns
setopt null_glob         # Allow unmatched globs to expand to null (empty string)
setopt multios           # Allow multiple redirections (e.g., echo foo >f1 >f2)
setopt glob_dots         # Include dotfiles in glob expansions
setopt numeric_glob_sort # Sort filenames with numbers in numerical order (e.g., 1 2 10)

# ---------------------------------------------------------------
# Source Common Configurations (Always Loaded)
# ---------------------------------------------------------------
[ -f $HOME/.commonrc ] && source $HOME/.commonrc

# ---------------------------------------------------------------
# Interactive-Only Zsh Configurations
# ---------------------------------------------------------------

if [[ -o interactive ]]; then

  # Install Zinit if not already installed
  if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  fi

  # Source Zinit
  typeset -gA ZINIT
  ZINIT[COMPINIT_OPTS]='-u -C'
  typeset -g skip_global_compinit=1

  source "${ZINIT_HOME}/zinit.zsh"

  # ---------------------------------------------------------------
  # Zinit Plugin Loads
  # ---------------------------------------------------------------
  # Load autosuggestions immediately for instant availability
  zinit light-mode for \
    zsh-users/zsh-autosuggestions OMZP::direnv OMZP::starship

  # Load other essential plugins asynchronously for performance
  zinit wait lucid light-mode for \
    zsh-users/zsh-completions \
    Aloxaf/fzf-tab \
    MichaelAquilina/zsh-you-should-use \
    sunlei/zsh-ssh \
    hlissner/zsh-autopair \
    ianthehenry/zsh-autoquoter \
    lukechilds/zsh-better-npm-completion

  # Load history-substring-search before syntax highlighting to avoid conflicts
  # Set up keybindings after plugin loads to prevent recursion issues
  zinit wait lucid light-mode atload"bindkey '\e[A' history-substring-search-up; bindkey '\e[B' history-substring-search-down" for \
    zsh-users/zsh-history-substring-search

  # Load syntax highlighting last to avoid conflicts
  # Must be loaded after history-substring-search is fully initialized
  zinit wait lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting \
    OMZP::command-not-found

  # Load Oh My Zsh plugin snippets only when their corresponding commands exist
  typeset -a _zn_omzp_plugins=(
    "apt GeoLMg/apt-zsh-plugin"
    "brew OMZP::brew"
    "code OMZP::vscode"
    "git OMZP::git"
    "jq OMZP::jsontools"
    "kubectl OMZP::kubectl"
    "kubectx OMZP::kubectx"
    "mise OMZP::mise"
    "npm OMZP::npm"
    "nvm OMZP::nvm"
    "pacman OMZP::archlinux"
    "podman OMZP::podman"
    "sudo OMZP::sudo"
    "terraform OMZP::terraform"
    "tmux OMZP::tmux"
    "yarn OMZP::yarn"
    "zoxide OMZP::zoxide"
  )

  for _zn_entry in "${_zn_omzp_plugins[@]}"; do
    plugin_cmd="${_zn_entry%% *}"
    plugin_snippet="${_zn_entry#* }"
    if command -v "$plugin_cmd" >/dev/null 2>&1; then
      zinit wait lucid light-mode for "$plugin_snippet"
    fi
  done

  unset _zn_entry _zn_omzp_plugins plugin_cmd plugin_snippet

  # Replay Zinit's plugin history after the first prompt
  _zn_zinit_replay_once() {
    add-zsh-hook -d precmd _zn_zinit_replay_once
    (
      zinit cdreplay -q &
    )
  }

  add-zsh-hook -Uz precmd _zn_zinit_replay_once

  # ---------------------------------------------------------------
  # Keybindings
  # ---------------------------------------------------------------
  bindkey -e # Use Emacs-style keybindings

  # ---------------------------------------------------------------
  # Command Line Editing
  # ---------------------------------------------------------------
  # Edit command line in external editor
  autoload -Uz edit-command-line
  zle -N edit-command-line

  bindkey '^Xe' edit-command-line      # Ctrl+X/Cmd+X, e: edit command line in external editor
  bindkey '^p' history-search-backward # Ctrl+P/Cmd+P: search history backward
  bindkey '^n' history-search-forward  # Ctrl+N/Cmd+N: search history forward
  bindkey '^[b' backward-word          # Alt+B/Cmd+B: move word backward
  bindkey '^[f' forward-word           # Alt+F/Cmd+F: move word forward
  bindkey '^[^[[D' backward-word       # Alt+Left/Cmd+Left: move word backward
  bindkey '^[^[[C' forward-word        # Alt+Right/Cmd+Right: move word forward
  bindkey '^[^?' backward-kill-word    # Alt+Backspace/Cmd+Backspace: delete word backward
  bindkey '^[d' kill-word              # Alt+D/Cmd+D: delete word forward
  bindkey '^[w' kill-region            # Alt+W/Cmd+W: kill region
  bindkey '^[l' down-case-word         # Alt+L/Cmd+L: lowercase word
  bindkey '^[u' up-case-word           # Alt+U/Cmd+U: uppercase word
  bindkey '^[c' capitalize-word        # Alt+C/Cmd+C: capitalize word
  bindkey '^[t' transpose-words        # Alt+T/Cmd+T: transpose words
  bindkey '^[m' copy-prev-word         # Alt+M/Cmd+M: copy previous word
  bindkey '^[[Z' reverse-menu-complete # Shift+Tab: reverse menu completion
  bindkey '^[^I' expand-or-complete    # Alt+Tab/Cmd+Tab: expand or complete

  # ---------------------------------------------------------------
  # Zsh Options & History Settings (Interactive Only)
  # ---------------------------------------------------------------
  HISTFILE=$HOME/.zsh_history # Where to store history
  SAVEHIST=$HISTSIZE          # Number of history lines to save
  HISTDUP=erase               # Erase oldest duplicate when a command is repeated

  # History-related options
  setopt appendhistory          # Append commands to $HISTFILE instead of overwriting it
  setopt sharehistory           # Share command history between all sessions
  setopt inc_append_history     # Immediately append each command to the history file
  setopt hist_ignore_space      # Don't record commands that start with a space
  setopt hist_ignore_all_dups   # Remove all older duplicates when a new command is added
  setopt hist_save_no_dups      # Don't write duplicate entries to the history file
  setopt hist_ignore_dups       # Ignore the command if it matches the previous one
  setopt hist_find_no_dups      # Skip duplicate entries when searching through history
  setopt hist_expire_dups_first # Expire duplicate entries first when trimming history
  setopt hist_verify            # Load history line into the editor before executing

  # Directory and navigation options
  setopt auto_cd           # Allow 'cd dir' by typing just 'dir'
  setopt auto_pushd        # Use pushd when changing directories
  setopt pushd_ignore_dups # Don't store duplicates in the directory stack
  setopt pushd_silent      # Don't print the directory stack after pushd/popd

  # Miscellaneous options (interactive only)
  setopt check_jobs  # Warn about running or stopped jobs when exiting the shell
  setopt correct     # Correct commands as they are typed
  setopt correct_all # Correct all arguments

  # ---------------------------------------------------------------
  # Completion Styling and Options
  # ---------------------------------------------------------------
  # Source zstyle configurations from separate file
  [ -f $HOME/.zstyles ] && source $HOME/.zstyles

  # Set WORDCHARS to treat certain punctuation as part of words
  WORDCHARS=".~&!#$%^[](){}<>"

  # ---------------------------------------------------------------
  # Custom Functions (Interactive Only)
  # ---------------------------------------------------------------
  # VSCode directory jumping alias (function defined in .functions)
  if typeset -f _vscode_z >/dev/null; then
    alias vz='_vscode_z'
    compdef _vscode_z vz
  fi

  if [ -z "$TMUX" ] && [ -z "$TMUX_AUTOSTART" ] && command -v tmux >/dev/null; then
    _zn_auto_tmux_attach() {
      export TMUX_AUTOSTART=true
      tmux attach -t default 2>/dev/null || tmux new -s default
      unset TMUX_AUTOSTART
      add-zsh-hook -d precmd _zn_auto_tmux_attach
    }
    add-zsh-hook -Uz precmd _zn_auto_tmux_attach
  fi
fi

# ---------------------------------------------------------------
# Load Local Configurations
# ---------------------------------------------------------------
[ -f $HOME/.zshrc_local ] && source $HOME/.zshrc_local

# Profiling Zsh
if [[ -n "$ZSH_DEBUGRC" ]]; then
  zprof
fi

set -m

# End of ~/.zshrc
# ---------------------------------------------------------------
