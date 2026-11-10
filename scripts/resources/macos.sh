#!/bin/bash

# Colors for output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
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

  _dotfiles_root="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
  brew bundle --no-lock --file="$_dotfiles_root/scripts/resources/Brewfile.macos" ||
    echo "Failed to install some casks from Brewfile.macos (continuing...)"
  unset _dotfiles_root

  # Brew can outlive the sudo timestamp from DotMate.sh; re-prompt in the
  # foreground (TTY) before defaults — never background this (sudo can't prompt).
  echo_with_color "$YELLOW" "Caching sudo credentials (foreground)..."
  if ! sudo -v; then
    echo_with_color "$RED" "Failed to cache sudo credentials; skipping macOS defaults."
    echo_with_color "$RED" "Re-run defaults later: bash \"$DOTFILES_DIR/scripts/resources/default_mac_settings.sh\""
    return 1
  fi

  # Keep-alive: refresh sudo timestamp until this function finishes.
  while true; do
    sudo -n true
    sleep 50
    kill -0 "$$" || exit
  done 2>/dev/null &
  _sudo_keepalive_pid=$!
  _cleanup_macos_sudo_keepalive() {
    if [[ -n "${_sudo_keepalive_pid:-}" ]]; then
      kill "$_sudo_keepalive_pid" 2>/dev/null || true
      wait "$_sudo_keepalive_pid" 2>/dev/null || true
      _sudo_keepalive_pid=""
    fi
  }
  trap '_cleanup_macos_sudo_keepalive' EXIT

  echo_with_color "$YELLOW" "Setting Personalized macOS defaults..."
  bash "$DOTFILES_DIR/scripts/resources/default_mac_settings.sh" 2>&1 | tee "$HOME/.macos_defaults.log"
  _defaults_status=${PIPESTATUS[0]}

  _cleanup_macos_sudo_keepalive
  trap - EXIT

  if [[ "$_defaults_status" -ne 0 ]]; then
    echo_with_color "$RED" "macOS defaults script failed (exit $_defaults_status); see ~/.macos_defaults.log"
    return "$_defaults_status"
  fi

  echo_with_color "$GREEN" "macOS setup complete!"
}
