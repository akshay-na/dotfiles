#!/bin/sh

# Colors for output
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Function to echo with color
echo_with_color() {
  echo -e "${1}${2}${RESET}"
}

install_debian() {
  echo_with_color "$YELLOW" "Detected Debian-based Linux..."
  echo_with_color "$YELLOW" "Installing dependencies..."

  sudo apt-get update
  sudo apt-get install -y build-essential procps curl file git zsh

  echo_with_color "$GREEN" "Linux setup complete!"
}
