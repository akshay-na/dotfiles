#!/usr/bin/env bash
# telemetry-common.sh — shared library for the agent-orchestration telemetry
# hook pipeline.
#
# Sourced by every `telemetry-*` hook script. Provides:
#   - configuration loading (configurations/telemetry.yml + env overrides)
#   - log directory + cache dir setup with safe perms
#   - daily rotation + retention pruning (called from sessionStart)
#   - correlation-ID lookups (session_id, trace_id, tool_call_id, subagent_run_id)
#   - secret redaction (pattern-library only — fast, deterministic, fail-open)
#   - JSONL event writer with size caps + redaction
#   - utility helpers (now_ms, iso8601_utc, sanitize_path, short_basename)
#
# DESIGN PRINCIPLES
#   * Fail-open. Telemetry must NEVER break the agent flow. Any error inside a
#     hook script is swallowed; the script always exits 0.
#   * No raw payloads. Tool inputs, command strings, file bodies, stdouts, and
#     stderrs are NEVER persisted. Only sanitized metadata + redacted summary.
#   * No secrets. The redaction pattern library covers AWS / Slack / Anthropic /
#     OpenAI / Stripe / GitHub / GitLab / npm / Twilio / Google / JWT / Bearer /
#     URL userinfo / private key blocks / generic ENV-style assignments.
#   * Tiny dependency surface. Bash + jq + standard unix tools only.
#
# This file is sourced, not executed. It does not call exit on its own.
#
# shellcheck shell=bash disable=SC2034,SC2155

# Guard against double-sourcing.
if [ -n "${__TELEMETRY_COMMON_LOADED:-}" ]; then
  return 0 2>/dev/null || true
fi
__TELEMETRY_COMMON_LOADED=1

# --- resolve paths -----------------------------------------------------------
# Each hook lives in <pack>/hooks/. The library is sibling. Resolve the pack
# root (the directory two levels up from the resolved library path).
__telemetry_self="${BASH_SOURCE[0]}"
__telemetry_real="$(realpath -q "$__telemetry_self" 2>/dev/null || printf '%s' "$__telemetry_self")"
TELEMETRY_HOOKS_DIR="$(dirname "$__telemetry_real")"
TELEMETRY_PACK_DIR="$(dirname "$TELEMETRY_HOOKS_DIR")"

# Pack identity: read from configurations/pack-identity.yml. Falls back to
# "unknown" so the hook still works on a partial install.
TELEMETRY_PACK_ID="unknown"
__telemetry_pack_identity_file="$TELEMETRY_PACK_DIR/configurations/pack-identity.yml"
if [ -r "$__telemetry_pack_identity_file" ]; then
  __telemetry_id="$(grep -E '^pack_id:' "$__telemetry_pack_identity_file" 2>/dev/null | head -1 | awk '{print $2}' | tr -d '"' | tr -d "'")"
  [ -n "$__telemetry_id" ] && TELEMETRY_PACK_ID="$__telemetry_id"
fi

# --- runtime config ----------------------------------------------------------
# Defaults; may be overridden by configurations/telemetry.yml or env vars.
TELEMETRY_ENABLED="${CURSOR_TELEMETRY_ENABLED:-1}"
TELEMETRY_LOG_DIR="${CURSOR_TELEMETRY_DIR:-$HOME/.cursor/logs/telemetry}"
TELEMETRY_RETENTION_DAYS="${CURSOR_TELEMETRY_RETENTION_DAYS:-14}"
TELEMETRY_FIELD_CAP_CHARS="${CURSOR_TELEMETRY_FIELD_CAP_CHARS:-200}"
TELEMETRY_SUMMARY_CAP_CHARS="${CURSOR_TELEMETRY_SUMMARY_CAP_CHARS:-256}"
TELEMETRY_EVENT_CAP_BYTES="${CURSOR_TELEMETRY_EVENT_CAP_BYTES:-4096}"

__telemetry_config_file="$TELEMETRY_PACK_DIR/configurations/telemetry.yml"
if [ -r "$__telemetry_config_file" ]; then
  # Tiny inline YAML reader: handles top-level scalars only ("key: value" lines
  # outside of indented blocks). Sufficient for our flat config keys.
  __telemetry_read_yaml_scalar() {
    grep -E "^[[:space:]]*$1:" "$__telemetry_config_file" 2>/dev/null \
      | head -1 \
      | awk -F: '{
          $1=""; sub(/^[[:space:]]+/,""); sub(/[[:space:]]+$/,"");
          gsub(/^"|"$/, "");
          gsub(/^'\''|'\''$/, "");
          # join everything after the first colon and strip leading/trailing ws
          out=$0; gsub(/^[[:space:]]+/,"",out); gsub(/[[:space:]]+$/,"",out);
          print out
        }' \
      | sed 's/[[:space:]]*#.*$//' \
      | sed -E 's/^[[:space:]]+|[[:space:]]+$//g'
  }
  __cfg_enabled="$(__telemetry_read_yaml_scalar enabled)"
  __cfg_log_dir="$(__telemetry_read_yaml_scalar log_dir)"
  __cfg_retention="$(__telemetry_read_yaml_scalar retention_days)"
  __cfg_field_cap="$(__telemetry_read_yaml_scalar field_cap_chars)"
  __cfg_summary_cap="$(__telemetry_read_yaml_scalar summary_cap_chars)"
  __cfg_event_cap="$(__telemetry_read_yaml_scalar event_cap_bytes)"
  case "$__cfg_enabled" in
    true | yes | 1) [ -z "${CURSOR_TELEMETRY_ENABLED:-}" ] && TELEMETRY_ENABLED=1 ;;
    false | no | 0) [ -z "${CURSOR_TELEMETRY_ENABLED:-}" ] && TELEMETRY_ENABLED=0 ;;
  esac
  if [ -n "$__cfg_log_dir" ] && [ -z "${CURSOR_TELEMETRY_DIR:-}" ]; then
    case "$__cfg_log_dir" in
      "~/"*) TELEMETRY_LOG_DIR="$HOME/${__cfg_log_dir#\~/}" ;;
      "~") TELEMETRY_LOG_DIR="$HOME" ;;
      *) TELEMETRY_LOG_DIR="$__cfg_log_dir" ;;
    esac
  fi
  [ -n "$__cfg_retention" ] && [ -z "${CURSOR_TELEMETRY_RETENTION_DAYS:-}" ] && TELEMETRY_RETENTION_DAYS="$__cfg_retention"
  [ -n "$__cfg_field_cap" ] && [ -z "${CURSOR_TELEMETRY_FIELD_CAP_CHARS:-}" ] && TELEMETRY_FIELD_CAP_CHARS="$__cfg_field_cap"
  [ -n "$__cfg_summary_cap" ] && [ -z "${CURSOR_TELEMETRY_SUMMARY_CAP_CHARS:-}" ] && TELEMETRY_SUMMARY_CAP_CHARS="$__cfg_summary_cap"
  [ -n "$__cfg_event_cap" ] && [ -z "${CURSOR_TELEMETRY_EVENT_CAP_BYTES:-}" ] && TELEMETRY_EVENT_CAP_BYTES="$__cfg_event_cap"
fi

# Hard kill switch: env var to disable everything, e.g. for tests.
if [ "${CURSOR_TELEMETRY_DISABLED:-}" = "1" ]; then
  TELEMETRY_ENABLED=0
fi

# --- ensure dirs -------------------------------------------------------------
TELEMETRY_CACHE_DIR="${TMPDIR:-/tmp}/cursor-telemetry-cache"
TELEMETRY_SESSIONS_DIR="$TELEMETRY_LOG_DIR/sessions"
TELEMETRY_EVENTS_FILE="$TELEMETRY_LOG_DIR/events.jsonl"

telemetry_ensure_dirs() {
  [ "$TELEMETRY_ENABLED" = "1" ] || return 0
  mkdir -p "$TELEMETRY_LOG_DIR" "$TELEMETRY_SESSIONS_DIR" "$TELEMETRY_CACHE_DIR" 2>/dev/null || true
  chmod 700 "$TELEMETRY_CACHE_DIR" 2>/dev/null || true
  chmod 750 "$TELEMETRY_LOG_DIR" 2>/dev/null || true
}

# --- helpers -----------------------------------------------------------------
telemetry_iso8601_utc() {
  # macOS `date` does not honour %N — it just emits the literal `N`. Detect
  # GNU date by running the format and checking the result is purely digits;
  # otherwise fall through to python3, then to "000".
  local s ms
  s="$(date -u +%Y-%m-%dT%H:%M:%S 2>/dev/null)"
  ms="$(date -u +%3N 2>/dev/null)"
  case "$ms" in
    '' | *[!0-9]*) ms="" ;;
  esac
  if [ -z "$ms" ] && command -v python3 >/dev/null 2>&1; then
    ms="$(python3 -c 'import time; print(f"{int((time.time()%1)*1000):03d}")' 2>/dev/null)"
  fi
  [ -z "$ms" ] && ms="000"
  [ -z "$s" ] && s="$(date -u +%Y-%m-%dT%H:%M:%S 2>/dev/null)"
  printf '%s.%sZ' "$s" "$ms"
}

telemetry_now_ms() {
  local v
  v="$(date -u +%s%3N 2>/dev/null)"
  case "$v" in
    '' | *[!0-9]*) v="" ;;
  esac
  if [ -n "$v" ]; then
    printf '%s' "$v"
    return
  fi
  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import time; print(int(time.time()*1000))' 2>/dev/null
    return
  fi
  printf '%s000' "$(date -u +%s 2>/dev/null)"
}

telemetry_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen | tr '[:upper:]' '[:lower:]'
    return
  fi
  printf '%s-%s-%s' "$(date -u +%s)" "$RANDOM" "$RANDOM"
}

telemetry_short_basename() {
  # Reduce a path to a sanitized basename with one parent for context.
  local p="$1"
  [ -z "$p" ] && return 0
  local parent base
  base="$(basename "$p" 2>/dev/null)"
  parent="$(basename "$(dirname "$p" 2>/dev/null)" 2>/dev/null)"
  [ "$parent" = "." ] || [ "$parent" = "/" ] && parent=""
  if [ -n "$parent" ]; then
    printf '%s/%s' "$parent" "$base"
  else
    printf '%s' "$base"
  fi
}

telemetry_sanitize_path() {
  # Replace $HOME with ~ so logs don't leak the operator's username.
  local p="$1"
  [ -z "$p" ] && return 0
  case "$p" in
    "$HOME"/*) printf '~/%s' "${p#"$HOME"/}" ;;
    "$HOME") printf '~' ;;
    *) printf '%s' "$p" ;;
  esac
}

telemetry_truncate() {
  # Truncate a string to N chars, appending an ellipsis marker if cut.
  local s="$1" n="${2:-200}"
  [ -z "$s" ] && return 0
  if [ "${#s}" -le "$n" ]; then
    printf '%s' "$s"
    return
  fi
  printf '%s…[+%dch]' "${s:0:$n}" "$((${#s} - n))"
}

# --- redaction ---------------------------------------------------------------
# Single fast pass over the input text. Each `s/PATTERN/<REDACTED:TAG>/g`
# replacement is applied. Patterns are EREs.
#
# Order matters: structural patterns (private key blocks, JWT, URL userinfo)
# go before token-shaped patterns so they don't get partially eaten.
telemetry_redact() {
  local input
  if [ "$#" -gt 0 ]; then
    input="$1"
  else
    input="$(cat)"
  fi
  [ -z "$input" ] && return 0

  # Use sed -E (BSD/GNU compatible). Each substitution is conservative:
  # we never substitute beyond a recognizable shape so user content stays
  # readable.
  printf '%s' "$input" | sed -E \
    -e 's/-----BEGIN [A-Z ]*PRIVATE KEY-----[^-]*-----END [A-Z ]*PRIVATE KEY-----/<REDACTED:PRIVATE_KEY>/g' \
    -e 's/eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}/<REDACTED:JWT>/g' \
    -e 's#://([^/@[:space:]:]+):([^/@[:space:]]+)@#://<REDACTED:URL_USERINFO>@#g' \
    -e 's/[Bb]earer[[:space:]]+[A-Za-z0-9._~+/=-]{20,}/<REDACTED:BEARER>/g' \
    -e 's/AKIA[0-9A-Z]{16}/<REDACTED:AWS_ACCESS_KEY>/g' \
    -e 's/ASIA[0-9A-Z]{16}/<REDACTED:AWS_STS_KEY>/g' \
    -e 's/xox[bpoaeur]-[0-9A-Za-z-]{10,}/<REDACTED:SLACK_TOKEN>/g' \
    -e 's/sk-ant-[A-Za-z0-9_-]{20,}/<REDACTED:ANTHROPIC_API_KEY>/g' \
    -e 's/sk-[A-Za-z0-9]{20,}/<REDACTED:OPENAI_API_KEY>/g' \
    -e 's/sk_(live|test)_[A-Za-z0-9]{16,}/<REDACTED:STRIPE_KEY>/g' \
    -e 's/rk_(live|test)_[A-Za-z0-9]{16,}/<REDACTED:STRIPE_KEY>/g' \
    -e 's/gh[pousr]_[A-Za-z0-9]{20,}/<REDACTED:GITHUB_TOKEN>/g' \
    -e 's/github_pat_[A-Za-z0-9_]{20,}/<REDACTED:GITHUB_PAT>/g' \
    -e 's/glpat-[A-Za-z0-9_-]{20,}/<REDACTED:GITLAB_PAT>/g' \
    -e 's/npm_[A-Za-z0-9]{20,}/<REDACTED:NPM_TOKEN>/g' \
    -e 's/SK[a-fA-F0-9]{32}/<REDACTED:TWILIO_KEY>/g' \
    -e 's/AC[a-fA-F0-9]{32}/<REDACTED:TWILIO_SID>/g' \
    -e 's/AIza[0-9A-Za-z_-]{20,}/<REDACTED:GOOGLE_API_KEY>/g' \
    -e 's/ya29\.[A-Za-z0-9_-]{20,}/<REDACTED:GOOGLE_OAUTH>/g' \
    -e 's/(SECRET|TOKEN|PASSWORD|PASSWD|API_KEY|PRIVATE_KEY|ACCESS_KEY)[A-Z_0-9]*[[:space:]]*[:=][[:space:]]*[^[:space:]"]{4,}/\1=<REDACTED:ENV>/g'
}

# --- session / trace correlation --------------------------------------------
telemetry_session_cache_dir() {
  local sid="${1:-nosession}"
  printf '%s/%s' "$TELEMETRY_CACHE_DIR" "$sid"
}

telemetry_get_or_create_trace_id() {
  local sid="${1:-nosession}"
  local dir
  dir="$(telemetry_session_cache_dir "$sid")"
  mkdir -p "$dir" 2>/dev/null || return 0
  local f="$dir/trace_id"
  if [ -s "$f" ]; then
    cat "$f"
    return
  fi
  local t
  t="$(telemetry_uuid)"
  printf '%s' "$t" > "$f" 2>/dev/null || true
  chmod 600 "$f" 2>/dev/null || true
  printf '%s' "$t"
}

telemetry_register_pending_tool() {
  # Record a tool call's start time so postToolUse can compute duration_ms.
  # Uses tool_call_id when present; otherwise uses a per-session stack file.
  local sid="$1" call_id="$2" tool="$3" started_ms="$4"
  [ -z "$sid" ] && sid="nosession"
  local dir
  dir="$(telemetry_session_cache_dir "$sid")"
  mkdir -p "$dir/pending" 2>/dev/null || return 0
  local key="${call_id:-stack}"
  if [ "$key" = "stack" ]; then
    # Append to a stack; postToolUse pops the most recent matching tool.
    printf '%s|%s|%s\n' "$tool" "$started_ms" "$(telemetry_uuid)" >> "$dir/pending/stack" 2>/dev/null || true
    chmod 600 "$dir/pending/stack" 2>/dev/null || true
  else
    printf '%s|%s|%s\n' "$tool" "$started_ms" "$call_id" > "$dir/pending/$key" 2>/dev/null || true
    chmod 600 "$dir/pending/$key" 2>/dev/null || true
  fi
}

telemetry_pop_pending_tool() {
  # Returns a single line: tool|started_ms|call_id (best-effort).
  local sid="$1" call_id="$2" tool="$3"
  [ -z "$sid" ] && sid="nosession"
  local dir
  dir="$(telemetry_session_cache_dir "$sid")"
  local key="${call_id:-stack}"
  if [ "$key" = "stack" ]; then
    local stack="$dir/pending/stack"
    [ -s "$stack" ] || return 0
    # Pop matching tool entry from the bottom (most recent).
    local matched=""
    if [ -n "$tool" ]; then
      matched="$(grep -n "^${tool}|" "$stack" 2>/dev/null | tail -1)"
    fi
    if [ -z "$matched" ]; then
      matched="$(tail -1 "$stack" 2>/dev/null)"
      [ -z "$matched" ] && return 0
      printf '%s' "$matched"
      sed -i.bak -e '$d' "$stack" 2>/dev/null || true
      rm -f "$stack.bak" 2>/dev/null || true
    else
      local lineno="${matched%%:*}"
      local payload="${matched#*:}"
      printf '%s' "$payload"
      sed -i.bak -e "${lineno}d" "$stack" 2>/dev/null || true
      rm -f "$stack.bak" 2>/dev/null || true
    fi
  else
    local f="$dir/pending/$key"
    [ -s "$f" ] || return 0
    cat "$f"
    rm -f "$f" 2>/dev/null || true
  fi
}

# --- daily rotation + retention ---------------------------------------------
telemetry_rotate_if_needed() {
  [ "$TELEMETRY_ENABLED" = "1" ] || return 0
  telemetry_ensure_dirs
  [ -f "$TELEMETRY_EVENTS_FILE" ] || return 0

  local today rotation_marker
  today="$(date -u +%Y-%m-%d)"
  rotation_marker="$TELEMETRY_LOG_DIR/.last-rotation"

  local last=""
  [ -s "$rotation_marker" ] && last="$(cat "$rotation_marker" 2>/dev/null)"
  if [ "$last" = "$today" ]; then
    return 0
  fi

  # Only rotate if the events file has yesterday's content. Move it to a dated
  # archive name and start fresh.
  local file_day
  if stat -f '%Sm' -t '%Y-%m-%d' "$TELEMETRY_EVENTS_FILE" >/dev/null 2>&1; then
    file_day="$(stat -f '%Sm' -t '%Y-%m-%d' "$TELEMETRY_EVENTS_FILE" 2>/dev/null)"
  else
    file_day="$(stat -c '%y' "$TELEMETRY_EVENTS_FILE" 2>/dev/null | awk '{print $1}')"
  fi
  if [ -n "$file_day" ] && [ "$file_day" != "$today" ]; then
    mv "$TELEMETRY_EVENTS_FILE" "$TELEMETRY_LOG_DIR/events-$file_day.jsonl" 2>/dev/null || true
    : > "$TELEMETRY_EVENTS_FILE" 2>/dev/null || true
    chmod 640 "$TELEMETRY_EVENTS_FILE" 2>/dev/null || true
  fi

  printf '%s' "$today" > "$rotation_marker" 2>/dev/null || true
  chmod 640 "$rotation_marker" 2>/dev/null || true

  telemetry_prune_old_logs
}

telemetry_prune_old_logs() {
  [ "$TELEMETRY_ENABLED" = "1" ] || return 0
  [ -d "$TELEMETRY_LOG_DIR" ] || return 0
  local days="$TELEMETRY_RETENTION_DAYS"
  case "$days" in
    '' | *[!0-9]*) return 0 ;;
  esac
  # Use POSIX find with -mtime; restrict to our naming pattern.
  find "$TELEMETRY_LOG_DIR" -maxdepth 1 -type f -name 'events-*.jsonl' -mtime +"$days" -print0 2>/dev/null \
    | xargs -0 rm -f 2>/dev/null || true
  find "$TELEMETRY_SESSIONS_DIR" -maxdepth 1 -type f -name '*.json' -mtime +"$days" -print0 2>/dev/null \
    | xargs -0 rm -f 2>/dev/null || true
}

# --- event writer ------------------------------------------------------------
# Args: event_type session_id [json_extra]
# json_extra is a JSON object string with additional fields; merged into the event.
telemetry_emit_event() {
  [ "$TELEMETRY_ENABLED" = "1" ] || return 0
  command -v jq >/dev/null 2>&1 || return 0
  telemetry_ensure_dirs

  local event_type="$1"
  local session_id="${2:-nosession}"
  local extra_json="${3:-{\}}"
  [ -z "$event_type" ] && return 0

  local ts trace_id event_id
  ts="$(telemetry_iso8601_utc)"
  trace_id="$(telemetry_get_or_create_trace_id "$session_id")"
  event_id="$(telemetry_uuid)"

  # Compose the base event. jq merges `extra_json` so callers can add domain
  # fields (tool_name, tool_call_id, duration_ms, outcome, error_class, etc.).
  local line
  line="$(jq -nc \
    --arg schema_version 1 \
    --arg event_id "$event_id" \
    --arg ts "$ts" \
    --arg event_type "$event_type" \
    --arg session_id "$session_id" \
    --arg trace_id "$trace_id" \
    --arg pack "$TELEMETRY_PACK_ID" \
    --argjson extra "$extra_json" \
    '{
      schema_version: ($schema_version|tonumber),
      event_id: $event_id,
      ts: $ts,
      event_type: $event_type,
      session_id: $session_id,
      trace_id: $trace_id,
      hooks_pack: $pack
    } + $extra' 2>/dev/null)"

  if [ -z "$line" ]; then
    return 0
  fi

  # Enforce per-event byte cap. Replace `summary` with a truncated note when
  # over budget; keep correlation fields intact.
  local size
  size="${#line}"
  if [ "$size" -gt "$TELEMETRY_EVENT_CAP_BYTES" ]; then
    line="$(printf '%s' "$line" | jq -c \
      --arg note "[event truncated: ${size}B > ${TELEMETRY_EVENT_CAP_BYTES}B cap]" \
      '. as $e | {
        schema_version: $e.schema_version,
        event_id: $e.event_id,
        ts: $e.ts,
        event_type: $e.event_type,
        session_id: $e.session_id,
        trace_id: $e.trace_id,
        hooks_pack: $e.hooks_pack,
        outcome: ($e.outcome // null),
        truncated: true,
        summary: $note
      }' 2>/dev/null)"
  fi

  printf '%s\n' "$line" >> "$TELEMETRY_EVENTS_FILE" 2>/dev/null || true
  chmod 640 "$TELEMETRY_EVENTS_FILE" 2>/dev/null || true
}

# --- input parsers -----------------------------------------------------------
telemetry_extract_session_id() {
  # Accepts the hook input JSON on stdin; prints the session_id (or empty).
  jq -r '.session_id // .sessionId // .conversation_id // empty' 2>/dev/null
}

telemetry_extract_workspace_root() {
  jq -r '.workspace_root // .workspaceRoot // .project_root // .projectRoot // .cwd // empty' 2>/dev/null
}

telemetry_extract_tool_call_id() {
  jq -r '.tool_call_id // .toolCallId // .invocation_id // .invocationId // empty' 2>/dev/null
}

telemetry_extract_tool_name() {
  jq -r '.tool_name // .toolName // empty' 2>/dev/null
}

# --- emit `permission: allow` for preToolUse-style hooks ---------------------
telemetry_emit_allow() {
  if command -v jq >/dev/null 2>&1; then
    jq -nc '{permission:"allow"}'
  else
    printf '{"permission":"allow"}\n'
  fi
}
