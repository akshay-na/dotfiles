#!/usr/bin/env bash
# Pinned sandbox: never touches real HOME symlinks; HOME is overridden only for stow -n.
set -euo pipefail

REAL_HOME="${HOME:?}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

TMP="$(mktemp -d)"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

snapshot_home() {
  ls -A "$REAL_HOME" | LC_ALL=C sort
}

snapshot_home >"$TMP/home.before"

FAKEHOME="$TMP/fakehome"
mkdir -p "$FAKEHOME"
LOCAL_DIR="$TMP/local"

cd "$REPO_ROOT"

# Hermetic / no-git CI: VERIFY_SKIP_GIT_INIT=1 skips git init + HEAD assertions
if [ "${VERIFY_SKIP_GIT_INIT:-0}" = 1 ]; then
  export SKIP_GIT_INIT=1
fi

run_bootstrap() {
  make bootstrap_local LOCAL_DIR="$LOCAL_DIR" DOTMATE_CANONICAL_ROOT="$REPO_ROOT"
}

run_bootstrap

die() { echo "verify-bootstrap-local: $*" >&2; exit 1; }

assert_file() {
  [ -f "$1" ] || die "missing file: $1"
}

assert_dir() {
  [ -d "$1" ] || die "missing dir: $1"
}

assert_file "$LOCAL_DIR/scripts/DotMate.sh"
assert_file "$LOCAL_DIR/Makefile"
assert_file "$LOCAL_DIR/.stowrc"
assert_file "$LOCAL_DIR/.gitignore"
assert_file "$LOCAL_DIR/shell/.commonrc_local"
assert_file "$LOCAL_DIR/shell/.functions_local"
assert_file "$LOCAL_DIR/shell/.aliases_local"
assert_file "$LOCAL_DIR/shell/.zshrc_local"
assert_file "$LOCAL_DIR/shell/.bashrc_local"
assert_file "$LOCAL_DIR/shell/.tmux_local.conf"
assert_file "$LOCAL_DIR/git/.gitconfig_local"
assert_file "$LOCAL_DIR/ssh/.ssh/config_local"
assert_file "$LOCAL_DIR/utilities/.taskrc_local"

if [ "${SKIP_GIT_INIT:-0}" != "1" ] && command -v git >/dev/null 2>&1; then
  assert_file "$LOCAL_DIR/.git/HEAD"
else
  :
fi

# Second run must be idempotent for on-disk content
checksum_tree() {
  find "$1" -type f ! -path '*/.git/*' -print0 | LC_ALL=C sort -z | xargs -0 shasum 2>/dev/null || \
    find "$1" -type f ! -path '*/.git/*' -print0 | LC_ALL=C sort -z | xargs -0 cksum
}
sum1="$(checksum_tree "$LOCAL_DIR")"
run_bootstrap
sum2="$(checksum_tree "$LOCAL_DIR")"
[ "$sum1" = "$sum2" ] || die "tree checksum drift after second bootstrap"

if [ "${SKIP_GIT_INIT:-0}" != "1" ] && command -v git >/dev/null 2>&1; then
  out="$(git -C "$LOCAL_DIR" status --porcelain -uno 2>/dev/null || true)"
  [ -z "$out" ] || die "unexpected tracked changes after second bootstrap: $out"
fi

# Stow dry-run: package list mirrors stow_dotfiles (direct children, exclude ai + scripts)
stow_pkgs=()
for d in "$LOCAL_DIR"/*/; do
  [ -d "$d" ] || continue
  base="$(basename "$d")"
  case "$base" in
  ai | scripts) continue ;;
  esac
  stow_pkgs+=("$base")
done
((${#stow_pkgs[@]})) || die "derived stow package list is empty"

HOME="$FAKEHOME" stow -n -d "$LOCAL_DIR" -t "$FAKEHOME" "${stow_pkgs[@]}"

snapshot_home >"$TMP/home.after"
cmp -s "$TMP/home.before" "$TMP/home.after" || die "real HOME listing changed (must stay identical)"

echo "verify-bootstrap-local: OK"
exit 0
