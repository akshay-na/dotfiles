#!/usr/bin/env bash
# Generate Ed25519 deploy key + Host github-content-kb (idempotent).
set -euo pipefail
KEY="$HOME/.ssh/content-knowledge-base"
CFG="$HOME/.ssh/config"
HOST_ALIAS="github-content-kb"
MARKER="# content-kb deploy key (gemini kb-bootstrap)"

if [[ -f "$KEY" ]]; then
  echo "deploy-key-bootstrap: key exists $KEY — skipping keygen"
else
  ssh-keygen -t ed25519 -f "$KEY" -N "" -C "content-kb deploy key $(hostname -s 2>/dev/null || echo host)"
  chmod 600 "$KEY"
  chmod 644 "${KEY}.pub"
  echo "deploy-key-bootstrap: created $KEY — add ${KEY}.pub to GitHub Deploy keys (write)"
fi

if grep -q "$HOST_ALIAS" "$CFG" 2>/dev/null; then
  echo "deploy-key-bootstrap: $HOST_ALIAS already in ~/.ssh/config"
else
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  {
    echo ""
    echo "$MARKER"
    echo "Host $HOST_ALIAS"
    echo "  HostName github.com"
    echo "  User git"
    echo "  IdentityFile $KEY"
    echo "  IdentitiesOnly yes"
  } >>"$CFG"
  echo "deploy-key-bootstrap: appended Host $HOST_ALIAS to ~/.ssh/config"
fi

echo "Remote suggestion: git remote set-url origin git@${HOST_ALIAS}:akshay-na/content-knowledge-base.git (inside ~/content-knowledge-base)"
