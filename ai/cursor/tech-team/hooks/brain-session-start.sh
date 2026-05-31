#!/usr/bin/env bash
# brain-session-start.sh
#
# sessionStart brain bootstrap hook (P3b — implement only; hooks.json enable in P4d).
#
# Resolves kb-identity slug, ensures project .meta/, optionally rebuilds
# session/<session_id>/memory.index.yaml via brain-rebuild-session-index.sh.
#
# Pre-migration guard: skip index rebuild when L0 compass or slug migration
# check is not ready — avoids indexing legacy frontmatter before P4a/P4b.
#
# Fail-open. Honor CURSOR_BRAIN_BOOTSTRAP_DISABLED=1.
#
# Manual smoke (not via hooks.json):
#   echo '{"session_id":"smoke-test","workspace_root":"/path/to/repo"}' \
#     | ./ai/cursor/tech-team/hooks/brain-session-start.sh
#
# shellcheck disable=SC1091

set -u

__self="${BASH_SOURCE[0]}"
__real="$(realpath -q "$__self" 2>/dev/null || printf '%s' "$__self")"
__hooks_dir="$(dirname "$__real")"
# shellcheck source=./brain-common.sh
. "$__hooks_dir/brain-common.sh" 2>/dev/null || exit 0
# shellcheck source=./telemetry-common.sh
. "$__hooks_dir/telemetry-common.sh" 2>/dev/null || exit 0

brain_install_fail_open_trap

input="$(cat 2>/dev/null || true)"

if [ "${CURSOR_BRAIN_BOOTSTRAP_DISABLED:-}" = "1" ]; then
  exit 0
fi

session_id="$(printf '%s' "$input" | telemetry_extract_session_id 2>/dev/null || true)"
[ -z "$session_id" ] && session_id="nosession"
workspace_root="$(printf '%s' "$input" | telemetry_extract_workspace_root 2>/dev/null || true)"
ws_san="$(telemetry_sanitize_path "$workspace_root" 2>/dev/null || printf '%s' "$workspace_root")"

slug=""
if [ -n "$workspace_root" ]; then
  slug="$(brain_resolve_slug "$workspace_root" 2>/dev/null || true)"
fi

# Emit brainBootstrap telemetry (fail-open; uses telemetry JSONL when enabled).
brain_emit_bootstrap() {
  local outcome="$1"
  local l0_ok="$2"
  local migration_ok="$3"
  local summary="$4"
  command -v jq >/dev/null 2>&1 || return 0
  local extra
  extra="$(jq -nc \
    --arg outcome "$outcome" \
    --arg slug "${slug:-}" \
    --argjson l0_ok "$l0_ok" \
    --argjson migration_ok "$migration_ok" \
    --arg contract_version "${BRAIN_CONTRACT_VERSION:-}" \
    --arg workspace_root "$ws_san" \
    --arg summary "$summary" \
    '{
      outcome: $outcome,
      slug: (if $slug == "" then null else $slug end),
      l0_ok: $l0_ok,
      migration_ok: $migration_ok,
      contract_version: (if $contract_version == "" then null else ($contract_version|tonumber) end),
      actor: { workspace_root: $workspace_root },
      summary: $summary
    }' 2>/dev/null)" || return 0
  [ -n "$extra" ] && telemetry_emit_event "brainBootstrap" "$session_id" "$extra" 2>/dev/null || true
}

if [ -z "$slug" ]; then
  brain_emit_bootstrap "skipped_no_slug" false false "brain bootstrap skipped: slug unresolved"
  exit 0
fi

mkdir -p "$BRAIN_ROOT/projects/$slug/.meta" 2>/dev/null || true

l0_ok=false
migration_ok=false
if brain_l0_index_exists; then
  l0_ok=true
fi
if brain_migration_check_slug "$slug"; then
  migration_ok=true
fi

if [ "$l0_ok" = false ] || [ "$migration_ok" = false ]; then
  brain_emit_bootstrap \
    "skipped_pre_migration" \
    "$l0_ok" \
    "$migration_ok" \
    "brain bootstrap skipped pre-migration guard (l0_ok=$l0_ok migration_ok=$migration_ok)"
  exit 0
fi

rebuild_script="$BRAIN_SCRIPTS_DIR/brain-rebuild-session-index.sh"
if [ ! -x "$rebuild_script" ]; then
  brain_emit_bootstrap \
    "skipped_script_missing" \
    "$l0_ok" \
    "$migration_ok" \
    "brain bootstrap skipped: brain-rebuild-session-index.sh not executable"
  exit 0
fi

rebuild_rc=0
"$rebuild_script" "$session_id" "$slug" >/dev/null 2>&1 || rebuild_rc=$?

if [ "$rebuild_rc" -eq 0 ]; then
  brain_emit_bootstrap \
    "ok" \
    "$l0_ok" \
    "$migration_ok" \
    "brain bootstrap ok: session index rebuilt for slug=$slug"
else
  brain_emit_bootstrap \
    "degraded" \
    "$l0_ok" \
    "$migration_ok" \
    "brain bootstrap degraded: rebuild exit $rebuild_rc"
fi

exit 0
