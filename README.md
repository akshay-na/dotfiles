# Untitled

# Dotfiles Repository

This repository includes a collection of configuration files (dotfiles) to set up a development environment with custom shell, Git, Neovim, and SSH settings. Follow the instructions below to install and configure these files on your system.

## Contents

- `.zshrc`: Zsh configuration with custom aliases and environment setup.
- `.custom_alias.sh`: Shell script with additional aliases.
- `.gitconfig` & `.gitignore`: Git configuration and global ignore file.
- `.prettierrc`: Prettier configuration file.
- `.tmux.conf`: Configuration for tmux terminal multiplexer.
- `.config/starship.toml`: Configuration for Starship prompt.
- `.config/nvim`: Neovim configuration directory with plugins and custom settings.
- `.ssh/config`: SSH configuration file.
- `setup_debian.sh`: Script to set up the environment on a Debian-based system.

## Installation

### 1. Clone the Repository

```bash
git clone <repository-url> ~/dotfiles
cd ~/dotfiles
```

### 2. Run Setup Script (Debian-Based Systems)

For Debian-based systems, you can use the `setup_debian.sh` script to install essential packages and set up symlinks.

```bash
bash setup_debian.sh
```

This will:

- Install necessary packages for development.
- Symlink configuration files to your home directory.

### 3. Manual Installation

If you’re not using Debian, manually link files to your home directory as follows:

```bash
ln -s ~/dotfiles/.zshrc ~/.zshrc
ln -s ~/dotfiles/.gitconfig ~/.gitconfig
# Repeat for other files as necessary
```

### 4. Neovim Setup

The Neovim configuration is in `.config/nvim`. To set up Neovim with this configuration:

1. Install Neovim.
2. Ensure you have [Packer](https://github.com/wbthomason/packer.nvim) installed for managing plugins.
3. Start Neovim and run `:PackerSync` to install plugins.

### 5. Starship Prompt

If using Starship for your prompt, link the `starship.toml` configuration:

```bash
ln -s ~/dotfiles/.config/starship.toml ~/.config/starship.toml
```

## Custom Aliases and Scripts

- **Aliases**: Additional custom aliases can be found in `.custom_alias.sh`.
- **Git Aliases**: Git-specific aliases are set in `.gitconfig`.

## SSH Configuration

The SSH configuration in `.ssh/config` provides shortcuts for SSH connections. Ensure proper permissions with:

```bash
chmod 600 ~/.ssh/config
```

## License

This repository is licensed under the MIT License. See `LICENSE` for more details.