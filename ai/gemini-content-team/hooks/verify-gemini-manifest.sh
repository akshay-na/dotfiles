#!/usr/bin/env bash
# verify-gemini-manifest.sh — paired-path drift detector for Cursor ↔ Gemini content packs.
#
# OR-07 enforcement (parity plan § "Dual-pack drift control"). Compares changes
# between `ai/cursor-content-team/` and `ai/gemini-content-team/` against the
# pair rules + exclusion lists in this directory.
#
# Modes:
#   (default)        — diff working tree + untracked vs HEAD
#   --staged         — diff staged index vs HEAD (use from pre-commit)
#   --against <ref>  — diff working tree vs <ref> (use from CI: --against origin/main)
#   --all            — full inventory check: every paired path must exist on disk
#
# Direction:
#   Default checks **cursor → gemini** only (the parity plan's mandate: any
#   behavioral change to the canonical cursor pack must have a paired gemini
#   change). Use --bidirectional to also flag gemini-side changes without a
#   matching cursor-side change (informational; can be noisy during bootstrap
#   ports or Gemini-specific tweaks).
#
# Behavior:
#   Exit 0 when no drift (or --warn). Exit 1 on drift findings.
#
# Usage:
#   ./verify-gemini-manifest.sh                     # local pre-commit-ish check
#   ./verify-gemini-manifest.sh --staged            # strict staged-only check
#   ./verify-gemini-manifest.sh --against origin/main
#   ./verify-gemini-manifest.sh --all               # structural integrity
#   ./verify-gemini-manifest.sh --warn              # never exit non-zero
#   ./verify-gemini-manifest.sh -v                  # verbose: show exemptions
#
# See also:
#   docs/runbooks/cursor-only-exclusions.md         # human rationale for cursor-only rows
#   docs/plans/2026-05-10-gemini-content-team-parity.md (in dotfiles/.cursor/docs/)

set -euo pipefail
shopt -s extglob

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
fi

CURSOR_EXCL_FILE="$SCRIPT_DIR/manifest-exclusions.txt"
GEMINI_EXCL_FILE="$SCRIPT_DIR/manifest-gemini-only.txt"

CURSOR_ROOT="ai/cursor-content-team"
GEMINI_ROOT="ai/gemini-content-team"

MODE="diff"
BASE_REF="HEAD"
WARN_ONLY=0
VERBOSE=0
BIDIRECTIONAL=0

usage() {
  sed -n '2,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --staged) MODE="staged"; shift ;;
    --against) MODE="against"; BASE_REF="$2"; shift 2 ;;
    --all) MODE="all"; shift ;;
    --warn) WARN_ONLY=1; shift ;;
    --bidirectional) BIDIRECTIONAL=1; shift ;;
    -v|--verbose) VERBOSE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "verify-gemini-manifest: unknown arg '$1'" >&2; exit 2 ;;
  esac
done

log_v() {
  [[ $VERBOSE -eq 1 ]] && echo "  $*" >&2 || true
}

load_globs() {
  local file="$1"
  [[ -f "$file" ]] || return 0
  awk '!/^[[:space:]]*#/ && NF { print }' "$file"
}

# Bash glob match (extglob enabled). Returns 0 if path matches any glob.
matches_any() {
  local path="$1"
  local glob
  shift
  for glob in "$@"; do
    [[ -z "$glob" ]] && continue
    case "$path" in
      $glob) return 0 ;;
    esac
  done
  return 1
}

# ----- twin-path mapping ----------------------------------------------------
twin_for_cursor() {
  local cp="$1"
  case "$cp" in
    "$CURSOR_ROOT/rules/trusted-cursor-edit-zones.mdc")
      echo "$GEMINI_ROOT/rules/trusted-edit-zones.md"; return ;;
    "$CURSOR_ROOT/configurations/pipelines/article.yml")
      echo "$GEMINI_ROOT/configurations/article.yml"; return ;;
  esac
  if [[ "$cp" == $CURSOR_ROOT/rules/*.mdc ]]; then
    local rest="${cp#$CURSOR_ROOT/}"
    rest="${rest%.mdc}.md"
    echo "$GEMINI_ROOT/$rest"
    return
  fi
  if [[ "$cp" == $CURSOR_ROOT/* ]]; then
    echo "$GEMINI_ROOT/${cp#$CURSOR_ROOT/}"
    return
  fi
  echo ""
}

twin_for_gemini() {
  local gp="$1"
  case "$gp" in
    "$GEMINI_ROOT/rules/trusted-edit-zones.md")
      echo "$CURSOR_ROOT/rules/trusted-cursor-edit-zones.mdc"; return ;;
    "$GEMINI_ROOT/configurations/article.yml")
      echo "$CURSOR_ROOT/configurations/pipelines/article.yml"; return ;;
  esac
  if [[ "$gp" == $GEMINI_ROOT/rules/*.md ]]; then
    local rest="${gp#$GEMINI_ROOT/}"
    rest="${rest%.md}.mdc"
    echo "$CURSOR_ROOT/$rest"
    return
  fi
  if [[ "$gp" == $GEMINI_ROOT/* ]]; then
    echo "$CURSOR_ROOT/${gp#$GEMINI_ROOT/}"
    return
  fi
  echo ""
}

# ----- changed-file collectors ----------------------------------------------
get_changed_diff() {
  # Working tree + untracked, vs $BASE_REF
  git -C "$ROOT" diff --name-only "$BASE_REF" -- "$CURSOR_ROOT" "$GEMINI_ROOT" 2>/dev/null
  git -C "$ROOT" ls-files --others --exclude-standard -- "$CURSOR_ROOT" "$GEMINI_ROOT" 2>/dev/null
  # Renames/deletes already covered by `git diff --name-only` (shows both old/new)
}

get_changed_staged() {
  git -C "$ROOT" diff --name-only --cached -- "$CURSOR_ROOT" "$GEMINI_ROOT" 2>/dev/null
}

get_changed_against() {
  git -C "$ROOT" diff --name-only "$BASE_REF" -- "$CURSOR_ROOT" "$GEMINI_ROOT" 2>/dev/null
}

get_all_files() {
  # Tracked + untracked (excluding .gitignore) under both packs
  git -C "$ROOT" ls-files -- "$CURSOR_ROOT" "$GEMINI_ROOT" 2>/dev/null
  git -C "$ROOT" ls-files --others --exclude-standard -- "$CURSOR_ROOT" "$GEMINI_ROOT" 2>/dev/null
}

# ----- main ------------------------------------------------------------------
mapfile -t CURSOR_EXCLUDED < <(load_globs "$CURSOR_EXCL_FILE")
mapfile -t GEMINI_EXCLUDED < <(load_globs "$GEMINI_EXCL_FILE")

case "$MODE" in
  diff)    files="$(get_changed_diff | sort -u)" ;;
  staged)  files="$(get_changed_staged | sort -u)" ;;
  against) files="$(get_changed_against | sort -u)" ;;
  all)     files="$(get_all_files | sort -u)" ;;
esac

declare -A IN_CURSOR IN_GEMINI
while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  case "$f" in
    $CURSOR_ROOT/*) IN_CURSOR["$f"]=1 ;;
    $GEMINI_ROOT/*) IN_GEMINI["$f"]=1 ;;
  esac
done <<<"$files"

findings=0

check_cursor_side() {
  local cf
  for cf in "${!IN_CURSOR[@]}"; do
    if matches_any "$cf" "${CURSOR_EXCLUDED[@]}"; then
      log_v "exempt (cursor-only): $cf"
      continue
    fi
    local twin
    twin="$(twin_for_cursor "$cf")"
    if [[ -z "$twin" ]]; then
      log_v "no-twin-rule: $cf"
      continue
    fi
    if [[ "$MODE" == "all" ]]; then
      if [[ ! -e "$ROOT/$twin" ]]; then
        echo "DRIFT: $cf has no Gemini twin on disk (expected $twin)"
        findings=$((findings + 1))
      else
        log_v "ok pair: $cf ↔ $twin"
      fi
    else
      if [[ -z "${IN_GEMINI[$twin]+x}" ]]; then
        echo "DRIFT: $cf changed but Gemini twin $twin did not"
        findings=$((findings + 1))
      else
        log_v "paired change: $cf ↔ $twin"
      fi
    fi
  done
}

check_gemini_side() {
  local gf
  for gf in "${!IN_GEMINI[@]}"; do
    if matches_any "$gf" "${GEMINI_EXCLUDED[@]}"; then
      log_v "exempt (gemini-only): $gf"
      continue
    fi
    local twin
    twin="$(twin_for_gemini "$gf")"
    if [[ -z "$twin" ]]; then
      log_v "no-twin-rule: $gf"
      continue
    fi
    if [[ "$MODE" == "all" ]]; then
      if [[ ! -e "$ROOT/$twin" ]]; then
        echo "DRIFT: $gf has no Cursor twin on disk (expected $twin)"
        findings=$((findings + 1))
      else
        log_v "ok pair: $gf ↔ $twin"
      fi
    else
      if [[ -z "${IN_CURSOR[$twin]+x}" ]]; then
        echo "DRIFT: $gf changed but Cursor twin $twin did not"
        findings=$((findings + 1))
      else
        log_v "paired change: $gf ↔ $twin"
      fi
    fi
  done
}

check_cursor_side
if [[ $BIDIRECTIONAL -eq 1 || "$MODE" == "all" ]]; then
  check_gemini_side
fi

if [[ $findings -gt 0 ]]; then
  echo "verify-gemini-manifest: $findings drift finding(s) — mode=$MODE base=$BASE_REF" >&2
  echo "Hint: pair the change in the other pack, OR add to:" >&2
  echo "  $CURSOR_EXCL_FILE  (cursor-only path)" >&2
  echo "  $GEMINI_EXCL_FILE  (gemini-only path)" >&2
  echo "  and document rationale in docs/runbooks/cursor-only-exclusions.md" >&2
  if [[ $WARN_ONLY -eq 1 ]]; then
    echo "verify-gemini-manifest: --warn set, exiting 0" >&2
    exit 0
  fi
  exit 1
fi

echo "verify-gemini-manifest: OK (no drift, mode=$MODE)"
