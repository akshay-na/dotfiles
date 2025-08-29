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

  echo_with_color "$YELLOW" "Installing GUI apps via Homebrew Cask..."

  brew install pinentry-mac pam-reattach

  brew install --cask \
    font-caskaydia-cove-nerd-font \
    font-caskaydia-mono-nerd-font \
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

  nohup bash "$DOTFILES_DIR/scripts/resources/default_mac_settings.sh" >"$HOME/.macos_defaults.log" 2>&1 &

  echo_with_color "$GREEN" "macOS setup complete!"
}
