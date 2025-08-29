#!/bin/bash

# Directories and timestamped backup
DOTFILES_DIR=$HOME/dotfiles
BACKUP_DIR=$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)

source $DOTFILES_DIR/shell/.functions

# Colors for output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Function to echo with color
echo_with_color() {
  echo -e "${1}${2}${RESET}"
}

# Backup existing dotfiles to avoid data loss
backup_dotfiles() {
  echo_with_color "$GREEN" "Backing up existing dotfiles to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  find "$DOTFILES_DIR" -type f | while read -r file; do
    dest="$HOME/${file#$DOTFILES_DIR/*/}"
    if [ -e "$dest" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
      cp "$dest" "$BACKUP_DIR/$dest"
      echo_with_color "$YELLOW" "Backed up $dest"
    fi
  done
}

# Install necessary tools and set up environment
install() {
  # Ask for the administrator password upfront
  sudo -v

  echo_with_color "$GREEN" "Installing tools and setting up environment..."

  chmod +x $DOTFILES_DIR/scripts/resources/*

  if [[ "$OSTYPE" == "darwin"* ]]; then
    source "$DOTFILES_DIR/scripts/resources/macos.sh"
    install_macos
  elif command -v apt >/dev/null 2>&1; then
    source "$DOTFILES_DIR/scripts/resources/debian.sh"
    install_debian
  else
    echo_with_color "$RED" "Unsupported OS or package manager."
    echo_with_color "$RED" "This script supports macOS (Homebrew) or Debian/Ubuntu (apt). Please install the required things manually"
    exit 1
  fi

  source "$DOTFILES_DIR/scripts/resources/common.sh"
  install_common

  stow_dotfiles

  git ignore $DOTFILES_DIR/mise/.config/mise/conf.d/global_tools.toml

  # Configure mise and add plugins
  echo_with_color "$YELLOW" "Installing runtimes using mise..."
  if command -v mise >/dev/null 2>&1; then
    mise install
  fi

  # Set permissions for gnupg and ssh folders
  if [ -d "$HOME/.gnupg" ]; then
    chmod 700 "$HOME/.gnupg"
    find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
    find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
  fi
  if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f -exec chmod 600 {} \;
    find "$HOME/.ssh" -type d -exec chmod 700 {} \;
  fi

  chmod +x ~/.local/bin/*

  fc-cache -f -v >/dev/null 2>&1

  chsh -s "$(which zsh)"

  echo_with_color "$GREEN" "Setup complete! Restart your terminal to apply changes."
}

# Create symlinks for dotfiles using stow
stow_dotfiles() {
  echo_with_color "$GREEN" "Stowing dotfiles..."
  for dir in "$DOTFILES_DIR"/*/; do
    stow --no-folding --override=$dir -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
  done
}

# Remove symlinks created by stow
unstow_dotfiles() {
  echo_with_color "$RED" "Unstowing dotfiles..."
  for dir in "$DOTFILES_DIR"/*/; do
    stow -D -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
  done
}

# Clean up broken symlinks in the home directory
clean_symlinks() {
  echo_with_color "$YELLOW" "Cleaning up broken symlinks in $HOME"
  find ~ -xtype l -delete
}

# Create symlinks for specific dotfiles (support multiple arguments)
stow_multiple_dotfiles() {
  if [ "$#" -eq 0 ]; then
    echo_with_color "$RED" "No repository or tool specified. Usage: $0 stow <tool1> <tool2> ..."
    exit 1
  fi

  for tool in "$@"; do
    echo_with_color "$GREEN" "Stowing $tool..."
    stow --no-folding --override=$tool -d "$DOTFILES_DIR" -t "$HOME" "$tool"
  done
}

# Remove symlinks for specific dotfiles (support multiple arguments)
unstow_multiple_dotfiles() {
  if [ "$#" -eq 0 ]; then
    echo_with_color "$RED" "No repository or tool specified. Usage: $0 unstow <tool1> <tool2> ..."
    exit 1
  fi

  for tool in "$@"; do
    echo_with_color "$RED" "Unstowing $tool..."
    stow -D -d "$DOTFILES_DIR" -t "$HOME" "$tool"
  done
}

# Main logic to handle arguments
case "$1" in
backup)
  backup_dotfiles
  ;;
update)
  backup_dotfiles
  check_dotfiles_update
  stow_dotfiles
  ;;
install)
  backup_dotfiles
  install
  ;;
stow)
  shift
  if [ "$#" -gt 0 ]; then
    stow_multiple_dotfiles "$@"
  else
    stow_dotfiles
  fi
  ;;
unstow)
  shift
  if [ "$#" -gt 0 ]; then
    unstow_multiple_dotfiles "$@"
  else
    unstow_dotfiles
  fi
  clean_symlinks
  ;;
clean)
  clean_symlinks
  ;;
*)
  echo_with_color "$YELLOW" "Usage: $0 {backup|update|install|stow|unstow|clean}"
  exit 1
  ;;
esac

exit 0
