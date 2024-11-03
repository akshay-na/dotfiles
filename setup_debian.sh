#!/bin/bash

# Update and install prerequisites
sudo apt update
sudo apt install -y curl git zsh fzf tmux neovim zoxide unzip stow

# Install nvm and the latest node version
if ! command -v nvm &>/dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

  # Installs the latest node version
  nvm install node
fi

# Install pyenv and the latest Python version
if ! command -v pyenv &>/dev/null; then
  curl https://pyenv.run | bash
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"

  latest_python=$(pyenv install --list | grep -E '^\s*[0-9]+.[0-9]+.[0-9]+$' | tail -1 | tr -d ' ')
  pyenv install "$latest_python"
  pyenv global "$latest_python"
fi

# Check if the repository already exists
if [ -d "$HOME/dotfiles" ]; then
  # If it exists, navigate to the directory and pull the latest changes
  cd "$HOME/dotfiles" && git pull
  popd
else
  # If it doesn't exist, clone the repository
  git clone https://github.com/akshay-na/dotfiles "$HOME/dotfiles"
fi

rsync -av \
  --exclude='.git' \
  --exclude='.gitconfig' \
  --exclude='.ssh' \
  --exclude='.gitignore' \
  --exclude='README.md' \
  --exclude='LICENSE' ~/dotfiles/ ~/

# Install TPM Tmux plugin manager
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Try installing Starship using the provided curl command
if ! command -v starship >/dev/null 2>&1; then
  if yes | sh -c "$(curl -sSL https://starship.rs/install.sh)"; then
    echo "Starship installed successfully using the curl command."
  else
    # Download the latest Starship release
    download_url=$(curl -s "https://api.github.com/repos/starship/starship/releases/latest" | grep "browser_download_url.*starship-x86_64-unknown-linux-gnu.tar.gz" | cut -d '"' -f 4)
    curl -L -o "$HOME/starship.tar.gz" $download_url

    # Unzip Starship and move to the User directory
    tar -xzf "$HOME/starship.tar.gz" -C $HOME
    rm "$HOME/starship.tar.gz"
  fi
fi

# Check if Cascadia Code Nerd Font is already installed
if ! fc-list | grep -qi "CaskaydiaCove Nerd Font Mono"; then
  # Download and install the Cascadia Code Nerd Font
  curl -L -o "$HOME/CascadiaCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/CascadiaCode.zip"
  unzip "$HOME/CascadiaCode.zip" -d "$HOME/CascadiaCode" >/dev/null 2>&1

  # Assuming the font is named "CascadiaMono*" in the zip; adjust if different
  mkdir -p ~/.local/share/fonts
  cp $HOME/CascadiaCode/CaskaydiaCoveNerdFontMono* ~/.local/share/fonts/
  fc-cache -f -v >/dev/null 2>&1

  # Clean up the downloaded files
  rm -rf "$HOME/CascadiaCode.zip" "$HOME/CascadiaCode"
fi

# Set zsh as the default shell
chsh -s $(which zsh)

echo "Setup complete! Please restart your terminal for all changes to take effect."
