#!/usr/bin/env bash
# kb-bootstrap.sh — after `stow gemini`: clone/init content repo, hooks, symlinks.
# Vault + memory + docs live only in ~/content-knowledge-base (no template copy from dotfiles).
set -euo pipefail
REPO="${CONTENT_KB_REPO:-$HOME/content-knowledge-base}"
REMOTE="${CONTENT_KB_REMOTE:-git@github.com:akshay-na/content-knowledge-base.git}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_into_home() {
  local name="$1"
  local target="$REPO/$name"
  local link="$HOME/.gemini/$name"
  mkdir -p "$HOME/.gemini"
  if [[ -e "$link" && ! -L "$link" ]]; then
    echo "kb-bootstrap: WARN $link exists and is not a symlink — leave untouched" >&2
    return 0
  fi
  ln -sfn "$target" "$link"
  echo "kb-bootstrap: $link -> $target"
}

if [[ ! -d "$HOME/.gemini/scripts" ]]; then
  echo "kb-bootstrap: ~/.gemini/scripts missing — run: make stow CONFIGS=gemini (from dotfiles)" >&2
  exit 1
fi

if [[ "${KB_BOOTSTRAP_DEPLOY_KEY:-}" == "1" ]]; then
  bash "$SCRIPT_DIR/auth/deploy-key-bootstrap.sh" || true
fi

if [[ ! -d "$REPO/.git" ]]; then
  mkdir -p "$(dirname "$REPO")"
  echo "kb-bootstrap: cloning $REMOTE -> $REPO"
  if ! git clone "$REMOTE" "$REPO" 2>/dev/null; then
    echo "kb-bootstrap: clone failed — git init empty repo (add remote later if needed)" >&2
    mkdir -p "$REPO"
    git -C "$REPO" init -b main
    git -C "$REPO" remote add origin "$REMOTE" 2>/dev/null || true
  fi
fi

cd "$REPO"
if [[ ! -f README.md ]]; then
  echo "kb-bootstrap: WARN repo has no README.md — populate from your content-knowledge-base template (tracked in that repo only)." >&2
fi

chmod +x "$REPO/pre-commit-hooks/"*.sh 2>/dev/null || true
chmod +x "$REPO/scripts/"*.sh 2>/dev/null || true
if [[ -x "$REPO/scripts/install-hooks.sh" ]]; then
  (cd "$REPO" && ./scripts/install-hooks.sh)
elif [[ -f "$REPO/scripts/install-hooks.sh" ]]; then
  chmod +x "$REPO/scripts/install-hooks.sh"
  (cd "$REPO" && ./scripts/install-hooks.sh)
fi

mkdir -p "$REPO/docs/skills/pipeline-state"
link_into_home memory
link_into_home kb
link_into_home docs
link_into_home runbooks
mkdir -p "$HOME/.gemini/skills"
ln -sfn "$REPO/docs/skills/pipeline-state" "$HOME/.gemini/skills/pipeline-state"
echo "kb-bootstrap: ~/.gemini/skills/pipeline-state -> $REPO/docs/skills/pipeline-state"

echo ""
echo "Next:  bash ~/.gemini/scripts/kb-status.sh"
echo "        (each cco / metrics-steward run: git pull + kb-sync.sh sync — see ~/.gemini/rules/repo-hygiene.md)"
