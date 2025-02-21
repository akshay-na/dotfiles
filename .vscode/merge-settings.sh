#!/bin/bash

if [[ "$OSTYPE" == "darwin"* ]]; then
  LOCAL_SETTINGS="$HOME/Library/Application Support/Code/User/settings.json"
else
  LOCAL_SETTINGS="$HOME/.config/Code/User/settings.json"
fi

WORKSPACE_SETTINGS=".vscode/settings.json"

if [[ -f "$WORKSPACE_SETTINGS" ]]; then
  if [[ -f "$LOCAL_SETTINGS" ]]; then
    jq -s '.[0] * .[1]' "$LOCAL_SETTINGS" "$WORKSPACE_SETTINGS" | jq 'unique_by(keys_unsorted)' >"$LOCAL_SETTINGS.tmp"
    mv "$LOCAL_SETTINGS.tmp" "$LOCAL_SETTINGS"
  else
    cp "$WORKSPACE_SETTINGS" "$LOCAL_SETTINGS"
  fi
fi
