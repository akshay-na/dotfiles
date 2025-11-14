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

  # Update package list and install build-essential, procps, curl, file, and git
  sudo apt-get update
  sudo apt-get install -y build-essential procps curl make wget file git zsh tmux stow

  # Add Linuxbrew to PATH
  sudo tee /etc/profile.d/linuxbrew.sh >/dev/null <<'EOF'
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"
export MANPATH="/home/linuxbrew/.linuxbrew/share/man:$MANPATH"
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:$INFOPATH"
EOF

  # Source Linuxbrew profile
  sudo chmod +x /etc/profile.d/linuxbrew.sh
  source /etc/profile.d/linuxbrew.sh

  echo_with_color "$GREEN" "Linux setup complete!"
}
