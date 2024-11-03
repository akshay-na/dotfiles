# Untitled

# Dotfiles Setup - DotMate.sh 🛠️

Welcome to **DotMate.sh**, a versatile dotfile management tool that helps you back up, update, install, and manage your configuration files. With DotMate, setting up a new system or maintaining dotfile consistency across multiple systems becomes effortless.

## Features 🌟

- **Automated Backups**: Easily back up existing dotfiles to prevent accidental data loss.
- **Repository Updates**: Keep your dotfiles repository up-to-date with a simple command.
- **Environment Setup**: Install essential tools and set up your environment for optimal productivity.
- **Dotfile Management**: Use `stow` for seamless symlink management, making it easy to apply or remove configurations.
- **Clean-Up**: Identify and clean up broken symlinks, keeping your environment tidy.

---

## Installation 🚀

1. **Clone the Repository**

    ```
    git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

2. **Run DotMate.sh**

    ```
./DotMate.sh install

    ```

    This command will install essential tools, set up your environment, back up existing configurations, and create symlinks for the dotfiles.


---

## Usage 📋

Run DotMate with the following commands to perform various tasks:

- **Backup existing dotfiles**

    ```
./DotMate.sh backup

    ```

    Backs up current dotfiles to a timestamped directory in `~/dotfiles_backup`.

- **Update repository**

    ```
./DotMate.sh update

    ```

    Checks for updates in your dotfiles repository and prompts you to pull the latest changes if available.

- **Install tools and set up environment**

    ```
./DotMate.sh install

    ```

    Installs essential tools and sets up your environment, also handling backup and symlinking of dotfiles.

- **Stow dotfiles**

    ```
./DotMate.sh stow

    ```

    Creates symlinks for all dotfiles in your repository, applying your configurations.

- **Unstow dotfiles**

    ```
./DotMate.sh unstow

    ```

    Removes symlinks created by `stow`, reverting to default configurations.

- **Clean broken symlinks**

    ```
./DotMate.sh clean

    ```

    Deletes broken symlinks in your home directory.


### Example Workflow 🌈

1. **Backup** current dotfiles before making changes:

    ```
./DotMate.sh backup

    ```

2. **Install** essential tools and apply configurations:

    ```
./DotMate.sh install

    ```

3. **Stow** or **unstow** configurations as needed to customize your setup.

---

## Customization 🧩

You can modify DotMate.sh to include additional tools or customize paths. The default configuration includes:

- **Utilities**: `curl`, `git`, `zsh`, `fzf`, `tmux`, `neovim`, `zoxide`, `unzip`, `stow`
- **Shell**: Automatically sets Zsh as the default shell

---

## Troubleshooting & Tips 💡

- **Permissions**: DotMate sets strict permissions on sensitive files (`.gnupg` and `.ssh/config`). Ensure you have the necessary privileges to modify these.
- **Restore Backups**: Use your backup directory (`~/dotfiles_backup`) to revert changes if needed.

---

## Contributing 🤝

Feel free to contribute! Submit issues or pull requests to enhance DotMate's functionality.

---

## License 📜

This project is licensed under the MIT License. See the LICENSE file for details.

---

Happy dotfiling with DotMate! 🎉