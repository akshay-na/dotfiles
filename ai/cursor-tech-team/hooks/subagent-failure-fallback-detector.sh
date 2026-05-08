#!/usr/bin/env bash
# subagent-failure-fallback-detector.sh
#
# postToolUse hook (matcher: Subagent).
# Detects Subagent failures (quota/model unavailable/interrupt), classifies cause,
# and emits immediate retry guidance with model:auto.

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

  session_id="$(printf '%s' "$input" | jq -r '.session_id // .sessionId // .conversation_id // "unknown"')"
  tool_name="$(printf '%s' "$input" | jq -r '.tool_name // "unknown"')"
  model="$(printf '%s' "$input" | jq -r '.tool_input.model // ""')"

  mkdir -p "$AUDIT_DIR" 2>/dev/null || true
  chmod 700 "$AUDIT_DIR" 2>/dev/null || true
  rotate_audit_logs

  jq -cn     --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)"     --arg hook "subagent-failure-fallback-detector"     --arg decision "$decision"     --arg reason "$reason"     --arg session_id "$session_id"     --arg tool_name "$tool_name"     --arg model "$model"     '{timestamp:$ts, hook:$hook, decision:$decision, reason:$reason, session_id:$session_id, tool_name:$tool_name, model:$model}'     >> "$AUDIT_FILE" 2>/dev/null || true
}

classify_failure() {
  local flat
  flat="$(printf '%s' "$input" | jq -r '.. | strings' | tr '[:upper:]' '[:lower:]')"

  if printf '%s' "$flat" | rg -q 'interrupted by the user|manually backgrounded by the user|cancelled by user|aborted by user'; then
    printf 'user_interrupt'
    return
  fi

  if printf '%s' "$flat" | rg -q 'out of usage|increase limits for faster responses|quota|rate limit|credits|insufficient quota'; then
    printf 'quota'
    return
  fi

  if printf '%s' "$flat" | rg -q 'model unavailable|model is unavailable|model not available|unsupported model|invalid model|no such model'; then
    printf 'model_unavailable'
    return
  fi

  if printf '%s' "$flat" | rg -q 'error|failed|exception|timeout|timed out|denied'; then
    printf 'other_failure'
    return
  fi

  printf 'no_failure'
}

if ! command -v jq >/dev/null 2>&1; then
  printf '{"permission":"allow"}
'
  exit 0
fi

input="$(cat)"
tool="$(printf '%s' "$input" | jq -r '.tool_name // empty')"
if [ "$tool" != "Subagent" ]; then
  printf '{"permission":"allow"}
'
  exit 0
fi

cause="$(classify_failure)"

if [ "$cause" = "no_failure" ]; then
  log_event "allow" "subagent_no_failure_signal"
  printf '{"permission":"allow"}
'
  exit 0
fi

log_event "fallback_signal" "$cause"

if [ "$cause" = "user_interrupt" ]; then
  jq -n --arg c "$cause" --arg m "subagent-failure-fallback-detector: classified=$cause. Last Subagent run was user-stopped. No auto-retry attempted."     '{permission:"allow",agent_message:$m,hook_classification:$c}'
  exit 0
fi

jq -n --arg c "$cause" --arg m "subagent-failure-fallback-detector: classified=$cause. Retry immediately with same Subagent payload using model:auto. Hook can signal retry, but cannot directly re-run tool call."   '{permission:"allow",agent_message:$m,hook_classification:$c,retry_recommended:true}'
exit 0
