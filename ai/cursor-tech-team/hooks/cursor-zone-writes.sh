#!/usr/bin/env bash
# cursor-zone-writes.sh
#
# preToolUse hook (matcher: Write|Edit|StrReplace|MultiEdit|Delete).
# Auto-approves any write/edit/delete whose target path resolves into one of
# the "trusted Cursor zones" — where agent-managed content lives and any
# write is, by policy, considered safe to apply without a user prompt.
#
# Applies to ANY agent. The hook is grant-only: if the
# target path is outside the trusted zones it exits 0 silently and the default
# Cursor approval flow continues unchanged. The hook never denies.
#
# Trusted zones (both the literal path AND its realpath canonical form are
# checked, so symlinked / stowed paths are auto-approved too):
#
#   Global (user-level):
#     $HOME/.cursor/docs/**      — user docs (includes knowledge-base vault)
#     $HOME/.cursor/memory/**    — user memory
#     $HOME/ai-brain/**         — unified ai-brain vault (org/projects/session)
#     $HOME/.cursor/ai-brain/** — legacy/alternate brain location (symlink or copy)
#
#   Global stow source (dotfiles repo — same files via symlink):
#     $HOME/dotfiles/ai/cursor-tech-team/docs/**
#     $HOME/dotfiles/ai/cursor-tech-team/memory/**
#     $HOME/dotfiles/ai/ai-brain/**
#
#   Workspace / project-level:
#     $workspace_root/.cursor/** — everything under the project's .cursor/
#                                  (rules, agents, skills, docs, memory, hooks, etc.)
#
# Workspace root is taken from the hook input JSON (.workspace_root or .cwd),
# with $PWD as a last-resort fallback.

set -uo pipefail

# Fail-open if jq is missing. Never break the agent flow because of a tooling gap.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

input="$(cat)"

tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
case "$tool" in
Write | Edit | StrReplace | MultiEdit | Delete | create_file | edit_file | write_file) ;;
*) exit 0 ;;
esac

# Extract the target path. Tool-input field name varies across Cursor versions;
# try the common ones in order.
path="$(printf '%s' "$input" | jq -r '
  .tool_input.path //
  .tool_input.file_path //
  .tool_input.target_file //
  .tool_input.filePath //
  .tool_input.filename //
  empty
')"

[ -z "$path" ] && exit 0

# Expand a leading literal `~/` (the `~` inside a parameter expansion must be
# escaped or bash would tilde-expand it itself and the strip would no-op).
case "$path" in
"~/"*) path="$HOME/${path#\~/}" ;;
"~") path="$HOME" ;;
esac

# Determine workspace root (for project-level .cursor/ detection).
workspace_root="$(printf '%s' "$input" | jq -r '
  .workspace_root //
  .workspaceRoot //
  .project_root //
  .projectRoot //
  .cwd //
  empty
')"
[ -z "$workspace_root" ] && workspace_root="$PWD"

# If the reported path is relative, anchor it against the workspace root.
case "$path" in
/*) ;;
*) path="$workspace_root/$path" ;;
esac

# Canonicalize (resolves symlinks). Fall back to the literal path if realpath
# fails (the file may not exist yet for a create operation — realpath -q still
# resolves as much as it can, but guard anyway).
canonical="$(realpath -q "$path" 2>/dev/null || printf '%s' "$path")"

# Build the set of trusted-zone prefixes (literal and canonicalized).
HOME_DOCS="$HOME/.cursor/docs"
HOME_MEM="$HOME/.cursor/memory"
HOME_BRAIN="$HOME/ai-brain"
HOME_BRAIN_CURSOR="$HOME/.cursor/ai-brain"
STOW_DOCS="$HOME/dotfiles/ai/cursor-tech-team/docs"
STOW_MEM="$HOME/dotfiles/ai/cursor-tech-team/memory"
STOW_BRAIN="$HOME/dotfiles/ai/ai-brain"
WS_CURSOR="$workspace_root/.cursor"

# Also compute the canonical form of each zone so that when an agent edits via
# a symlink that points back into dotfiles, the canonical check still matches.
HOME_DOCS_R="$(realpath -q "$HOME_DOCS" 2>/dev/null || printf '%s' "$HOME_DOCS")"
HOME_MEM_R="$(realpath -q "$HOME_MEM" 2>/dev/null || printf '%s' "$HOME_MEM")"
HOME_BRAIN_R="$(realpath -q "$HOME_BRAIN" 2>/dev/null || printf '%s' "$HOME_BRAIN")"
HOME_BRAIN_CURSOR_R="$(realpath -q "$HOME_BRAIN_CURSOR" 2>/dev/null || printf '%s' "$HOME_BRAIN_CURSOR")"
STOW_DOCS_R="$(realpath -q "$STOW_DOCS" 2>/dev/null || printf '%s' "$STOW_DOCS")"
STOW_MEM_R="$(realpath -q "$STOW_MEM" 2>/dev/null || printf '%s' "$STOW_MEM")"
STOW_BRAIN_R="$(realpath -q "$STOW_BRAIN" 2>/dev/null || printf '%s' "$STOW_BRAIN")"
WS_CURSOR_R="$(realpath -q "$WS_CURSOR" 2>/dev/null || printf '%s' "$WS_CURSOR")"

approve() {
  local reason="$1"
  printf '{"permission":"allow","agent_message":"cursor-zone-writes: auto-approved (%s)"}\n' "$reason"
  exit 0
}

# Literal-path match
case "$path" in
"$HOME_DOCS"/*) approve "~/.cursor/docs" ;;
"$HOME_MEM"/*) approve "~/.cursor/memory" ;;
"$HOME_BRAIN"/*) approve "~/ai-brain" ;;
"$HOME_BRAIN_CURSOR"/*) approve "~/.cursor/ai-brain" ;;
"$STOW_DOCS"/*) approve "dotfiles docs stow source" ;;
"$STOW_MEM"/*) approve "dotfiles memory stow source" ;;
"$STOW_BRAIN"/*) approve "dotfiles ai-brain stow source" ;;
"$WS_CURSOR"/*) approve "workspace .cursor" ;;
esac

# Canonical-path match (handles symlinked paths)
case "$canonical" in
"$HOME_DOCS_R"/*) approve "~/.cursor/docs (canonical)" ;;
"$HOME_MEM_R"/*) approve "~/.cursor/memory (canonical)" ;;
"$HOME_BRAIN_R"/*) approve "~/ai-brain (canonical)" ;;
"$HOME_BRAIN_CURSOR_R"/*) approve "~/.cursor/ai-brain (canonical)" ;;
"$STOW_DOCS_R"/*) approve "dotfiles docs stow source (canonical)" ;;
"$STOW_MEM_R"/*) approve "dotfiles memory stow source (canonical)" ;;
"$STOW_BRAIN_R"/*) approve "dotfiles ai-brain stow source (canonical)" ;;
"$WS_CURSOR_R"/*) approve "workspace .cursor (canonical)" ;;
esac

# Not a trusted zone — fall through to normal approval flow.
exit 0
