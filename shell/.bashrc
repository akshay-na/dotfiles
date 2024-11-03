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

# Load common configurations
source ~/.commonrc

# Configure bash history settings
HISTFILE=~/.bash_history                # Path to the history file
export HISTFILESIZE=$HISTSIZE           # Maximum history file size
export HISTCONTROL=ignoreboth:erasedups # Ignore duplicate and blank entries
shopt -s histappend                     # Append to history file, avoid overwriting

# ---------------------------------------------------------------
# Tool Initializations (Starship, Zoxide, Fzf)
# ---------------------------------------------------------------

# Initialize Starship prompt if available
if command -v starship >/dev/null; then
  eval "$(starship init bash)"
fi

# Initialize Zoxide for quick directory navigation if available
if command -v zoxide >/dev/null; then
  eval "$(zoxide init bash)"
fi

# Initialize Fzf if available, with custom completion, key-bindings, and history
if command -v fzf >/dev/null; then
  source "$(fzf --completion=bash --key-bindings --history)"
elif [ -f ~/.fzf.bash ]; then
  # Alternative check if Fzf was manually installed
  source ~/.fzf.bash >/dev/null 2>&1
fi

# ---------------------------------------------------------------
# Load Additional Local Configurations
# ---------------------------------------------------------------
# Load custom local bash configurations, if available
[ -f ~/.aliases_local ] && source ~/.aliases_local
[ -f ~/.bashrc_local ] && source ~/.bashrc_local
