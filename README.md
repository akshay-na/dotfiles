# DotMate 🛠️ — Your Companion for Effortless Dotfile Management

Welcome to **DotMate**, a comprehensive dotfiles management system that provides a streamlined solution for managing and syncing configurations across multiple systems. Whether you're setting up a new machine, organizing configurations, or maintaining consistency across environments, DotMate simplifies the entire process with automated tool installation, intelligent backups, and seamless configuration management.

---

## 🌟 What's Included

DotMate comes with a curated collection of configurations for popular development tools and utilities:

### 🖥️ **Terminal & Shell**

- **Shell Configurations**: Zsh, Bash with optimized settings, aliases, and functions
- **Advanced Completion System**:
  - Fzf-tab integration for fuzzy completion with previews
  - Smart completion caching with automatic rehashing
  - Comprehensive completion styles for development tools (Git, Docker, Kubernetes, etc.)
  - Package manager completions (npm, yarn, cargo, pip, etc.)
- **Zsh Plugins**:
  - Zinit plugin manager with async loading
  - Syntax highlighting, autosuggestions, and history search
  - Auto-pairing, auto-quoting, and command correction
  - SSH completion and better npm completion
- **Terminal Emulators**: Alacritty, WezTerm with custom themes and configurations
- **Shell Tools**: Starship prompt, Zoxide for smart directory jumping, Fzf for fuzzy finding
- **Terminal Multiplexer**: Tmux with optimized configuration and plugin management

### 🎨 **Development Environment**

- **Editor**: Neovim with Lazy.nvim plugin manager and custom configurations
- **IDE**: Cursor editor with custom rules and MCP configuration
- **Fonts**: Caskaydia Cove and Mono Nerd Fonts for optimal terminal experience

### 🛠️ **Development Tools**

- **Version Control**: Git with global configurations, attributes, and commit templates
- **Package Managers**:
  - Mise for runtime management (Node.js, Python, Go, etc.)
  - NPM with custom configurations
  - Yarn with optimized settings
- **Container Tools**: Podman with optimized container configurations
- **Database**: DBGate with custom settings

### 🔐 **Security & Authentication**

- **SSH**: Optimized SSH client configuration with socket management
- **GPG**: GPG agent configuration for secure key management
- **Font Configuration**: System-wide font management

### 🚀 **System Utilities**

- **The Fuck**: Command correction utility
- **Font Management**: Fontconfig with custom font installations
- **Cross-platform Support**: macOS and Linux (Debian/Ubuntu) automation

---

## 🚀 Getting Started

### Prerequisites

- **Linux**: Debian/Ubuntu-based systems with `apt` package manager
- **macOS**: macOS 10.15+ with Homebrew support
- **Windows**: WSL2 with Ubuntu (recommended)

### Step 1: Clone the Repository

```bash
git clone https://github.com/akshay-na/DotMate.git ~/dotfiles
cd ~/dotfiles
```

### Step 2: Install DotMate

Run the complete setup with:

```bash
sudo apt install make  # On Linux
make install
```

This command:

- **Detects your operating system** and installs appropriate tools
- **Installs essential development tools** via Homebrew (macOS) or apt (Linux)
- **Backs up existing configurations** to prevent data loss
- **Creates symlinks** for all configurations using GNU Stow
- **Sets up development runtimes** via Mise
- **Configures fonts** and system preferences

**Need only the configurations?** Use:

```bash
make stow
```

This skips tool installation and only creates symlinks for your dotfiles.

---

## 📋 Available Commands

### Core Operations

| Command                              | Description                                     |
| ------------------------------------ | ----------------------------------------------- |
| `make install`                       | Complete setup: install tools + create symlinks |
| `make stow`                          | Create symlinks for all configurations          |
| `make stow CONFIGS="git nvim shell"` | Create symlinks for specific tools only         |
| `make unstow`                        | Remove all symlinks                             |
| `make unstow CONFIGS="git nvim"`     | Remove symlinks for specific tools              |
| `make backup`                        | Backup existing configurations                  |
| `make update`                        | Check for updates and reapply configurations    |
| `make clean`                         | Clean up broken symlinks                        |
| `make help`                          | Show all available commands                     |

### Selective Configuration

Apply only the configurations you need:

```bash
# Set up just Git and Neovim
make stow CONFIGS="git nvim"

# Set up shell and terminal configurations
make stow CONFIGS="shell alacritty wezterm"

# Set up development tools
make stow CONFIGS="mise node python"
```

---

## 🧩 Configuration Details

### Shell Environment (`.shell/`)

- **Zsh Configuration** (`.zshrc`):
  - Zinit plugin manager with async loading for performance
  - Advanced completion system with fzf-tab integration
  - Smart completion caching with automatic rehashing for new commands
  - Comprehensive plugin ecosystem (syntax highlighting, autosuggestions, history search)
  - Optimized startup performance with background initialization
- **Zsh Completion Styling** (`.zstyles`):
  - Centralized completion style configurations
  - Fzf-tab previews for files, directories, Git operations, and more
  - Tool-specific completions (Docker, Kubernetes, package managers, etc.)
  - Performance optimizations with caching
- **Bash Configuration** (`.bashrc`):
  - Compatible configuration with common aliases and functions
  - Shared initialization with Zsh via `.commonrc`
- **Common Configuration** (`.commonrc`):
  - Shared environment variables, paths, and tool initializations
  - Homebrew, editor detection, and tool setup
  - Cross-platform compatibility (macOS/Linux)
- **Aliases** (`.aliases`):
  - Comprehensive collection of useful command shortcuts
  - Git, npm, system, and development tool aliases
- **Functions** (`.functions`):
  - Custom shell functions for development workflows
  - Utility functions for common tasks
- **Tmux Configuration** (`.tmux.conf`):
  - Optimized settings for local and remote sessions
  - Plugin management with TPM
  - Clipboard integration and mouse support

### Neovim (`.nvim/`)

- **Plugin Manager**: Lazy.nvim for fast plugin loading
- **Configuration**: Lua-based configuration with modular structure
- **Code Formatting**: Stylua integration for consistent code style

### Terminal Configurations

- **Alacritty**: Fast GPU-accelerated terminal with custom themes
- **WezTerm**: Feature-rich terminal with custom keybindings and appearance

### Development Tools

- **Mise**: Runtime version management for multiple languages
- **Git**: Global configuration with useful aliases and templates
- **Node.js**: NPM and Yarn configurations for package management
- **Python**: Pip configuration and virtual environment setup

### System Integration

- **Fonts**: Nerd Fonts for terminal and development tools
- **SSH**: Optimized client configuration with socket management
- **GPG**: Secure key management and agent configuration
- **Podman**: Container runtime with optimized settings

---

## 🔧 Customization

### Local Overrides

Create local configuration files to override defaults without affecting the repository:

| Configuration   | Local Override File                                         |
| --------------- | ----------------------------------------------------------- |
| `.gitconfig`    | `~/.gitconfig_local`                                        |
| `starship.toml` | `~/.config/starship_local.toml`                             |
| `.zshrc`        | `~/.zshrc_local`                                            |
| `.zstyles`      | Not supported (edit directly or override in `.zshrc_local`) |
| `.bashrc`       | `~/.bashrc_local`                                           |
| `.commonrc`     | `~/.commonrc_local`                                         |
| `.aliases`      | `~/.aliases_local`                                          |
| `.functions`    | `~/.functions_local`                                        |
| `.tmux.conf`    | Not supported (edit directly)                               |

**Example**: Add custom Starship prompt configuration:

```bash
# Create local override
cp ~/.config/starship/starship.toml ~/.config/starship_local.toml

# Edit local file with your customizations
nano ~/.config/starship_local.toml
```

### Adding New Configurations

1. Create a new directory in the repository root
2. Add your configuration files
3. Update `.stowrc` if needed to exclude certain files
4. Use `make stow CONFIGS="your_config"` to apply

---

## 🛡️ Security Features

- **Automatic Permissions**: Sets correct permissions for SSH and GPG directories
- **Secure Backups**: Timestamped backups prevent accidental data loss
- **Isolated Configurations**: Each tool's configuration is isolated and manageable
- **Permission Management**: Strict file permissions for sensitive configurations

---

## 🔄 Update Management

### Automatic Updates

DotMate includes an auto-update feature that notifies you of available updates:

```bash
make update
```

This command:

- Backs up current configurations
- Checks for repository updates
- Reapplies all configurations
- Maintains your local customizations

### Manual Updates

```bash
# Pull latest changes
git pull origin main

# Reapply configurations
make stow
```

---

## 💡 Tips & Best Practices

### Performance Optimization

- **Lazy Loading**: Shell plugins load asynchronously for faster startup
- **Conditional Loading**: Tools only initialize when available
- **Background Updates**: Non-blocking update checks
- **Completion Caching**: Smart completion system with automatic rehashing
- **Async Plugin Loading**: Zinit plugins load in background for instant shell startup

### Troubleshooting

- **Broken Symlinks**: Use `make clean` to remove broken symlinks
- **Permission Issues**: Run `make install` to reset permissions
- **Backup Recovery**: Check `~/dotfiles_backup/<timestamp>/` for previous configurations
- **Stale Completions**: Delete `~/.zsh/cache/zcompdump*` and reload shell to rebuild completions
- **Missing Command Completions**: The completion system automatically detects new commands; if needed, run `rehash` manually

### Cross-Platform Usage

- **macOS**: Full Homebrew integration with GUI app installation
- **Linux**: Optimized for Debian/Ubuntu with apt package management
- **WSL**: Full Linux compatibility with Windows integration

---

## 🤝 Contributing

DotMate is open-source and welcomes contributions!

### How to Contribute

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup

```bash
# Clone your fork
git clone https://github.com/your-username/DotMate.git
cd DotMate

# Set up upstream
git remote add upstream https://github.com/akshay-na/DotMate.git

# Create feature branch
git checkout -b feature/your-feature
```

---

## 📜 License

DotMate is licensed under the **GNU General Public License v3.0** (GPL-3.0). See the [LICENSE](LICENSE) file for full details.

---

## 🙏 Acknowledgments

- **GNU Stow**: For elegant symlink management
- **Homebrew**: For cross-platform package management
- **Mise**: For runtime version management
- **Nerd Fonts**: For beautiful terminal typography
- **Zinit**: For fast Zsh plugin management

---

Take the hassle out of dotfile management and development environment setup with DotMate! 🎉

**Get organized, stay consistent, and make development a breeze across all your machines.**
