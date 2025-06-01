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
check_dotfiles_update() {
    # Run in a subshell to avoid changing the current directory in the parent shell

    # Checks if the dotfiles repository is up-to-date and prompts for update if not
    cd "$DOTFILES_DIR" || return
    git fetch origin

    # Check if the local branch is behind the remote branch
    BEHIND_COUNT=$(git rev-list --count HEAD..origin/$(git rev-parse --abbrev-ref HEAD))

    # If there are commits in the remote that aren't in the local branch, prompt the user
    if [ "$BEHIND_COUNT" -gt 0 ]; then
        echo "\n\n🚀 Updates are available for your dotfiles repository!\n"

        # Create a nicely formatted box for the update prompt
        echo "┌──────────────────────────────────────────────┐"
        echo "│                                              │"
        echo "│   🌟 New updates have been detected! 🌟     │"
        echo "│                                              │"
        echo "│   Take a moment to review the changes:       │"
        echo "│                                              │"
        echo "└──────────────────────────────────────────────┘"

        # Show a summary of incoming changes for better user context
        echo "\nHere's a summary of new changes:"
        LOCAL=$(git rev-parse @)
        REMOTE=$(git rev-parse "@{u}")
        git log --oneline --decorate --color "$LOCAL..$REMOTE"

        # Prompt for update
        echo -e "\nDo you want to update now? (y/n):"
        read -r REPLY
        echo # Move to a new line
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git pull
            echo "✅ Dotfiles repository updated successfully!"
        else
            echo "🚫 Update skipped. Remember to update later to stay in sync!"
        fi
    fi

}
# Install necessary tools and set up environment
install() {
    echo_with_color "$GREEN" "Installing tools and setting up environment..."

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

    chsh -s "$(which zsh)"

    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo_with_color "$YELLOW" "Detected macOS..."

        # Ensure Homebrew is installed
        if ! command -v brew >/dev/null 2>&1; then
            echo_with_color "$YELLOW" "Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        echo_with_color "$YELLOW" "Tapping homebrew/cask-fonts..."
        brew tap homebrew/cask-fonts

        echo_with_color "$YELLOW" "Installing CLI & Utilities via Brew..."
        brew install zoxide zsh-completions tmux fzf ripgrep eza wget bat coreutils fontconfig asdf

        echo_with_color "$GREEN" "macOS setup complete!"

    elif command -v apt >/dev/null 2>&1; then
        echo_with_color "$YELLOW" "Detected Linux with apt..."

        echo_with_color "$YELLOW" "Updating apt and installing base packages..."
        sudo apt update
        sudo apt install -y curl git zsh fzf tmux zoxide unzip stow make gcc wget ripgrep eza bat coreutils

        # --- asdf  ---
        echo_with_color "$YELLOW" "Installing asdf..."
        # Install asdf if not already present
        if [ ! -d "~/.asdf" ]; then
            echo_with_color "$YELLOW" "Installing asdf..."
            git clone https://github.com/asdf-vm/asdf.git ~/.asdf || echo_with_color "$RED" "Error cloning asdf repository."
        fi

        # --- bat (aliased as cat) ---
        echo_with_color "$YELLOW" "Installing bat..."
        # Some distros call the binary 'batcat'
        if [[ ! -x "$(command -v bat)" && -x "$(command -v batcat)" ]]; then
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        fi

        echo_with_color "$GREEN" "Linux setup complete!"

    else
        echo_with_color "$RED" "Unsupported OS or package manager."
        echo_with_color "$RED" "This script supports macOS (Homebrew) or Debian/Ubuntu (apt). Please install the required things manually"
        exit 1
    fi

    # Configure asdf and add plugins
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
    asdf plugin add python https://github.com/danhper/asdf-python.git
    asdf plugin add java https://github.com/halcyon/asdf-java.git
    asdf plugin add terraform https://github.com/asdf-community/asdf-hashicorp.git
    asdf plugin add kubectl https://github.com/asdf-community/asdf-kubectl.git
    asdf plugin add awscli https://github.com/MetricMike/asdf-awscli.git
    asdf plugin add gcloud https://github.com/jthegedus/asdf-gcloud.git
    asdf plugin add azcli https://github.com/mutemutsa/asdf-azcli.git

    fc-cache -f -v >/dev/null 2>&1

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
    check_dotfiles_update
    ;;
install)
    install
    backup_dotfiles
    stow_dotfiles
    ;;
stow)
    check_dotfiles_update
    shift
    if [ "$#" -gt 0 ]; then
        stow_multiple_dotfiles "$@"
    else
        stow_dotfiles
    fi
    ;;
unstow)
    shift
    if [ "$#" -gt 0 ]; then
        unstow_multiple_dotfiles "$@"
    else
        unstow_dotfiles
    fi
    clean_symlinks
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
