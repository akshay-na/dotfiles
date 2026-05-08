#!/usr/bin/env bash
# task-model-auto-guard.sh
#
# preToolUse hook (matcher: Task|Subagent).
# Enforces model:auto policy for Task/Subagent dispatch and writes audit events.

set -uo pipefail

AUDIT_DIR="$HOME/ai-brain/org/global/orchestration"
AUDIT_FILE="$AUDIT_DIR/cursor-task-model-fallback-audit.jsonl"
AUDIT_MAX_BYTES=1048576
AUDIT_MAX_FILES=5

rotate_audit_logs() {
  [ -f "$AUDIT_FILE" ] || return 0

  local size
  size=$(wc -c < "$AUDIT_FILE" 2>/dev/null || echo 0)
  [ "${size:-0}" -gt "$AUDIT_MAX_BYTES" ] || return 0

  local ts rotated
  ts="$(date -u +%Y%m%dT%H%M%SZ)"
  rotated="$AUDIT_FILE.$ts"

  mv "$AUDIT_FILE" "$rotated" 2>/dev/null || return 0

  ls -1t "$AUDIT_FILE".* 2>/dev/null | awk -v keep="$AUDIT_MAX_FILES" 'NR>keep {print}' | while read -r old; do
    rm -f "$old" 2>/dev/null || true
  done
}

log_event() {
  local decision="$1"
  local reason="$2"
  local session_id tool_name model

  if ! command -v jq >/dev/null 2>&1; then
    return 0
  fi

  session_id="$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .conversation_id // "unknown"')"
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // "unknown"')"
  model="$(printf '%s' "$input" | jq -r '.tool_input.model // ""')"

  mkdir -p "$AUDIT_DIR" 2>/dev/null || true
  chmod 700 "$AUDIT_DIR" 2>/dev/null || true
  rotate_audit_logs

  jq -cn     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)"     --arg hook "task-model-auto-guard"     --arg decision "$decision"     --arg reason "$reason"     --arg session_id "$session_id"     --arg tool_name "$tool_name"     --arg model "$model"     '{timestamp:$ts, hook:$hook, decision:$decision, reason:$reason, session_id:$session_id, tool_name:$tool_name, model:$model}'     >> "$AUDIT_FILE" 2>/dev/null || true
}

if ! command -v jq >/dev/null 2>&1; then
  printf '{"permission":"allow"}
'
  exit 0
fi

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
if [ "$tool" != "Task" ] && [ "$tool" != "Subagent" ]; then
  printf '{"permission":"allow"}
'
  exit 0
fi

model="$(printf '%s' "$input" | jq -r '.tool_input.model // empty')"

# Empty model inherits runtime default; explicit model must be "auto".
if [ -n "$model" ] && [ "$model" != "auto" ]; then
  log_event "deny" "explicit_model_not_auto"
  jq -n --arg t "$tool" --arg m "$model" --arg msg "task-model-auto-guard: $tool denied. Explicit model must be model:auto (got: $m). Re-dispatch immediately with model:auto."     '{permission:"deny",agent_message:$msg}'
  exit 0
fi

if [ -z "$model" ]; then
  log_event "allow" "model_unspecified_runtime_default"
else
  log_event "allow" "model_auto"
fi
printf '{"permission":"allow"}
'
exit 0
