#!/usr/bin/env bash
# P2c / P7: assert Gemini hook emits strict JSON on stdout (OR-02).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel 2>/dev/null)"
if [[ -z "$ROOT" ]]; then
  ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
fi
HOOK="$ROOT/ai/gemini-content-team/hooks/gemini-hook-json-pass-through.sh"

if [[ ! -x "$HOOK" ]]; then
  chmod +x "$HOOK"
fi

fail() { echo "verify-gemini-hooks: $*" >&2; exit 1; }

tmp="$(mktemp)"
cleanup() { rm -f "$tmp"; }
trap cleanup EXIT

# Valid JSON pass-through
out="$(printf '%s' '{"ok":true,"n":1}' | "$HOOK")"
printf '%s' "$out" >"$tmp"
python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$tmp" || fail "stdout not valid JSON"
[[ "$out" != *$'\n'* ]] || fail "stdout must be single-line JSON (no embedded newlines)"
[[ "$out" == '{"ok":true,"n":1}' ]] || fail "unexpected payload: $out"

# Invalid stdin → {}
out2="$(printf '%s' 'not-json' | "$HOOK")"
[[ "$out2" == '{}' ]] || fail "invalid stdin should yield {}, got: $out2"

echo "verify-gemini-hooks: OK"
