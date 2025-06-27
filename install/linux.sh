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
  echo_with_color "$YELLOW" "Detected Linux..."
  echo_with_color "$GREEN" "Linux setup complete!"
}
