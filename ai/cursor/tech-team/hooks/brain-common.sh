#!/usr/bin/env bash
# brain-common.sh — shared library for ai-brain session bootstrap hooks.
#
# Sourced by brain-session-start.sh (and future brain-* hooks). Provides:
#   - BRAIN_ROOT resolution
#   - contract_version load from memory-demotion.yml
#   - kb-identity slug resolver (worktree-safe)
#   - fail-open trap helpers
#
# DESIGN: fail-open — bootstrap must NEVER break the agent flow.
#
# shellcheck shell=bash disable=SC2034,SC2155

if [ -n "${__BRAIN_COMMON_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
__BRAIN_COMMON_LOADED=1

# --- resolve paths -----------------------------------------------------------
__brain_self="${BASH_SOURCE[0]}"
__brain_real="$(realpath -q "$__brain_self" 2>/dev/null || printf '%s' "$__brain_self")"
BRAIN_HOOKS_DIR="$(dirname "$__brain_real")"
BRAIN_PACK_DIR="$(dirname "$BRAIN_HOOKS_DIR")"
BRAIN_DOTFILES_ROOT="$(cd "$BRAIN_PACK_DIR/../../.." && pwd)"

if [ -x "$BRAIN_DOTFILES_ROOT/ai/ai-brain/scripts/brain-rebuild-session-index.sh" ]; then
  BRAIN_SCRIPTS_DIR="${BRAIN_DOTFILES_ROOT}/ai/ai-brain/scripts"
elif [ -x "$HOME/ai-brain/scripts/brain-rebuild-session-index.sh" ]; then
  BRAIN_SCRIPTS_DIR="$HOME/ai-brain/scripts"
else
  BRAIN_SCRIPTS_DIR="${BRAIN_DOTFILES_ROOT}/ai/ai-brain/scripts"
fi

# Runtime vault root — override for tests via CURSOR_BRAIN_ROOT.
__brain_root_raw="${CURSOR_BRAIN_ROOT:-$HOME/ai-brain}"
case "$__brain_root_raw" in
  "~/"*) BRAIN_ROOT="$HOME/${__brain_root_raw#\~/}" ;;
  "~") BRAIN_ROOT="$HOME" ;;
  *) BRAIN_ROOT="$__brain_root_raw" ;;
esac

BRAIN_CONTRACT_VERSION=""
BRAIN_CONTRACT_POLICY=""

# --- contract_version --------------------------------------------------------
brain_load_contract_version() {
  BRAIN_CONTRACT_VERSION=""
  BRAIN_CONTRACT_POLICY=""

  local candidates=()
  if [ -f "$BRAIN_ROOT/org/global/config/memory-demotion.yml" ]; then
    candidates+=("$BRAIN_ROOT/org/global/config/memory-demotion.yml")
  fi
  local dotfiles_policy="$BRAIN_DOTFILES_ROOT/ai/ai-brain/org/global/config/memory-demotion.yml"
  if [ -f "$dotfiles_policy" ]; then
    candidates+=("$dotfiles_policy")
  fi

  local f cv
  for f in "${candidates[@]}"; do
    cv="$(grep -E '^contract_version:' "$f" 2>/dev/null | head -1 | awk '{print $2}')"
    if [ -n "$cv" ]; then
      BRAIN_CONTRACT_POLICY="$f"
      BRAIN_CONTRACT_VERSION="$cv"
      return 0
    fi
  done
  return 0
}

brain_load_contract_version

# --- fail-open ---------------------------------------------------------------
brain_fail_open() {
  exit 0
}

brain_install_fail_open_trap() {
  trap 'brain_fail_open' ERR
}

# --- slug resolver (kb-identity parity) --------------------------------------
# Prints slug on stdout; returns 0 on success, 1 when unresolved.
brain_resolve_slug() {
  local project_root="$1"
  [ -n "$project_root" ] || return 1

  if ! command -v python3 >/dev/null 2>&1; then
    local fallback
    fallback="$(basename "$project_root" 2>/dev/null | tr '[:upper:]' '[:lower:]')"
    [ -n "$fallback" ] || return 1
    printf '%s' "$fallback"
    return 0
  fi

  python3 - "$project_root" <<'PY'
import re
import sys
from pathlib import Path
from urllib.parse import urlparse

def repo_name_from_remote(url: str) -> str:
    url = url.strip()
    if url.startswith(("https://", "http://")):
        path = urlparse(url).path.strip("/")
        name = path.split("/")[-1] if path else ""
    elif url.startswith("git@"):
        name = url.split(":", 1)[-1]
    elif url.startswith("ssh://"):
        path = urlparse(url).path.strip("/")
        name = path.split("/")[-1] if path else ""
    else:
        name = url.rstrip("/").split("/")[-1]
    if name.endswith(".git"):
        name = name[:-4]
    return name.lower()

def git_config_path(project_root: Path) -> Path | None:
    git_entry = project_root / ".git"
    if not git_entry.exists():
        return None
    if git_entry.is_file():
        text = git_entry.read_text()
        m = re.search(r"^gitdir:\s*(.+)$", text, re.M)
        if not m:
            return None
        worktree_git = Path(m.group(1).strip())
        parts = worktree_git.parts
        if "worktrees" in parts:
            idx = parts.index("worktrees")
            main_git = Path(*parts[:idx])
        else:
            main_git = worktree_git.parent
        return main_git / "config"
    return git_entry / "config"

def origin_url(config_path: Path) -> str | None:
    if not config_path.is_file():
        return None
    in_origin = False
    for line in config_path.read_text().splitlines():
        stripped = line.strip()
        if stripped.startswith("["):
            in_origin = stripped == '[remote "origin"]'
            continue
        if in_origin and stripped.startswith("url"):
            _, _, value = stripped.partition("=")
            if value:
                return value.strip()
    return None

def resolve(project_root: str) -> str | None:
    root = Path(project_root).expanduser().resolve()
    cfg = git_config_path(root)
    if cfg is None:
        return root.name.lower()
    remote = origin_url(cfg)
    if remote:
        return repo_name_from_remote(remote)
    return root.name.lower()

slug = resolve(sys.argv[1])
if slug:
    print(slug)
    sys.exit(0)
sys.exit(1)
PY
}

# --- L0 / migration probes ---------------------------------------------------
brain_l0_index_exists() {
  [ -f "$BRAIN_ROOT/org/global/_index.md" ]
}

brain_migration_check_slug() {
  local slug="$1"
  local script="$BRAIN_SCRIPTS_DIR/migrate-brain-frontmatter.sh"
  [ -n "$slug" ] || return 1
  [ -x "$script" ] || return 1
  "$script" --check-slug "$slug" >/dev/null 2>&1
}
