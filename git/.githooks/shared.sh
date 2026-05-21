#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
DEBUG_HOOKS=${DEBUG_HOOKS:-0}

hooks_debug_enabled() {
  local v
  v=$(printf '%s' "$DEBUG_HOOKS" | tr '[:upper:]' '[:lower:]')
  case "$v" in
    1 | true | yes | on) return 0 ;;
    *) return 1 ;;
  esac
}

info() {
  echo -e "${BLUE}$1${NC}"
}

warn() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

success() {
  echo -e "${GREEN}✔ $1${NC}"
}

error() {
  echo -e "${RED}✖ $1${NC}"
  exit 1
}

debug() {
  if hooks_debug_enabled; then
    echo "DEBUG: $1" >&2
  fi
}

repo_root() {
  git rev-parse --show-toplevel 2>/dev/null
}

current_branch() {
  git branch --show-current 2>/dev/null
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

# Strip AI/IDE/bot attribution trailers and common injected body credit lines.
strip_ai_attribution() {
  local msg_file="$1"
  local tmp
  tmp=$(mktemp) || error "Failed to create temp file for commit-msg sanitization"

  local ai_identity ai_trailers ai_attribution_trailers ai_email
  ai_identity='cursor|cursor[[:space:]]*agent|cursoragent|anysphere|copilot|github[[:space:]]*copilot|microsoft[[:space:]]*copilot|open[[:space:]]*ai|chatgpt|gpt[-[:space:]]*[0-9.]+|codex|o[0-9]+-mini|claude|anthropic|gemini|bard|google[[:space:]]*ai|deepmind|cody|sourcegraph|codeium|tabnine|windsurf|cascade|supermaven|aider|aider-chat|devin|cognition|amazon[[:space:]]*q|codewhisperer|code[[:space:]]*whisperer|jetbrains[[:space:]]*ai|junie|replit|phind|bolt\.new|lovable|v0[[:space:]]*by|vercel[[:space:]]*v0|openhands|moatless|sweep|continue\.dev|continue[[:space:]]*ai|mistral|le[[:space:]]*chat|perplexity|blackbox|augment[[:space:]]*code|kilocode|cline|roo[[:space:]]*code|fabric[[:space:]]*ai|ghostwriter|artificial[[:space:]]*intelligence|language[[:space:]]*model|[[:<:]]llm[[:>:]]|dependabot|renovate(\[bot\])?|github-actions|\[bot\]'
  ai_trailers='ai-authored|ai-assisted-by|ai-assisted|ai-generated-by|generated-by|generated-with|llm-authored|tool-assisted-by|commit-generated-by|created-with-ai|written-with-ai|pair-programmed-with|prompted-by|assisted-by-ai'
  ai_attribution_trailers='co-authored-by|assisted-by|reviewed-by|suggested-by|authored-by|created-by|written-by'
  ai_email='@(cursor\.(sh|com)|openai\.com|anthropic\.com|copilot\.githubusercontent\.com|ai@local\.invalid|users\.noreply\.github\.com)'

  grep -viE \
    -e "^(${ai_attribution_trailers}):[[:space:]]*.*(${ai_identity})" \
    -e "^(${ai_attribution_trailers}):[[:space:]]*.*<[^>]*${ai_email}[^>]*>" \
    -e "^(${ai_trailers})[[:space:]]*:" \
    -e "^[[:space:]]*(this (commit )?was )?(written|generated|authored|created|assisted|produced)( with| by| using)? .*(artificial intelligence|language model|[[:<:]]llm[[:>:]]|${ai_identity})" \
    -e "^[[:space:]]*(generated|written|authored|created|assisted)( with| by| using)? (ai|an? ai( assistant| tool| agent)?|chatgpt|copilot|claude|gemini|cursor)[[:space:][:punct:]]" \
    "$msg_file" >"$tmp" || true

  mv "$tmp" "$msg_file"
}

run_if_exists() {
  local file="$1"

  if [ -f "$file" ]; then
    debug "Running: $file"
    bash "$file"
  fi
}

run_if_executable() {
  local file="$1"

  if [ -x "$file" ]; then
    debug "Running: $file"
    "$file"
  fi
}

run_husky_hook() {
  local hook="$1"
  local root="$2"

  if [ -f "$root/.husky/$hook" ]; then
    debug "🐶 Husky: $hook"
    cd "$root"
    bash ".husky/$hook"
  fi
}

run_precommit_hook() {
  local hook="$1"
  local root="$2"

  if [ -f "$root/.pre-commit-config.yaml" ] && has_command pre-commit; then
    debug "🐍 pre-commit: $hook"
    cd "$root"
    pre-commit run --hook-stage "$hook"
  fi
}

run_lefthook_hook() {
  local hook="$1"
  local root="$2"

  if [ -f "$root/lefthook.yml" ] && has_command lefthook; then
    debug "🪝 Lefthook: $hook"
    cd "$root"
    lefthook run "$hook"
  fi
}

run_repo_local_hook() {
  local hook="$1"
  local root="$2"

  run_if_executable "$root/.githooks/$hook"

  #detect worktree
  if [ -f "$root/.git" ]; then
    cd "$root"
    is_worktree_config_enabled=$(git config --bool extensions.worktreeconfig 2>/dev/null || echo false)
    if [ "$is_worktree_config_enabled" = "true" ]; then
      root=$(git rev-parse --git-dir)
    else
      root=$(git rev-parse --git-common-dir)
    fi
  fi

  run_if_executable "$root/hooks/$hook"
}

dispatch_hook() {
  local hook="$1"

  local root
  root=$(repo_root)

  [ -z "$root" ] && return 0

  run_husky_hook "$hook" "$root"
  if [[ $hook = 'pre-commit' ]]; then
    run_precommit_hook "$hook" "$root"
  fi
  run_lefthook_hook "$hook" "$root"
  run_repo_local_hook "$hook" "$root"
}
