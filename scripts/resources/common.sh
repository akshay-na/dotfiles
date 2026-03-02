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
    curl https://mise.run | sh
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
    direnv
    duf
    eza
    figlet
    fontconfig
    fzf
    gcc
    git-delta
    git
    gnupg
    gpg
    jesseduffield/lazydocker/lazydocker
    jq
    kha7iq/tap/pingme
    lazydocker
    lazygit
    logrotate
    lolcat
    lnav
    lsof
    make
    neofetch
    neovim
    rsync
    starship
    stow
    tmux
    topgrade
    tree
    unzip
    wget
    xq
    xxh
    yq
    zoxide
  )

  for pkg in "${BREW_PACKAGES[@]}"; do
    if command -v "$pkg" >/dev/null 2>&1; then
      echo "Already available: $pkg"
    else
      echo "Installing with brew: $pkg"
      brew install "$pkg" || echo "Failed to install: $pkg (continuing...)"
    fi
  done

  # Configure logrotate
  mkdir -p $HOME/logs

  if ! command -v bws >/dev/null 2>&1; then
    echo_with_color "$YELLOW" "Installing Bitwarden Secrets Manager CLI (bws)..."

    OS_NAME="$(uname -s)"
    ARCH_NAME="$(uname -m)"
    BWS_URL=""

    case "$OS_NAME" in
    Darwin)
      if [ "$ARCH_NAME" = "arm64" ]; then
        BWS_URL="https://github.com/bitwarden/sdk-sm/releases/download/bws-v1.0.0/bws-aarch64-apple-darwin-1.0.0.zip"
      else
        BWS_URL="https://github.com/bitwarden/sdk-sm/releases/download/bws-v1.0.0/bws-macos-universal-1.0.0.zip"
      fi
      ;;
    Linux)
      BWS_URL="https://github.com/bitwarden/sdk-sm/releases/download/bws-v1.0.0/bws-x86_64-unknown-linux-gnu-1.0.0.zip"
      ;;
    esac

    if [ -z "$BWS_URL" ]; then
      echo_with_color "$YELLOW" "Skipping bws install: unsupported platform ($OS_NAME/$ARCH_NAME)."
    else
      TMP_DIR="$(mktemp -d)"
      BWS_ZIP="$TMP_DIR/bws.zip"

      if curl -fsSL "$BWS_URL" -o "$BWS_ZIP"; then
        if unzip -o "$BWS_ZIP" -d "$TMP_DIR" >/dev/null; then
          INSTALL_DIR="$HOME/.local/bin"
          mkdir -p "$INSTALL_DIR"

          BWS_BINARY="$(find "$TMP_DIR" -type f -name bws | head -n1)"
          if [ -n "$BWS_BINARY" ]; then
            chmod +x "$BWS_BINARY"
            mv "$BWS_BINARY" "$INSTALL_DIR/bws"
            echo_with_color "$GREEN" "bws installed to $INSTALL_DIR/bws"
          else
            echo_with_color "$YELLOW" "bws binary not found after extraction."
          fi
        else
          echo_with_color "$YELLOW" "Failed to unzip bws archive."
        fi
      else
        echo_with_color "$YELLOW" "Failed to download bws from $BWS_URL."
      fi

      rm -rf "$TMP_DIR"
    fi
  else
    echo "Already available: bws"
  fi

  echo_with_color "$GREEN" "Common Homebrew package installation complete!"
}
