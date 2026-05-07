#!/usr/bin/env bash
# subagent-task-antidup-preflight.sh — Task preflight (Anti-Dup contract)
#
# Reads hook JSON stdin. When policy enabled, rejects dispatches carrying
# >inline_blob_soft_fail_bytes contiguous text without REF token wrappers.
#
# Policy: ~/.cursor/configurations/orchestration-policies/anti-dup.yml (stow)
set -uo pipefail
SELF="${BASH_SOURCE[0]}"
SELF_REAL="$(realpath -q "$SELF" 2>/dev/null || printf '%s' "$SELF")"
CURSOR_DIR="$(dirname "$(dirname "$SELF_REAL")")"
POLICY="$CURSOR_DIR/configurations/orchestration-policies/anti-dup.yml"
input="$(cat)"

enabled=""
if [ -r "$POLICY" ]; then
  enabled="$(grep -E '^enabled:' "$POLICY" | head -1 | awk '{print $2}')"
fi
case "$enabled" in
  true|yes|1) ;;
  *)
    if command -v jq >/dev/null 2>&1; then
      jq -n '{permission:"allow"}'
    else
      printf '{"permission":"allow"}\n'
    fi
    exit 0
    ;;
esac

thresh=1024
if [ -r "$POLICY" ]; then
  t="$(grep -E '^[[:space:]]*inline_blob_soft_fail_bytes:' "$POLICY" | head -1 | awk '{print $2}')"
  [ -n "$t" ] && thresh="$t"
fi

if ! command -v jq >/dev/null 2>&1; then
  printf '{"permission":"allow"}\n'
  exit 0
fi

msg="$(printf '%s' "$input" \
  | jq -r '.. | strings' 2>/dev/null \
  | awk -v th="$thresh" '
      BEGIN { max=0; bad=0 }
      {
        n=split($0, parts, /[[:space:]]+/)
        for (i=1; i<=n; i++) {
          token=parts[i]
          len=length(token)
          if (len > th && index(token, "<REF:") == 0) {
            bad=1
            if (len > max) max=len
          }
        }
      }
      END {
        if (bad == 1) {
          printf "inline_blob_without_REF max_len=%d", max
        }
      }'
)"

if [ -n "$msg" ]; then
  jq -n --arg m "anti-dup: $msg retry w/ <REF:path#sha256:HASH#size:BYTES> chunking per templates/subagent-response.yml.tmpl" \
    '{permission:"deny",agent_message:$m}' 2>/dev/null || printf '{"permission":"deny","agent_message":"%s"}\n' "$msg"
  exit 0
fi

jq -n '{permission:"allow"}' 2>/dev/null || printf '{"permission":"allow"}\n'
exit 0
