#!/bin/sh

# Colors for output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

export PATH=$PATH:/opt/homebrew/bin

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
  fi

  echo_with_color "$YELLOW" "Installing fonts..."

  brew install --cask \
    font-caskaydia-cove-nerd-font \
    font-caskaydia-mono-nerd-font

  echo_with_color "$YELLOW" "Installing CLI & Utilities via Brew..."

  brew install \
    zoxide \
    stow \
    zsh-completions \
    tmux \
    fzf \
    ripgrep \
    eza \
    wget \
    bat \
    coreutils \
    fontconfig \
    mise

  echo_with_color "$YELLOW" "Installing GUI apps via Brew Cask..."

  brew install --cask \
    alfred \
    alacritty \
    cursor \
    chatgpt \
    caffeine \
    grammarly-desktop \
    spotify \
    dbgate \
    postman \
    hiddenbar \
    espanso

  echo_with_color "$YELLOW" "Setting Personalized macOS defaults..."
  source "$DOTFILES_DIR/install/default_mac_settings.sh"

  echo_with_color "$GREEN" "macOS setup complete!"
}
