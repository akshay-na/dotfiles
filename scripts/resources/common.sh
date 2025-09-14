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

install_common() {

  # Ensure Homebrew is installed
  if ! command -v brew >/dev/null 2>&1; then
    echo_with_color "$YELLOW" "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # ---------------------------------------------------------------
  # Homebrew Initialization (macOS and Linux)
  # ---------------------------------------------------------------
  # Homebrew Initialization (macOS and Linux)
  if [ -x "/opt/homebrew/bin/brew" ]; then
    # macOS (Apple Silicon)
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || true
  elif [ -x "/usr/local/bin/brew" ]; then
    # macOS (Intel) or Linux (rare)
    eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true
  elif [ -x "$HOME/homebrew/bin/brew" ]; then
    # Linux (user install)
    eval "$($HOME/homebrew/bin/brew shellenv)" 2>/dev/null || true
  elif [ -x "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    # Linux (system-wide)
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
  elif [ -x "$HOME/.linuxbrew/bin/brew" ]; then
    # Linux (alternative user install)
    eval "$($HOME/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
  fi

  echo_with_color "$YELLOW" "Installing CLI & Utilities via Homebrew..."

  if ! command -v mise >/dev/null 2>&1; then
    echo_with_color "$YELLOW" "Mise not found. Installing..."
    curl https://mise.run | bash
  fi

  # CLI and utilities (common to both macOS and Linux)
  # List of packages to install
  BREW_PACKAGES=(
    asciinema
    autossh
    bat
    btop
    coreutils
    curl
    eza
    fontconfig
    fzf
    gcc
    git
    gnupg
    gpg
    lsof
    make
    neofetch
    stow
    tmux
    tree
    unzip
    wget
    zoxide
    zsh
  )

  for pkg in "${BREW_PACKAGES[@]}"; do
    if command -v "$pkg" >/dev/null 2>&1; then
      echo "Already available: $pkg"
    else
      echo "Installing with brew: $pkg"
      brew install "$pkg" || echo "Failed to install: $pkg (continuing...)"
    fi
  done

  echo_with_color "$GREEN" "Common Homebrew package installation complete!"
}
