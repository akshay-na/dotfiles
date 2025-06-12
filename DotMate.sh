#!/bin/sh

# Directories and timestamped backup
DOTFILES_DIR=~/dotfiles
BACKUP_DIR=~/dotfiles_backup/$(date +%Y%m%d_%H%M%S)

source ./shell/.functions

# Colors for output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Ask for the administrator password upfront
sudo -v

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
  echo_with_color "$GREEN" "Installing tools and setting up environment..."

  chsh -s "$(which zsh)"

  if [[ "$OSTYPE" == "darwin"* ]]; then
    echo_with_color "$YELLOW" "Detected macOS..."

    # Ensure Homebrew is installed
    if ! command -v brew >/dev/null 2>&1; then
      echo_with_color "$YELLOW" "Homebrew not found. Installing..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi

    echo_with_color "$YELLOW" "Tapping homebrew/cask-fonts..."
    brew tap homebrew/cask-fonts

    echo_with_color "$YELLOW" "Installing CLI & Utilities via Brew..."
    brew install zoxide stow zsh-completions tmux fzf ripgrep eza wget bat coreutils fontconfig mise

    echo_with_color "$GREEN" "macOS setup complete!"

  elif command -v apt >/dev/null 2>&1; then
    echo_with_color "$YELLOW" "Detected Linux with apt..."

    echo_with_color "$YELLOW" "Updating apt and installing base packages..."
    sudo apt update
    sudo apt install -y gpg curl git zsh unzip stow make gcc wget ripgrep eza bat

    sudo install -dm 755 /etc/apt/keyrings
    wget -qO - https://mise.jdx.dev/gpg-key.pub | gpg --dearmor | sudo tee /etc/apt/keyrings/mise-archive-keyring.gpg 1>/dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.gpg arch=amd64] https://mise.jdx.dev/deb stable main" | sudo tee /etc/apt/sources.list.d/mise.list
    sudo apt update
    sudo apt install -y mise tmux zoxide fzf coreutils

    # --- bat (aliased as cat) ---
    echo_with_color "$YELLOW" "Installing bat..."
    # Some distros call the binary 'batcat'
    if [[ ! -x "$(command -v bat)" && -x "$(command -v batcat)" ]]; then
      sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
    fi

    echo_with_color "$GREEN" "Linux setup complete!"

  else
    echo_with_color "$RED" "Unsupported OS or package manager."
    echo_with_color "$RED" "This script supports macOS (Homebrew) or Debian/Ubuntu (apt). Please install the required things manually"
    exit 1
  fi

  # Configure mise and add plugins
  echo_with_color "$YELLOW" "Installing runtimes using mise..."
  mise install

  fc-cache -f -v >/dev/null 2>&1

  echo_with_color "$GREEN" "Setup complete! Restart your terminal to apply changes."
}

# Create symlinks for dotfiles using stow
stow_dotfiles() {
  echo_with_color "$GREEN" "Stowing dotfiles..."
  for dir in "$DOTFILES_DIR"/*/; do
    stow --override=$dir -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
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
    stow --override=$tool -d "$DOTFILES_DIR" -t "$HOME" "$tool"
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
  check_dotfiles_update
  stow_dotfiles
  ;;
install)
  backup_dotfiles
  stow_dotfiles
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
