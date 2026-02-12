#!/bin/bash

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

  brew install pinentry-mac pam-reattach zsh

  BREW_CASK_PACKAGES=(
    alfred
    alacritty
    bitwarden
    cursor
    chatgpt-atlas
    caffeine
    dbgate
    discord
    drawio
    elasticvue
    espanso
    font-caskaydia-cove-nerd-font
    font-caskaydia-mono-nerd-font
    grammarly-desktop
    google-chrome
    hammerspoon
    hiddenbar
    logitech-g-hub
    obsidian
    postman
    spotify
    switchhosts
  )

  for pkg in "${BREW_PACKAGES[@]}"; do
    if command -v "$pkg" >/dev/null 2>&1; then
      echo "Already available: $pkg"
    else
      echo "Installing with brew: $pkg"
      brew install --cask "$pkg" || echo "Failed to install: $pkg (continuing...)"
    fi
  done

  echo_with_color "$YELLOW" "Setting Personalized macOS defaults..."

  nohup bash "$DOTFILES_DIR/scripts/resources/default_mac_settings.sh" >"$HOME/.macos_defaults.log" 2>&1 &

  echo_with_color "$GREEN" "macOS setup complete!"
}
