#!/usr/bin/env bash
# kb-sync.sh — pull / commit / push / sync / status for content-knowledge-base.
# Intended to run at end of each cco / metrics-steward invocation (see rules/repo-hygiene.md). Commits only when staged diff non-empty.
set -euo pipefail
REPO="${CONTENT_KB_REPO:-$HOME/content-knowledge-base}"
STATE="$REPO/.git/kb-sync-state.json"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_HELPER="$SCRIPT_DIR/kb-log.sh"
LOCK_DIR="$REPO/.git/kb-sync.lock.dir"
LOCK_TIMEOUT="${KB_SYNC_LOCK_TIMEOUT:-30}"

log() { bash "$LOG_HELPER" INFO "$*" || true; }

write_state() {
  local ok="${1:-}"
  local err="${2:-}"
  local t
  t="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  mkdir -p "$REPO/.git"
  printf '{"last_successful_push_at":"%s","last_error":"%s","updated_at":"%s"}\n' "$ok" "$err" "$t" >"$STATE"
}

read_last_ok() {
  [[ -f "$STATE" ]] || { echo ""; return; }
  sed -n 's/.*"last_successful_push_at"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$STATE" | head -1
}

acquire_lock() {
  local end=$((SECONDS + LOCK_TIMEOUT))
  while true; do
    if mkdir "$LOCK_DIR" 2>/dev/null; then
      echo "$$" >"$LOCK_DIR/pid"
      return 0
    fi
    if (( SECONDS >= end )); then
      log "lock_busy repo=$REPO"
      return 40
    fi
    sleep 0.25
  done
}

release_lock() {
  rm -rf "$LOCK_DIR" 2>/dev/null || true
}

ensure_repo() {
  if [[ ! -d "$REPO/.git" ]]; then
    echo "kb-sync: not a git repository: $REPO" >&2
    exit 1
  fi
}

check_large_files() {
  [[ "${KB_SYNC_ALLOW_LARGE:-}" == "1" ]] && return 0
  cd "$REPO"
  while IFS= read -r f; do
    [[ -z "$f" || ! -f "$f" ]] && continue
    local sz=0
    if [[ "${OSTYPE:-}" == darwin* ]]; then
      sz=$(stat -f%z "$f" 2>/dev/null || echo 0)
    else
      sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
    fi
    if (( sz > 10 * 1024 * 1024 )); then
      echo "kb-sync: file >10MB (set KB_SYNC_ALLOW_LARGE=1): $f" >&2
      exit 41
    fi
  done < <(git ls-files)
}

stage_policy() {
  local force="${1:-}"
  cd "$REPO"
  local p
  for p in kb/_meta kb/50-Published kb/60-Repurposed kb/90-Analytics memory docs runbooks integrations scripts; do
    [[ -e "$p" ]] && git add -A -- "$p" 2>/dev/null || true
  done
  for p in kb/00-Home.md kb/30-Briefs kb/70-Topics kb/80-Brand; do
    [[ -e "$p" ]] && git add -A -- "$p" 2>/dev/null || true
  done
  if [[ "$force" == "--force" || "${KB_SYNC_INCLUDE_DRAFTS:-}" == "1" ]]; then
    [[ -d kb/40-Drafts ]] && git add -A -- kb/40-Drafts 2>/dev/null || true
  fi
}

cmd_pull() {
  ensure_repo
  acquire_lock || exit $?
  trap release_lock EXIT
  cd "$REPO"
  if ! git pull --rebase --autostash; then
    log "pull_failed repo=$REPO"
    write_state "$(read_last_ok)" "pull_conflict_or_failed"
    exit 30
  fi
  log "pull_ok repo=$REPO"
}

cmd_commit() {
  local force="${1:-}"
  ensure_repo
  acquire_lock || exit $?
  trap release_lock EXIT
  cd "$REPO"
  check_large_files
  stage_policy "$force"
  if git diff --cached --quiet; then
    log "nothing_to_commit repo=$REPO"
    release_lock
    trap - EXIT
    exit 10
  fi
  local scope
  scope="$(git diff --cached --name-only | awk -F/ '{print $1}' | sort -u | head -3 | tr '\n' ',' | sed 's/,$//')"
  git commit -m "kb: ${scope:-sync} @$(git rev-parse --short HEAD 2>/dev/null || echo local)"
  log "commit_ok repo=$REPO scope=$scope"
}

cmd_push() {
  ensure_repo
  acquire_lock || exit $?
  trap release_lock EXIT
  cd "$REPO"
  local prev
  prev="$(read_last_ok)"
  if ! git push; then
    log "push_failed repo=$REPO"
    write_state "$prev" "push_failed"
    exit 20
  fi
  write_state "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" ""
  log "push_ok repo=$REPO"
}

cmd_sync() {
  ensure_repo
  acquire_lock || exit $?
  trap release_lock EXIT
  cd "$REPO"
  if ! git pull --rebase --autostash; then
    log "pull_failed repo=$REPO"
    write_state "$(read_last_ok)" "pull_conflict_or_failed"
    exit 30
  fi
  check_large_files
  stage_policy "${1:-}"
  if ! git diff --cached --quiet; then
    local scope
    scope="$(git diff --cached --name-only | awk -F/ '{print $1}' | sort -u | head -3 | tr '\n' ',' | sed 's/,$//')"
    git commit -m "kb: ${scope:-sync} @$(git rev-parse --short HEAD 2>/dev/null || echo local)"
    log "commit_ok repo=$REPO scope=$scope"
  else
    log "nothing_to_commit repo=$REPO"
  fi
  local prev
  prev="$(read_last_ok)"
  if ! git push; then
    log "push_failed repo=$REPO"
    write_state "$prev" "push_failed"
    exit 20
  fi
  write_state "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" ""
  log "push_ok repo=$REPO"
}

cmd_status() {
  exec "$SCRIPT_DIR/kb-status.sh"
}

main() {
  local sub="${1:-status}"
  shift || true
  case "$sub" in
  pull) cmd_pull ;;
  commit) cmd_commit "${1:-}" ;;
  push) cmd_push ;;
  sync) cmd_sync "${1:-}" ;;
  status) cmd_status ;;
  *)
    echo "usage: kb-sync.sh pull|commit|push|sync|status [--force]" >&2
    exit 2
    ;;
  esac
}

main "$@"
