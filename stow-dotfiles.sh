#!/bin/sh

# Set up directories and timestamped backup location
DOTFILES_DIR=~/dotfiles # Root directory containing all dotfiles packages
BACKUP_DIR=~/dotfiles_backup/$(date +%Y%m%d_%H%M%S)

chmod 700 ~/dotfiles/gnupg/.gnupg
chmod 600 ~/dotfiles/gnupg/.gnupg/*
chmod 600 ~/dotfiles/ssh/.ssh/config

# Function to create a backup of existing dotfiles that will be replaced
backup_dotfiles() {
    echo "Backing up existing dotfiles to $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Iterate over each package in DOTFILES_DIR and back up existing files
    for package in "$DOTFILES_DIR"/*; do
        [ -d "$package" ] || continue # Skip if not a directory (package)

        # Find all files in the package and back up if they exist in home directory
        find "$package" -type f | while read -r file; do
            dest="$HOME/${file#$DOTFILES_DIR/*/}" # Destination path in home directory

            # Copy to backup if file exists in home directory
            if [ -e "$dest" ]; then
                mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
                cp "$dest" "$BACKUP_DIR/$dest"
                echo "Backed up $dest"
            fi
        done
    done
}

# Function to stow all dotfiles by creating symlinks in the target directory (home)
stow_dotfiles() {
    echo "Stowing dotfiles..."
    cd "$DOTFILES_DIR" || exit

    # Stow each package directory in DOTFILES_DIR
    for dir in */; do
        [ -d "$dir" ] && stow "$dir"
    done
}

# Function to unstow all dotfiles by removing symlinks in the target directory
unstow_dotfiles() {
    echo "Unstowing dotfiles..."
    cd "$DOTFILES_DIR" || exit

    # Unstow each package directory
    for dir in */; do
        [ -d "$dir" ] && stow -D "$dir"
    done
}

# Function to clean up broken symlinks in the home directory
clean_symlinks() {
    echo "Cleaning up broken symlinks in $HOME"
    find ~ -xtype l -delete
}

# Main script logic to handle arguments
case "$1" in
backup)
    backup_dotfiles
    ;;
stow)
    stow_dotfiles
    ;;
unstow)
    unstow_dotfiles
    ;;
clean)
    clean_symlinks
    ;;
*)
    echo "Usage: $0 {backup|stow|unstow|clean}"
    exit 1
    ;;
esac
