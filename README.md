# DotMate 🛠️ — Your Companion for Effortless Dotfile Management

Welcome to **DotMate**, the streamlined solution for managing and syncing dotfiles across multiple systems. Whether you're setting up a new machine, organizing configurations, or maintaining consistency across environments, DotMate simplifies the entire process, saving you time, hassle, and manual work.

---

## 🌟 Why DotMate?

DotMate goes beyond basic dotfile management. Here’s what makes it stand out:

- **Automatic Backups**: DotMate backs up your current configurations automatically, so you’ll never lose a setup.
- **Seamless Syncing**: Keep your dotfiles synchronized across devices with a single update command.
- **Fast Environment Setup**: Install essential tools automatically, making new machine setups faster than ever.
- **Clean Symlink Management with Stow**: Use `stow` to create organized symlinks for all configurations, ensuring a tidy setup.
- **Simple Clean-Up Tools**: Quickly detect and remove broken symlinks, keeping your environment neat.

---

## 🚀 Getting Started

### Step 1: Clone the DotMate Repository

Start by cloning the DotMate repository to your home directory (or a preferred location):

```bash
git clone https://github.com/akshay-na/DotMate.git ~/dotfiles
cd ~/dotfiles
```

### Step 2: Install DotMate

Run the setup with:

```bash
sudo apt install make
make install
```

This command:

- **Installs essential tools** for your environment.
- **Backs up any existing configurations** to prevent accidental overwrites.
- **Creates symlinks** for dotfiles in the repository for easy configuration management.

**Need only the symlinks?** Use:

```bash
make stow
```

This command skips tool installation and only creates symlinks for your dotfiles.

---

## 📋 Using DotMate

### Update Your Dotfiles

Keeping your dotfiles up-to-date is as simple as running:

```bash
make update
```

If you’re using `.bashrc` or `.zshrc` from this repository, DotMate has an **auto-update feature** that notifies you of available updates, so you always stay current.

### Avoid Accidental Overwrites

DotMate automatically backs up any existing configurations in `~/dotfiles_backup/<timestamp>`. So if you run `make install` or `make stow` by mistake, your previous settings are saved, making it easy to revert if needed.

### Selective Configuration with Stow

Apply only the configurations you need with Stow. For example, to set up just the `shell` and `nvim` configurations:

```bash
make stow CONFIGS="shell nvim"
```

This flexibility lets you sync only the configurations you want, giving you control over what gets applied to each machine.

---

## 🧩 Customizing Your Dotfiles

DotMate comes with a set of essential configurations, but customization is easy! For personal tweaks without overwriting shared configurations, create a `.<config_name>_local` file. This way, you can keep global settings while adding machine-specific customizations.

### Supported Customizations:

| Configuration File | Local Customization File |
| --- | --- |
| `.gitconfig` | `~/.gitconfig_local` |
| `starship.toml` | `~/.config/starship_local.toml` |
| `.taskrc` | `~/.taskrc_local` |
| `.npmrc` | `~/.npmrc_local` |
| `.bashrc` | `~/.bashrc_local` |
| `.commonrc` | `~/.commonrc_local` |
| `.tmux.conf` | `~/.tmux_local.conf` |
| `.zshrc` | `~/.zshrc_local` |

For example, to add your own Starship prompt configuration, create a `~/.config/starship_local.toml` file and add your customizations there. DotMate will load these local files if they exist, giving you full control.

**Note**: Local files override initial configurations, so double-check before saving to ensure it’s set up the way you want.

---

## 💡 Tips & Troubleshooting

- **Permissions**: DotMate applies strict permissions on sensitive files, like `.gnupg` and `.ssh/config`, to protect your data. Ensure you have permission to edit these files if needed.
- **Restoring Backups**: Backups are saved in `~/dotfiles_backup/<timestamp>`. To restore a previous configuration, simply copy files from this directory back to your home folder.
- **Need Help?** Run `make help` to view available DotMate commands and their descriptions.

---

## 🤝 Contributing to DotMate

DotMate is open-source and always welcomes contributions! If you find issues, have feature requests, or want to contribute, please submit an issue or a pull request. Your feedback and contributions help improve DotMate for the community.

---

## 📜 License

DotMate is licensed under the MIT License. See the `LICENSE` file for more details.

---

Take the hassle out of dotfile management and setup with DotMate. 🎉 Get organized, stay consistent, and make dotfiling a breeze!