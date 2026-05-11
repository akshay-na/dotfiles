#!/bin/bash

# Colors for output (defined before repo resolution so trust checks can use them)
GREEN="\033[1;32m"
RED="\033[1;31m"
YELLOW="\033[1;33m"
RESET="\033[0m"

echo_with_color() {
  echo -e "${1}${2}${RESET}"
}

# Absolute path to this script (symlink-safe, no readlink -f requirement)
_dotmate_self_path() {
  local s="${BASH_SOURCE[0]:-$0}"
  while [ -L "$s" ]; do
    local dir
    dir="$(cd -P "$(dirname "$s")" && pwd)"
    s="$(readlink "$s")"
    case "$s" in /*) ;; *) s="$dir/$s" ;; esac
  done
  echo "$(cd -P "$(dirname "$s")" && pwd)/$(basename "$s")"
}

# Repo root: directory containing scripts/DotMate.sh, else directory of script
_dotmate_repo_root_from_script() {
  local self="$1"
  local dir
  dir="$(cd -P "$(dirname "$self")" && pwd)"
  if [ "$(basename "$dir")" = "scripts" ]; then
    cd -P "$(dirname "$dir")" && pwd
  else
    echo "$dir"
  fi
}

# Resolve operational dotfiles tree (upstream clone or ~/dotfiles-local)
if [ -n "${DOTFILES_DIR:-}" ]; then
  if ! DOTFILES_DIR="$(cd -P "$DOTFILES_DIR" 2>/dev/null && pwd)"; then
    echo_with_color "$RED" "Invalid DOTFILES_DIR: ${DOTFILES_DIR:-}"
    exit 1
  fi
else
  _dotmate_sp="$(_dotmate_self_path)"
  DOTFILES_DIR="$(_dotmate_repo_root_from_script "$_dotmate_sp")"
fi

# Trust boundary: sourcing from DOTFILES_DIR is like trusting a git checkout
_dotmate_assert_dotfiles_dir_trusted() {
  local root="$1"
  if [ ! -d "$root" ]; then
    echo_with_color "$RED" "Dotfiles directory missing: $root"
    exit 1
  fi
  local cur_uid owner_uid
  cur_uid="$(id -u)"
  if stat -f '%u' "$root" >/dev/null 2>&1; then
    owner_uid="$(stat -f '%u' "$root")"
  elif stat -c '%u' "$root" >/dev/null 2>&1; then
    owner_uid="$(stat -c '%u' "$root")"
  else
    echo_with_color "$YELLOW" "DotMate: could not stat DOTFILES_DIR; skipping ownership check."
    return 0
  fi
  if [ "$owner_uid" != "$cur_uid" ]; then
    echo_with_color "$RED" "DotMate: refusing DOTFILES_DIR not owned by current user (euid $cur_uid): $root"
    exit 1
  fi
  if find "$root" -maxdepth 0 -perm -0002 2>/dev/null | grep -q .; then
    echo_with_color "$RED" "DotMate: refusing world-writable DOTFILES_DIR: $root"
    exit 1
  fi
}

_dotmate_assert_dotfiles_dir_trusted "$DOTFILES_DIR"

_DOTMATE_FUNCTIONS="$DOTFILES_DIR/shell/.functions"
if [ -f "$_DOTMATE_FUNCTIONS" ]; then
  # shellcheck source=/dev/null
  source "$_DOTMATE_FUNCTIONS"
else
  echo_with_color "$YELLOW" "DotMate: missing shell/.functions — continuing without shared functions."
fi

# Directories and timestamped backup
BACKUP_DIR=$HOME/dotfiles_backup/$(date +%Y%m%d_%H%M%S)

# Backup existing dotfiles to avoid data loss
backup_dotfiles() {
  echo_with_color "$GREEN" "Backing up existing dotfiles to $BACKUP_DIR"
  mkdir -p "$BACKUP_DIR"
  find "$DOTFILES_DIR" -type f | while read -r file; do
    dest="$HOME/${file#$DOTFILES_DIR/*/}"
    if [ -e "$dest" ]; then
      mkdir -p "$BACKUP_DIR/$(dirname "$dest")"
      mv "$dest" "$BACKUP_DIR/$dest"
      echo_with_color "$YELLOW" "Backed up $dest"
    fi
  done
}

# Install necessary tools and set up environment
install() {
  # Ask for the administrator password upfront
  sudo -v

  echo_with_color "$GREEN" "Installing tools and setting up environment..."

  chmod +x $DOTFILES_DIR/scripts/resources/*

  # Install tools and set up environment based on OS
  if [[ "$OSTYPE" == "darwin"* ]]; then
    source "$DOTFILES_DIR/scripts/resources/macos.sh"
    install_macos
  elif command -v apt >/dev/null 2>&1; then
    source "$DOTFILES_DIR/scripts/resources/debian.sh"
    install_debian
  else
    echo_with_color "$RED" "Unsupported OS or package manager."
    echo_with_color "$RED" "This script supports macOS (Homebrew) or Debian/Ubuntu (apt). Please install the required things manually"
    exit 1
  fi

  # Install common tools
  source "$DOTFILES_DIR/scripts/resources/common.sh"
  install_common

  stow_dotfiles

  git ignore $DOTFILES_DIR/mise/.config/mise/conf.d/global_tools.toml

  # Set permissions for gnupg and ssh folders
  if [ -d "$HOME/.gnupg" ]; then
    chmod 700 "$HOME/.gnupg"
    find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
    find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
  fi
  if [ -d "$HOME/.ssh" ]; then
    chmod 700 "$HOME/.ssh"
    find "$HOME/.ssh" -type f -exec chmod 600 {} \;
    find "$HOME/.ssh" -type d -exec chmod 700 {} \;
  fi

  fc-cache -f -v >/dev/null 2>&1

  sudo chsh -s "$(which zsh)" "$(whoami)"

  echo_with_color "$GREEN" "Setup complete! Restart your terminal to apply changes."
}

# Create symlinks for dotfiles using stow
stow_dotfiles() {
  echo_with_color "$GREEN" "Stowing dotfiles..."
  EXCLUDED_DIRS=("ai" "scripts")
  for dir in "$DOTFILES_DIR"/*/; do
    if [[ ! " ${EXCLUDED_DIRS[@]} " =~ " $(basename "$dir") " ]]; then
      stow --no-folding --override=$dir -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
    fi
  done
  chmod +x ~/.local/bin/*
}

# Remove symlinks created by stow, including ai directory
unstow_dotfiles() {
  echo_with_color "$RED" "Unstowing dotfiles..."
  for dir in "$DOTFILES_DIR"/*/; do
    stow -D -d "$DOTFILES_DIR" -t "$HOME" "$(basename "$dir")"
  done
}

# Clean up broken symlinks in the home directory
clean_symlinks() {
  echo_with_color "$YELLOW" "Cleaning up broken dotfile symlinks"
  {
    find "$HOME" -maxdepth 1 -type l ! -exec test -e {} \; -delete -print
    find "$HOME/.config" "$HOME/.local/bin" -type l ! -exec test -e {} \; -delete -print
  }
}

# Create symlinks for specific dotfiles (support multiple arguments)
stow_multiple_dotfiles() {
  if [ "$#" -eq 0 ]; then
    echo_with_color "$RED" "No repository or tool specified. Usage: $0 stow <tool1> <tool2> ..."
    exit 1
  fi

  for tool in "$@"; do
    if [ "$tool" = "ai-brain" ]; then
      echo_with_color "$RED" "ai-brain is not stowed via CONFIGS. Use: $0 stow_with_target ai/<cursor|gemini-pack> <target>"
      exit 1
    fi
    echo_with_color "$GREEN" "Stowing $tool..."
    stow --no-folding --override=$tool -d "$DOTFILES_DIR" -t "$HOME" "$tool"
  done
}

# Tool id for ~/.<tool> from ai package directory name (cursor-tech-team→cursor; .gemini→gemini).
ai_tool_from_package_name() {
  case "$1" in
  .gemini) printf '%s\n' gemini ;;
  ai-brain) printf '%s\n' ai-brain ;;
  *)
    if [[ "$1" == *-* ]]; then
      printf '%s\n' "${1%%-*}"
    else
      printf '%s\n' "$1"
    fi
    ;;
  esac
}

# Stow a specific folder path to a target folder name under $HOME
# Usage: stow_with_target <folder_path_from_dotfiles> [target_folder_name]
stow_with_target() {
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo_with_color "$RED" "Usage: $0 stow_with_target <folder_path> [target_folder_name]"
    exit 1
  fi

  local folder_path="$1"
  local target_folder_name="${2:-$(basename "$folder_path")}"
  local package_dir
  local package_name

  package_dir="$(dirname "$folder_path")"
  package_name="$(basename "$folder_path")"

  if [ ! -d "$DOTFILES_DIR/$folder_path" ]; then
    echo_with_color "$RED" "Folder not found: $DOTFILES_DIR/$folder_path"
    exit 1
  fi

  local stow_target="$HOME/$target_folder_name"

  # Switching ai team packs: remove every package that maps to the same ~/.<tool> target
  # first, or stow errors ("existing target is stowed to a different package").
  if [ "$package_dir" = "ai" ]; then
    unstow_same_tool_siblings() {
      local want_tool="$1"
      local target="$2"
      local sibling base pkg_tool
      echo_with_color "$YELLOW" "Unstowing previous ${want_tool} team packages from $target..."
      rm -rf "${target}/agents" 2>/dev/null || true
      while IFS= read -r -d '' sibling; do
        base="$(basename "$sibling")"
        [ "$base" = "ai-brain" ] && continue
        pkg_tool="$(ai_tool_from_package_name "$base")"
        [ "$pkg_tool" = "$want_tool" ] || continue
        stow -D -d "$DOTFILES_DIR/ai" -t "$target" "$base" 2>/dev/null || true
      done < <(find "$DOTFILES_DIR/ai" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null)
    }
    unstow_same_tool_siblings "$(ai_tool_from_package_name "$package_name")" "$stow_target"
  fi

  echo_with_color "$GREEN" "Stowing $folder_path -> $stow_target"
  stow --no-folding --override="$package_name" -R -d "$DOTFILES_DIR/$package_dir" -t "$stow_target" "$package_name"

  # AI agents: copy (not symlink). ai-brain skeleton is stowed only here — not via make stow CONFIGS (ai/ excluded).
  copy_agents_for_app() {
    local app_name="$1"
    local target_dir="$HOME/.$app_name"
    mkdir -p "$HOME/ai-brain"
    stow --no-folding --override="ai-brain" -d "$DOTFILES_DIR/ai" -t "$HOME/ai-brain" "ai-brain"
    rm -rf "$target_dir/agents"
    cp -rf "$DOTFILES_DIR/$folder_path/agents" "$target_dir" 2>/dev/null || true
  }

  if [ "$package_dir" = "ai" ]; then
    app_tool="$(ai_tool_from_package_name "$package_name")"
    if [ "$app_tool" != "ai-brain" ]; then
      copy_agents_for_app "$app_tool"
    fi
  fi
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

# Second repo for per-host overrides. Sources of truth for copies: DOTMATE_CANONICAL_ROOT only.
bootstrap_local_main() {
  if [ -z "${DOTMATE_CANONICAL_ROOT:-}" ]; then
    echo_with_color "$RED" "Run via \`make bootstrap-local\` from upstream clone or set \`DOTMATE_CANONICAL_ROOT\`."
    exit 1
  fi
  if ! CANON="$(cd -P "$DOTMATE_CANONICAL_ROOT" 2>/dev/null && pwd)"; then
    echo_with_color "$RED" "Invalid DOTMATE_CANONICAL_ROOT: $DOTMATE_CANONICAL_ROOT"
    exit 1
  fi
  local raw="${LOCAL_DIR:-${1:-}}"
  raw="${raw:-$HOME/dotfiles-local}"
  case "$raw" in
  ~/*) raw="$HOME/${raw#~/}" ;;
  ~) raw="$HOME" ;;
  esac
  mkdir -p "$raw" || {
    echo_with_color "$RED" "Could not create LOCAL_DIR: $raw"
    exit 1
  }
  local_dir="$(cd -P "$raw" && pwd)" || {
    echo_with_color "$RED" "Could not resolve LOCAL_DIR: $raw"
    exit 1
  }

  echo_with_color "$GREEN" "Bootstrapping local dotfiles tree: $local_dir"
  mkdir -p "$local_dir/shell" "$local_dir/git" "$local_dir/ssh/.ssh" "$local_dir/utilities" "$local_dir/scripts"

  cp -n "$CANON/scripts/DotMate.sh" "$local_dir/scripts/DotMate.sh"
  cp -n "$CANON/Makefile" "$local_dir/Makefile"
  if [ -f "$CANON/.stowrc" ]; then
    cp -n "$CANON/.stowrc" "$local_dir/.stowrc"
  else
    echo_with_color "$YELLOW" "Warning: $CANON/.stowrc missing; skipping copy."
  fi

  _bootstrap_scaffold_if_missing() {
    local f="$1"
    if [ ! -e "$f" ]; then
      : >"$f"
    fi
  }
  _bootstrap_scaffold_if_missing "$local_dir/shell/.commonrc_local"
  _bootstrap_scaffold_if_missing "$local_dir/shell/.functions_local"
  _bootstrap_scaffold_if_missing "$local_dir/shell/.aliases_local"
  _bootstrap_scaffold_if_missing "$local_dir/shell/.zshrc_local"
  _bootstrap_scaffold_if_missing "$local_dir/shell/.bashrc_local"
  _bootstrap_scaffold_if_missing "$local_dir/shell/.tmux_local.conf"
  _bootstrap_scaffold_if_missing "$local_dir/git/.gitconfig_local"
  _bootstrap_scaffold_if_missing "$local_dir/ssh/.ssh/config_local"
  _bootstrap_scaffold_if_missing "$local_dir/utilities/.taskrc_local"

  if [ ! -f "$local_dir/.gitignore" ]; then
    cat >"$local_dir/.gitignore" <<'EOF'
.DS_Store
EOF
  fi
  if [ ! -f "$local_dir/README.md" ]; then
    cat >"$local_dir/README.md" <<'EOF'
# Local dotfiles overrides

Machine-specific stow tree. Refresh `DotMate.sh`, `Makefile`, and `.stowrc` from upstream by running `make bootstrap-local` from your canonical clone (or set `DOTMATE_CANONICAL_ROOT` explicitly).

See upstream README: two-root contract and trust boundaries for `DOTFILES_DIR`.
EOF
  fi

  if command -v git >/dev/null 2>&1 && [ "${SKIP_GIT_INIT:-0}" != "1" ]; then
    if [ ! -d "$local_dir/.git" ]; then
      (cd "$local_dir" && git init -b main)
    fi
    if [ ! -f "$local_dir/.git/HEAD" ]; then
      echo_with_color "$RED" "Expected $local_dir/.git/HEAD after git init."
      exit 1
    fi
  fi

  echo_with_color "$GREEN" "bootstrap-local finished: $local_dir"
}

# Main logic to handle arguments
case "$1" in
backup)
  backup_dotfiles
  ;;
update)
  backup_dotfiles
  if declare -F check_dotfiles_update >/dev/null 2>&1; then
    check_dotfiles_update
  else
    echo_with_color "$YELLOW" "check_dotfiles_update not defined; skipping update check."
  fi
  stow_dotfiles
  ;;
install)
  backup_dotfiles
  install
  ;;
stow)
  shift
  if [ "$#" -gt 0 ]; then
    stow_multiple_dotfiles "$@"
  else
    stow_dotfiles
  fi
  ;;
stow_with_target | stow-with-target)
  shift
  stow_with_target "$@"
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
bootstrap_local | bootstrap-local)
  shift
  bootstrap_local_main "$@"
  ;;
*)
  echo_with_color "$YELLOW" "Usage: $0 {backup|update|install|stow|stow_with_target|unstow|clean|bootstrap_local}"
  exit 1
  ;;
esac

exit 0
