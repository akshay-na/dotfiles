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
if [[ ! -f "$SSH_CONFIG_FILE" ]]; then
  export SSH_CONFIG_FILE="${HOME}/.ssh/config"
fi

# Profiling Zsh
alias profile-zsh="time ZSH_DEBUGRC=1 zsh -i -c exit"

if [[ -n "$ZSH_DEBUGRC" ]]; then
  zmodload zsh/zprof
fi

# Initialize and run compinit quietly in the background
mkdir -p $HOME/.zsh/cache
autoload -Uz compinit bashcompinit
bashcompinit
compinit -C -d "${ZDOTDIR:-$HOME}/.zsh/cache/zcompdump"

# ---------------------------------------------------------------
# Non-Interactive Zsh Options (Always Loaded)
# ---------------------------------------------------------------
# Globbing and redirection options (apply to all shells)
setopt extended_glob     # Enable advanced globbing patterns
setopt null_glob         # Allow unmatched globs to expand to null (empty string)
setopt multios           # Allow multiple redirections (e.g., echo foo >f1 >f2)
setopt glob_dots         # Include dotfiles in glob expansions
setopt numeric_glob_sort # Sort filenames with numbers in numerical order (e.g., 1 2 10)

# Advanced globbing (non-interactive)
setopt ksh_glob               # Ksh-style extended globbing
setopt glob_star_short        # **/ is equivalent to **/*/
setopt brace_ccl              # Enable brace character class lists
setopt magic_equal_subst      # Enable = expansion for filenames

# Smart path expansion (non-interactive)
setopt auto_param_slash       # Add trailing slash to directories
setopt auto_param_keys        # Remove trailing space after completion
setopt mark_dirs              # Mark directories with trailing slash
setopt path_dirs              # Perform path search even on command names

# Smart quoting & expansion (non-interactive)
setopt rc_quotes             # Allow '...' quotes in parameter expansion
setopt prompt_subst          # Enable parameter expansion in prompts
setopt prompt_percent        # Enable % expansion in prompts

# Enhanced directory navigation (non-interactive)
setopt cdable_vars             # Allow cd to variables like cd $HOME
setopt auto_name_dirs          # Auto-create named directories

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
  source "${ZINIT_HOME}/zinit.zsh"

  # ---------------------------------------------------------------
  # Zinit Plugin Loads
  # ---------------------------------------------------------------
  # Load autosuggestions immediately for instant availability
  zinit light-mode for \
    zsh-users/zsh-autosuggestions

  # Load other essential plugins asynchronously for performance
  zinit wait lucid light-mode for \
    zsh-users/zsh-completions \
    zsh-users/zsh-history-substring-search \
    Aloxaf/fzf-tab \
    MichaelAquilina/zsh-you-should-use \
    sunlei/zsh-ssh \
    hlissner/zsh-autopair \
    lukechilds/zsh-better-npm-completion

  # Load syntax highlighting last to avoid conflicts
  zinit wait lucid light-mode for \
    zdharma-continuum/fast-syntax-highlighting

  # Load Oh My Zsh plugin snippets with optimized settings
  zinit wait lucid light-mode for \
    OMZP::git \
    OMZP::kubectl \
    OMZP::docker \
    OMZP::docker-compose \
    OMZP::podman \
    OMZP::npm \
    OMZP::nvm \
    OMZP::terraform \
    OMZP::vscode \
    OMZP::sudo \
    OMZP::jsontools \
    OMZP::archlinux \
    OMZP::brew \
    OMZP::kubectx \
    OMZP::command-not-found

  # Replay Zinit's plugin history quietly
  zinit cdreplay -q

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

  bindkey '^Xe' edit-command-line                         # Ctrl+X/Cmd+X, e: edit command line in external editor
  bindkey '^p' history-search-backward                    # Ctrl+P/Cmd+P: search history backward
  bindkey '^n' history-search-forward                     # Ctrl+N/Cmd+N: search history forward
  bindkey "\e[A" history-substring-search-up              # Up Arrow: search history up
  bindkey "\e[B" history-substring-search-down            # Down Arrow: search history down
  bindkey '^[b' backward-word                             # Alt+B/Cmd+B: move word backward
  bindkey '^[f' forward-word                              # Alt+F/Cmd+F: move word forward
  bindkey '^[^[[D' backward-word                          # Alt+Left/Cmd+Left: move word backward
  bindkey '^[^[[C' forward-word                           # Alt+Right/Cmd+Right: move word forward
  bindkey '^[^?' backward-kill-word                       # Alt+Backspace/Cmd+Backspace: delete word backward
  bindkey '^[d' kill-word                                 # Alt+D/Cmd+D: delete word forward
  bindkey '^[w' kill-region                               # Alt+W/Cmd+W: kill region
  bindkey '^[l' down-case-word                            # Alt+L/Cmd+L: lowercase word
  bindkey '^[u' up-case-word                              # Alt+U/Cmd+U: uppercase word
  bindkey '^[c' capitalize-word                           # Alt+C/Cmd+C: capitalize word
  bindkey '^[t' transpose-words                           # Alt+T/Cmd+T: transpose words
  bindkey '^[m' copy-prev-word                            # Alt+M/Cmd+M: copy previous word
  bindkey '^[[Z' reverse-menu-complete                    # Shift+Tab: reverse menu completion
  bindkey '^[^I' expand-or-complete                       # Alt+Tab/Cmd+Tab: expand or complete

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
  setopt hist_reduce_blanks      # Remove superfluous blanks from history
  setopt hist_expand             # Expand history references when typing
  setopt hist_allow_clobber      # Allow history expansion with > redirection
  setopt hist_no_store           # Don't store history commands in history
  setopt hist_no_functions       # Don't store function definitions in history

  # Directory and navigation options
  setopt auto_cd           # Allow 'cd dir' by typing just 'dir'
  setopt auto_pushd        # Use pushd when changing directories
  setopt pushd_ignore_dups # Don't store duplicates in the directory stack
  setopt pushd_silent      # Don't print the directory stack after pushd/popd

  # Miscellaneous options (interactive only)
  setopt check_jobs  # Warn about running or stopped jobs when exiting the shell
  setopt correct     # Correct commands as they are typed
  setopt correct_all # Correct all arguments

  # Smart completion
  setopt menu_complete           # Show completion menu on first tab
  setopt list_packed             # Compact completion lists
  setopt list_types              # Show file types in completion
  setopt auto_remove_slash       # Remove trailing slash when completing
  setopt complete_in_word        # Complete from middle of word
  setopt always_to_end           # Move cursor to end when completing

  # Job control
  setopt auto_resume            # Resume suspended jobs when typing their name
  setopt long_list_jobs         # List jobs in long format
  setopt notify                 # Report status of background jobs immediately
  setopt bg_nice                # Run background jobs at lower priority

  # ---------------------------------------------------------------
  # Completion Styling and Options
  # ---------------------------------------------------------------
  # Source zstyle configurations from separate file
  [ -f $HOME/.zstyles ] && source $HOME/.zstyles

  # ---------------------------------------------------------------
  # Interactive Tool Initializations
  # ---------------------------------------------------------------

  # mise for managing multiple runtime versions
  if command -v mise >/dev/null; then
    eval "$(mise activate zsh)"
  fi

  # Starship prompt (interactive only)
  if command -v starship >/dev/null; then
    eval "$(starship init zsh)"
  fi

  # Zoxide for quick directory jumping (interactive only)
  if command -v zoxide >/dev/null; then
    eval "$(zoxide init zsh)"
  fi

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
