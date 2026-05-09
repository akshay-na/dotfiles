#!/usr/bin/env bash
# P7: agent registry YAML must contain only `name` and `description` (Gemini CLI).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
fi
AGENTS="$ROOT/ai/gemini-content-team/agents"

fail() { echo "check-gemini-agent-frontmatter: $*" >&2; exit 1; }

shopt -s nullglob
for f in "$AGENTS"/*.md "$AGENTS"/internal/*.md; do
  [[ -f "$f" ]] || continue
  awk 'BEGIN{m=0} /^---$/{if(m==0){m=1;next}else if(m==1){exit}} m==1{print}' "$f" | while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    key="${line%%:*}"
    key="$(echo "$key" | tr -d '[:space:]')"
    [[ -z "$key" ]] && continue
    case "$key" in
      name|description) ;;
      *) fail "forbidden frontmatter key '$key' in $f" ;;
    esac
  done
done

echo "check-gemini-agent-frontmatter: OK"
