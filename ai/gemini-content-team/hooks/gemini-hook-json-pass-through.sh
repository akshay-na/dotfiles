#!/usr/bin/env bash
# Gemini CLI hook adapter: strict JSON on stdout only (stderr may log).
# Reads hook payload from stdin; emits compact JSON. Invalid stdin → "{}".
set -euo pipefail
python3 -c 'import json,sys
raw=sys.stdin.read()
try:
    obj=json.loads(raw) if raw.strip() else {}
except json.JSONDecodeError:
    obj={}
json.dump(obj, sys.stdout, separators=(",", ":"))'
