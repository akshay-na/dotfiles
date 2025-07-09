# ---------------------------------------------------------------
# Bash Configuration and History Settings
# ---------------------------------------------------------------
# Purpose:
# This `.bashrc` script customizes the Bash shell environment by:
# - Sourcing common settings from `.commonrc`.
# - Configuring history settings to avoid duplicates and maintain history size.
# - Initializing tools like Starship, Zoxide, and Fzf for an enhanced shell experience.
# - Loading additional local configurations if they exist.

# Usage:
# Place this file as `.bashrc` in the home directory to configure Bash with
# these settings automatically. Ensure that tools like Starship, Zoxide, and Fzf
# are installed for full functionality. For personal adjustments, add configurations
# in `.bashrc_local` or `.aliases_local`.
# ---------------------------------------------------------------

# Configure bash history settings
HISTFILE="$HOME/.bash_history"          # Path to the history file
export HISTFILESIZE=$HISTSIZE           # Maximum history file size
export HISTCONTROL=ignoreboth:erasedups # Ignore duplicate and blank entries
shopt -s histappend                     # Append to history file, avoid overwriting

# Performance optimizations
shopt -s checkwinsize # Check window size after each command
shopt -s globstar     # Enable ** globbing
shopt -s extglob      # Enable extended globbing

# ---------------------------------------------------------------
# Tool Initializations (Starship, Zoxide, Fzf)
# ---------------------------------------------------------------

# Initialize Starship prompt if available
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
fi

# Initialize Zoxide for quick directory navigation if available
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)" 2>/dev/null || true
fi

# Initialize mise for managing runtimes envs
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)" 2>/dev/null || true
fi

# Initialize Fzf if available, with custom completion, key-bindings, and history
if [ -f $HOME/.fzf.bash ]; then
  # Alternative check if Fzf was manually installed
  source $HOME/.fzf.bash >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------
# Load Additional Local Configurations
# ---------------------------------------------------------------
# Load custom local bash configurations, if available
[ -f $HOME/.commonrc ] && source $HOME/.commonrc
[ -f "$HOME/.bashrc_local" ] && source "$HOME/.bashrc_local"

# ---------------------------------------------------------------
# If zsh is installed and we are not already in zsh, start zsh as a login shell
# ---------------------------------------------------------------
if command -v zsh >/dev/null 2>&1 && [ -z "$ZSH_VERSION" ]; then
  exec zsh -l
fi
