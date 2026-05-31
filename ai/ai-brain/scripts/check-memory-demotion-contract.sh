#!/usr/bin/env bash
# Assert memory-demotion contract_version matches tech-team lifecycle stub.
# When ~/ai-brain/org/global/config/memory-demotion.yml exists, diff against dotfiles source (cro-011).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=brain-lib.sh
source "$SCRIPT_DIR/brain-lib.sh"

POLICY="$POLICY_SOURCE"
RUNTIME="${HOME:?}/ai-brain/org/global/config/memory-demotion.yml"

if ! DOTFILES_ROOT="$(resolve_dotfiles_root)"; then
  echo "check-memory-demotion-contract: set DOTFILES_DIR to dotfiles repo root" >&2
  exit 1
fi

STUB="$DOTFILES_ROOT/ai/cursor/tech-team/configurations/orchestration-policies/memory-lifecycle.yml"
if [[ ! -f "$STUB" ]]; then
  STUB="$DOTFILES_ROOT/ai/opencode/tech-team/configurations/orchestration-policies/memory-lifecycle.yml"
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "check-memory-demotion-contract: python3 required" >&2
  exit 1
fi
python3 - "$POLICY" "$STUB" "$RUNTIME" <<'PY'
import sys, re
from pathlib import Path

def cv(path):
    text = Path(path).read_text()
    m = re.search(r"^contract_version:\s*(\d+)", text, re.M)
    if not m:
        sys.exit(f"missing contract_version in {path}")
    return int(m.group(1))

p, s, runtime = sys.argv[1], sys.argv[2], sys.argv[3]
cp, cs = cv(p), cv(s)
if cp != cs:
    sys.exit(f"contract_version mismatch: policy={cp} stub={cs}")
print(f"ok contract_version={cp} (dotfiles source vs tech-pack stub)")

rp = Path(runtime)
if rp.is_file():
    cr = cv(rp)
    if cr != cp:
        sys.exit(f"contract_version mismatch: source={cp} runtime={cr}")
    if rp.read_text() != Path(p).read_text():
        sys.exit(
            "runtime memory-demotion.yml content differs from dotfiles source; "
            "run ~/ai-brain/scripts/materialize-brain-policy.sh --apply"
        )
    kind = "symlink" if rp.is_symlink() else "copy"
    print(f"ok runtime policy matches source ({kind}, contract_version={cr})")
PY
