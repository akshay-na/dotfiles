#!/usr/bin/env bash
# subagent-protocol-inject.sh
#
# preToolUse hook (matcher: Task).
# Injects the subagent-response-protocol contract block at the top of the
# subagent's prompt, along with a freshly-minted per-session `_marker` UUID
# that the postToolUse validator uses to authenticate the child response.
#
# Also caches session metadata (rule-mtime + marker) under $TMPDIR so the
# validate hook can detect rule-version drift mid-session (R14, D19).
#
# Fail-open: on any error (jq missing, template missing, non-Task tool), the
# hook exits 0 without modifying anything. NEVER breaks the agent flow.
#
# POSIX-compatible. Uses `uuidgen` with `python3` fallback.

set -uo pipefail

# --- resolve key paths (symlink-safe) ---------------------------------------
SELF="${BASH_SOURCE[0]}"
SELF_REAL="$(realpath -q "$SELF" 2>/dev/null || printf '%s' "$SELF")"
CURSOR_DIR="$(dirname "$(dirname "$SELF_REAL")")"
TEMPLATE="$CURSOR_DIR/templates/subagent-contract-block.md"
RULE_FILE="$CURSOR_DIR/rules/subagent-response-protocol.mdc"

# --- tooling sanity ---------------------------------------------------------
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi
if [ ! -r "$TEMPLATE" ]; then
  exit 0
fi

# --- read hook input --------------------------------------------------------
input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
case "$tool" in
  Task) ;;
  *) exit 0 ;;
esac

session_id="$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .conversation_id // empty')"
[ -z "$session_id" ] && session_id="nosession"

# --- session cache dir ------------------------------------------------------
cache_dir="${TMPDIR:-/tmp}/cursor-subagent-protocol"
mkdir -p "$cache_dir" 2>/dev/null || true
# restrict access — marker is a session-scoped nonce (D8)
chmod 700 "$cache_dir" 2>/dev/null || true

marker_file="$cache_dir/marker-$session_id"
mtime_file="$cache_dir/rule-mtime-$session_id"
warn_flag="$cache_dir/drift-warned-$session_id"

# --- generate or reuse this session's marker (single marker per session) ---
if [ -s "$marker_file" ]; then
  marker="$(cat "$marker_file")"
else
  if command -v uuidgen >/dev/null 2>&1; then
    marker="$(uuidgen | tr '[:upper:]' '[:lower:]')"
  elif command -v python3 >/dev/null 2>&1; then
    marker="$(python3 -c 'import uuid;print(uuid.uuid4())')"
  else
    # last-resort fallback — timestamp + random, still unique enough per-session
    marker="sess-$(date +%s)-$RANDOM-$RANDOM"
  fi
  printf '%s' "$marker" > "$marker_file"
  chmod 600 "$marker_file" 2>/dev/null || true
fi

# --- rule-version mtime cache (R14, D19) ------------------------------------
# Cache rule mtime at session start. Warn once if rule file mtime changes
# mid-session; do not switch behavior (hold the cached version).
current_mtime=""
if [ -r "$RULE_FILE" ]; then
  current_mtime="$(stat -f '%m' "$RULE_FILE" 2>/dev/null || stat -c '%Y' "$RULE_FILE" 2>/dev/null || echo "")"
fi
drift_note=""
if [ -n "$current_mtime" ]; then
  if [ -s "$mtime_file" ]; then
    cached="$(cat "$mtime_file")"
    if [ "$cached" != "$current_mtime" ] && [ ! -f "$warn_flag" ]; then
      drift_note="(protocol rule mtime changed mid-session; holding cached version; session restart recommended)"
      : > "$warn_flag"
    fi
  else
    printf '%s' "$current_mtime" > "$mtime_file"
  fi
fi

# --- render the contract block with marker substituted ---------------------
contract="$(sed "s|{{MARKER}}|$marker|g" "$TEMPLATE")"

# --- emit agent_message so Cursor surfaces the contract to the subagent ---
# The message is structured as a clearly delimited injection block so the
# subagent can recognize and follow it.
msg="--- PARENT-INJECTED CONTRACT (subagent-response-protocol) ---
$contract
${drift_note:+[hook: $drift_note]}
--- END CONTRACT ---"

# Emit both agent_message (visible to agent) and permission=allow.
# Some Cursor versions also honor additionalContext / promptPrepend; include
# them defensively — unknown keys are ignored.
jq -n \
  --arg msg "$msg" \
  --arg marker "$marker" \
  '{permission:"allow", agent_message:$msg, additionalContext:$msg, promptPrepend:$msg, metadata:{subagent_protocol_marker:$marker}}'

exit 0
