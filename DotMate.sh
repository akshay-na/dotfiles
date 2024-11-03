#!/bin/sh

# Directories and timestamped backup
DOTFILES_DIR=~/dotfiles
BACKUP_DIR=~/dotfiles_backup/$(date +%Y%m%d_%H%M%S)

# Colors for output
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

# Function to echo with color
echo_with_color() {
    echo -e "${1}${2}${RESET}"
}

# Backup existing dotfiles to avoid data loss
backup_dotfiles() {
    echo_with_color "$GREEN" "Backing up existing dotfiles to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    find "$DOTFILES_DIR" -type f | while read -r file; do
        dest="$HOME/${file#$DOTFILES_DIR/*/}"
        if [ -e "$dest" ]; then
            mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
            cp "$dest" "$BACKUP_DIR/$dest"
            echo_with_color "$YELLOW" "Backed up $dest"
        fi
    done
}

# Check for updates in the dotfiles repository
check_for_update() {
    cd "$DOTFILES_DIR" || exit
    git fetch origin
    if [ "$(git rev-parse @)" != "$(git rev-parse @{u})" ]; then
        echo_with_color "$YELLOW" "Updates available for the dotfiles repository."
        read -p "Do you want to update now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git pull && echo_with_color "$GREEN" "Repository updated."
        fi
    else
        echo_with_color "$GREEN" "Dotfiles repository is up-to-date."
    fi
    cd - >/dev/null || exit
}

# Install necessary tools and set up environment
install() {
    echo_with_color "$GREEN" "Installing tools and setting up environment..."
    sudo apt update && sudo apt install -y curl git zsh fzf tmux zoxide unzip stow make gcc

    if ! command -v nvim >/dev/null 2>&1; then
        curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf nvim-linux64.tar.gz
        rm -rf nvim-linux64.tar.gz
    fi

    # Install Starship if not already installed
    if ! command -v starship >/dev/null 2>&1; then
        curl -sSL https://starship.rs/install.sh | sh || echo_with_color "$RED" "Error installing Starship."
    fi

    fc-cache -f -v >/dev/null 2>&1
    chsh -s "$(which zsh)"
    echo_with_color "$GREEN" "Setup complete! Restart your terminal to apply changes."
}

# Create symlinks for dotfiles using stow
stow_dotfiles() {
    echo_with_color "$GREEN" "Stowing dotfiles..."
    for dir in "$DOTFILES_DIR"/*/; do
        stow --override=$dir -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
    done
}

# Remove symlinks created by stow
unstow_dotfiles() {
    echo_with_color "$RED" "Unstowing dotfiles..."
    for dir in "$DOTFILES_DIR"/*/; do
        stow -D -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
    done
}

# Clean up broken symlinks in the home directory
clean_symlinks() {
    echo_with_color "$YELLOW" "Cleaning up broken symlinks in $HOME"
    find ~ -xtype l -delete
}

# Create symlinks for specific dotfiles (support multiple arguments)
stow_multiple_dotfiles() {
    if [ "$#" -eq 0 ]; then
        echo_with_color "$RED" "No repository or tool specified. Usage: $0 stow <tool1> <tool2> ..."
        exit 1
    fi

    for tool in "$@"; do
        echo_with_color "$GREEN" "Stowing $tool..."
        stow --override=$tool -d "$DOTFILES_DIR" -t "$HOME" "$tool"
    done
}

# Remove symlinks for specific dotfiles (support multiple arguments)
unstow_multiple_dotfiles() {
    if [ "$#" -eq 0 ]; then
        echo_with_color "$RED" "No repository or tool specified. Usage: $0 unstow <tool1> <tool2> ..."
        exit 1
    fi

    for tool in "$@"; do
        echo_with_color "$RED" "Unstowing $tool..."
        stow -D -d "$DOTFILES_DIR" -t "$HOME" "$tool"
    done
}

# Main logic to handle arguments
case "$1" in
backup)
    backup_dotfiles
    ;;
update)
    clean_symlinks
    check_for_update
    ;;
install)
    install
    backup_dotfiles
    stow_dotfiles
    ;;
stow)
    shift
    if [ "$#" -gt 0 ]; then
        stow_multiple_dotfiles "$@"
    else
        stow_dotfiles
    fi
    ;;
unstow)
    clean_symlinks
    shift
    if [ "$#" -gt 0 ]; then
        unstow_multiple_dotfiles "$@"
    else
        unstow_dotfiles
    fi
    ;;
clean)
    clean_symlinks
    ;;
*)
    echo_with_color "$YELLOW" "Usage: $0 {backup|update|install|stow|unstow|clean}"
    exit 1
    ;;
esac

exit 0
