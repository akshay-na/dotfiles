#!/bin/sh

# Colors for output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Function to echo with color
echo_with_color() {
  echo -e "${1}${2}${RESET}"
}

install_linux() {
  echo_with_color "$YELLOW" "Detected Linux with apt..."

  echo_with_color "$YELLOW" "Updating apt and installing base packages..."
  sudo apt update
  sudo apt install -y gpg curl git zsh unzip stow make gcc wget ripgrep eza bat tmux zoxide fzf coreutils

  # --- bat (aliased as cat) ---
  echo_with_color "$YELLOW" "Installing bat..."
  # Some distros call the binary 'batcat'
  if [[ ! -x "$(command -v bat)" && -x "$(command -v batcat)" ]]; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
  fi

  echo_with_color "$GREEN" "Linux setup complete!"
}
