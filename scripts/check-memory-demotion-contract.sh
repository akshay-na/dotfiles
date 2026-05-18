#!/usr/bin/env bash
# Assert memory-demotion contract_version matches tech-team lifecycle stub.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
POLICY="$ROOT/ai/ai-brain/org/global/config/memory-demotion.yml"
STUB="$ROOT/ai/cursor/tech-team/configurations/orchestration-policies/memory-lifecycle.yml"
if ! command -v python3 >/dev/null 2>&1; then
  echo "check-memory-demotion-contract: python3 required" >&2
  exit 1
fi
python3 - "$POLICY" "$STUB" <<'PY'
import sys, re
from pathlib import Path

def cv(path):
    text = Path(path).read_text()
    m = re.search(r"^contract_version:\s*(\d+)", text, re.M)
    if not m:
        sys.exit(f"missing contract_version in {path}")
    return int(m.group(1))

p, s = sys.argv[1], sys.argv[2]
cp, cs = cv(p), cv(s)
if cp != cs:
    sys.exit(f"contract_version mismatch: policy={cp} stub={cs}")
print(f"ok contract_version={cp}")
PY
