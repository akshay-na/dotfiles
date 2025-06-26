#!/usr/bin/env bash

# Determine IdentityAgent dynamically
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  agent_path="$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  agent_path="/run/user/$(id -u)/gnupg/S.gpg-agent.ssh"
elif grep -q Microsoft /proc/version &>/dev/null; then
  # WSL
  agent_path="/mnt/c/Users/aksha/AppData/Local/gnupg/S.gpg-agent.ssh"
else
  echo "No agentic path found for this OS"
fi
