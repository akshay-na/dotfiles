#!/bin/sh

# Colors for output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Function to echo with color
echo_with_color() {
  echo -e "${1}${2}${RESET}"
}

install_macos() {
  echo_with_color "$YELLOW" "Detected macOS..."

  # Ensure Homebrew is installed
  if ! command -v brew >/dev/null 2>&1; then
    echo_with_color "$YELLOW" "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    source $HOME/.zshrc
  fi

  echo_with_color "$YELLOW" "Tapping homebrew/cask-fonts..."
  brew tap homebrew/cask-fonts
  brew tap homebrew/cask-versions

  brew install --cask font-caskaydia-cove-nerd-font
  brew install --cask font-caskaydia-mono-nerd-font
  brew install --cask font-caskaydia-mono-nerd-font-mono

  echo_with_color "$YELLOW" "Installing CLI & Utilities via Brew..."
  brew install zoxide stow zsh-completions tmux fzf ripgrep eza wget bat coreutils fontconfig mise

  echo_with_color "$YELLOW" "Installing GUI apps via Brew Cask..."

  brew install --cask \
    alfred \
    alacritty \
    cursor \
    chatgpt \
    google-chrome \
    caffeine \
    grammarly-desktop \
    bitwarden \
    spotify \
    mongodb-compass \
    postman \
    hiddenbar \
    tinkertool \
    espanso

  source "$DOTFILES_DIR/install/default_mac_settings.sh"

  echo_with_color "$GREEN" "macOS setup complete!"
}
