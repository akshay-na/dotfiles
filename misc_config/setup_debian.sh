#!/bin/bash

# Update and install prerequisites
sudo apt update
sudo apt install -y curl git zsh fzf tmux neovim zoxide

# Install nvm and the latest node version
if ! command -v nvm &>/dev/null; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # Load nvm
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
fi
nvm install node # Installs the latest node version

# Install pyenv and the latest Python version
if ! command -v pyenv &>/dev/null; then
  curl https://pyenv.run | bash
  export PATH="$HOME/.pyenv/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi
latest_python=$(pyenv install --list | grep -E '^\s*[0-9]+.[0-9]+.[0-9]+$' | tail -1 | tr -d ' ')
pyenv install "$latest_python"
pyenv global "$latest_python"

# # Install oh-my-zsh
# if [ ! -d "$HOME/.oh-my-zsh" ]; then
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
# fi

# # Install additional zsh plugins
# ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
# [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ] && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
# [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ] && git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
# [ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ] && git clone https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"

# # Configure zsh plugins if .zshrc exists
# if [ -f "$HOME/.zshrc" ]; then
#   # Overwrite the plugins line if it exists, or append it if it doesn't
#   if grep -q '^plugins=' "$HOME/.zshrc"; then
#     # Use sed to replace the existing plugins line
#     sed -i '/^plugins=/c\plugins=(docker git kubectl npm vscode you-should-use zsh-syntax-highlighting zsh-autosuggestions)' "$HOME/.zshrc"
#   else
#     # If plugins line doesn't exist, append it
#     echo 'plugins=(docker git kubectl npm vscode you-should-use zsh-syntax-highlighting zsh-autosuggestions)' >>"$HOME/.zshrc"
#   fi

#   # Insert source commands directly below the plugins line
#   sed -i '/^plugins=.*/a\
# source $ZSH/oh-my-zsh.sh\n\
# source $ZSH/plugins/git/git.plugin.zsh\n\
# source $ZSH_CUSTOM/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh\n\
# source $ZSH_CUSTOM/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh\n\
# source $ZSH_CUSTOM/plugins/you-should-use/you-should-use.plugin.zsh\n\

# # Custom plugin settings\n\
# zstyle ':vcs_info:git:*:-all-' get-revision true\n\
# zstyle ':completion:*:*:docker:*' option-stacking yes\n\
# zstyle ':completion:*:*:docker-*:*' option-stacking yes\n\
# export YSU_MESSAGE_POSITION="after"\n\' "$HOME/.zshrc"

# fi

# Clone nvim configuration
git clone https://github.com/akshay-na/nvim-config ~/.config/nvim

# Copy miscellaneous config files
cp -rf ~/.config/nvim/misc_config/ $HOME

# Install Starship prompt
curl -sSL https://gist.githubusercontent.com/akshay-na/dc29ce1b6e980f94ff72e595f05e29b7/raw | sh

# Add necessary config for nvm, pyenv, fzf, and zoxide to bashrc and zshrc without overwriting
append_if_not_exists() {
  local line="$1"
  local file="$2"
  grep -qxF "$line" "$file" || echo "$line" >>"$file"
}

# Configuration for both .bashrc and .zshrc
for file in ~/.bashrc ~/.zshrc; do
  append_if_not_exists 'export NVM_DIR="$HOME/.nvm"' "$file"
  append_if_not_exists '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' "$file"
  append_if_not_exists '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' "$file"
  append_if_not_exists 'export PATH="$HOME/.pyenv/bin:$PATH"' "$file"
  append_if_not_exists 'eval "$(pyenv init --path)"' "$file"
  append_if_not_exists 'eval "$(pyenv init -)"' "$file"
  append_if_not_exists 'eval "$(zoxide init zsh)"' "$file"
done

# Add function to load all git directories and worktrees for fzf and zoxide
cat <<'EOF' >>~/.zshrc
# Function to add all git directories and worktrees to fzf and zoxide
fcd_git() {
  find "$HOME" -type d -name .git -prune -exec dirname {} \; | fzf | while read -r dir; do
    zoxide add "$dir"
    cd "$dir" || return
  done
}
EOF

# Set zsh as the default shell
chsh -s $(which zsh)

# Configure tmux to start automatically on terminal startup
cat <<'EOF' >>~/.zshrc
# Automatically start tmux if not already inside a tmux session
if command -v tmux &>/dev/null; then
  [ -z "$TMUX" ] && exec tmux
fi
EOF

# Reload shell configurations
source ~/.bashrc
source ~/.zshrc

echo "Setup complete! Please restart your terminal for all changes to take effect."
