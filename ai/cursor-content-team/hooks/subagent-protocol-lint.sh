#!/usr/bin/env bash
# subagent-protocol-lint.sh — content org (JSON envelope)
#
# Blocks distinctive contract phrases outside SoT files under this pack.
# Scans: .cursor/rules/*.mdc, .cursor/skills/**/SKILL.md, .cursor/agents/*.md

set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_REAL="$(realpath -q "$SELF" 2>/dev/null || printf '%s' "$SELF")"
CURSOR_DIR="$(dirname "$(dirname "$SELF_REAL")")"
REPO_ROOT="$(cd "$CURSOR_DIR/.." && pwd)"

is_exempt() {
  case "$1" in
    */contracts/schemas/subagent-response.schema.json) return 0 ;;
    */contracts/schemas/main-agent-response.schema.json) return 0 ;;
    */templates/subagent-response.example.json) return 0 ;;
    */templates/main-agent-response.example.json) return 0 ;;
    */contracts/subagent-contract-block.md) return 0 ;;
    */contracts/headless-agent-contract.json) return 0 ;;
  esac
  return 1
}

# Phrases that must only appear in subagent-contract-block.md
PAT_CONTRACT1='REFORMAT ONLY\. Do not redo work'
PAT_CONTRACT2='No prose outside'

targets=()
mode="all"
if [ "$#" -gt 0 ]; then
  case "$1" in
    --staged) mode="staged"; shift ;;
    *) mode="files" ;;
  esac
fi

case "$mode" in
  staged)
    while IFS= read -r f; do
      case "$f" in
        */.cursor/rules/*.mdc) targets+=("$REPO_ROOT/$f") ;;
        */.cursor/skills/*/SKILL.md) targets+=("$REPO_ROOT/$f") ;;
        */.cursor/agents/*.md) targets+=("$REPO_ROOT/$f") ;;
      esac
    done < <(git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACM 2>/dev/null)
    ;;
  files)
    for f in "$@"; do
      case "$f" in
        /*) p="$f" ;;
        *) p="$REPO_ROOT/$f" ;;
      esac
      targets+=("$p")
    done
    ;;
  all)
    while IFS= read -r f; do targets+=("$f"); done < <(
      find "$CURSOR_DIR/rules" -name '*.mdc' 2>/dev/null
      find "$CURSOR_DIR/skills" -name 'SKILL.md' 2>/dev/null
      find "$CURSOR_DIR/agents" -name '*.md' 2>/dev/null
    )
    ;;
esac

[ "${#targets[@]}" -eq 0 ] && exit 0

if command -v rg >/dev/null 2>&1; then
  scan() { rg -n --no-heading --color=never "$1" "$2" 2>/dev/null; }
else
  scan() { grep -nE "$1" "$2" 2>/dev/null; }
fi

violations=0
for f in "${targets[@]}"; do
  [ -f "$f" ] || continue
  is_exempt "$f" && continue
  for pat in "$PAT_CONTRACT1" "$PAT_CONTRACT2"; do
    m="$(scan "$pat" "$f")"
    if [ -n "$m" ]; then
      printf 'subagent-protocol-lint: DRIFT (contract phrase) in %s\n' "${f#"$REPO_ROOT/"}"
      printf '%s\n' "$m"
      violations=$((violations + 1))
    fi
  done
done

if [ "$violations" -gt 0 ]; then
  printf '\nsubagent-protocol-lint: %d violation(s). Canonical text lives in contracts/subagent-contract-block.md; schemas under contracts/schemas/.\n' "$violations" >&2
  exit 1
fi
exit 0
