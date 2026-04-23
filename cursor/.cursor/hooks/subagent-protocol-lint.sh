#!/usr/bin/env bash
# subagent-protocol-lint.sh
#
# Pre-commit lint (D16). Rejects drift of the two SoT templates:
#   - `templates/subagent-response.yml.tmpl`      — the authoritative schema
#   - `templates/subagent-contract-block.md`      — the authoritative contract
#
# Blocks any commit (or returns non-zero on manual run) when distinctive
# contract/schema phrases appear OUTSIDE the SoT template files, inside:
#   - .cursor/rules/**.mdc
#   - .cursor/skills/**/SKILL.md
#   - .cursor/agents/**.md
#
# Usage:
#   subagent-protocol-lint.sh                    # scan the whole dotfiles tree
#   subagent-protocol-lint.sh file1 file2 ...    # scan specific files (pre-commit)
#   subagent-protocol-lint.sh --staged           # scan files staged in git index
#
# Exit codes: 0 clean, 1 drift found, 2 tooling error.
#
# POSIX-safe bash, no GNU-only flags. Prefers `rg` if available, falls back to
# grep -RE.

set -uo pipefail

SELF="${BASH_SOURCE[0]}"
SELF_REAL="$(realpath -q "$SELF" 2>/dev/null || printf '%s' "$SELF")"
CURSOR_DIR="$(dirname "$(dirname "$SELF_REAL")")"
REPO_ROOT="$(cd "$CURSOR_DIR/.." && pwd)"

# Exempt paths (absolute + repo-relative forms both accepted on match)
EXEMPT_SCHEMA="cursor/.cursor/templates/subagent-response.yml.tmpl"
EXEMPT_CONTRACT="cursor/.cursor/templates/subagent-contract-block.md"

# The distinctive strings we are guarding. ERE patterns.
# Using bounded word boundaries so we don't trip on `schema_versions` (plural)
# or other legitimate uses.
PAT_SCHEMA='(^|[^_A-Za-z])schema_version:[[:space:]]+1([[:space:]]|$|#)'
PAT_CONTRACT1='REFORMAT ONLY\. Do not redo work'
PAT_CONTRACT2='No prose outside the fence'

# Targets: override via args, or default to scanning rules/skills/agents under
# cursor/.cursor/.
targets=()
mode="all"
if [ "$#" -gt 0 ]; then
  case "$1" in
    --staged)
      mode="staged"
      shift
      ;;
    *)
      mode="files"
      ;;
  esac
fi

case "$mode" in
  staged)
    # Files staged for commit, filtered to our glob set.
    while IFS= read -r f; do
      case "$f" in
        cursor/.cursor/rules/*.mdc) targets+=("$REPO_ROOT/$f") ;;
        cursor/.cursor/skills/*/SKILL.md) targets+=("$REPO_ROOT/$f") ;;
        cursor/.cursor/agents/*.md) targets+=("$REPO_ROOT/$f") ;;
      esac
    done < <(git -C "$REPO_ROOT" diff --cached --name-only --diff-filter=ACM 2>/dev/null)
    ;;
  files)
    for f in "$@"; do
      case "$f" in
        /*) p="$f" ;;
        *)  p="$REPO_ROOT/$f" ;;
      esac
      targets+=("$p")
    done
    ;;
  all)
    # Default: scan the entire dotfiles cursor tree.
    while IFS= read -r f; do
      targets+=("$f")
    done < <(find "$CURSOR_DIR/rules" -name '*.mdc' 2>/dev/null; \
             find "$CURSOR_DIR/skills" -name 'SKILL.md' 2>/dev/null; \
             find "$CURSOR_DIR/agents" -name '*.md' 2>/dev/null)
    ;;
esac

if [ "${#targets[@]}" -eq 0 ]; then
  exit 0
fi

# Determine scanner.
if command -v rg >/dev/null 2>&1; then
  scan() { rg -n --no-heading --color=never "$1" "$2" 2>/dev/null; }
else
  scan() { grep -nE "$1" "$2" 2>/dev/null; }
fi

is_exempt() {
  case "$1" in
    *"$EXEMPT_SCHEMA") return 0 ;;
    *"$EXEMPT_CONTRACT") return 0 ;;
  esac
  return 1
}

violations=0
for f in "${targets[@]}"; do
  [ -f "$f" ] || continue
  if is_exempt "$f"; then
    continue
  fi
  # schema pattern — only blocked outside the schema template
  m="$(scan "$PAT_SCHEMA" "$f")"
  if [ -n "$m" ]; then
    printf 'subagent-protocol-lint: DRIFT (schema_version) in %s\n' "${f#"$REPO_ROOT/"}"
    printf '%s\n' "$m"
    violations=$((violations + 1))
  fi
  # contract phrases — only blocked outside the contract template
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
  printf '\nsubagent-protocol-lint: %d violation(s). See ~/.cursor/templates/subagent-response.yml.tmpl and ~/.cursor/templates/subagent-contract-block.md for canonical text.\n' "$violations" >&2
  exit 1
fi

exit 0
