#!/usr/bin/env bash
# Copy canonical memory-demotion.yml into ~/ai-brain (replaces stow symlink when --apply).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="$ROOT/org/global/config/memory-demotion.yml"
DEST="${HOME:?}/ai-brain/org/global/config/memory-demotion.yml"
APPLY=0

usage() {
  echo "usage: $(basename "$0") [--dry-run|--apply]" >&2
  echo "  --dry-run  show planned copy (default)" >&2
  echo "  --apply    write file; replace symlink if present" >&2
}

for arg in "${@:-}"; do
  case "$arg" in
    --dry-run) APPLY=0 ;;
    --apply) APPLY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

if [ ! -f "$SOURCE" ]; then
  echo "materialize-brain-policy: missing source: $SOURCE" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "materialize-brain-policy: python3 required" >&2
  exit 1
fi

contract_version() {
  python3 - "$1" <<'PY'
import re, sys
from pathlib import Path
text = Path(sys.argv[1]).read_text()
m = re.search(r"^contract_version:\s*(\d+)", text, re.M)
if not m:
    sys.exit(f"missing contract_version in {sys.argv[1]}")
print(m.group(1))
PY
}

SRC_CV="$(contract_version "$SOURCE")"

describe_dest() {
  if [ ! -e "$DEST" ]; then
    echo "dest: (missing) would create"
    return
  fi
  if [ -L "$DEST" ]; then
    echo "dest: symlink -> $(readlink "$DEST") (would replace with copy on --apply)"
  elif [ -f "$DEST" ]; then
    echo "dest: regular file"
  else
    echo "dest: exists but not a regular file or symlink" >&2
    exit 1
  fi
}

parity_check() {
  python3 - "$SOURCE" "$DEST" <<'PY'
import sys
from pathlib import Path

def cv(path):
    import re
    text = Path(path).read_text()
    m = re.search(r"^contract_version:\s*(\d+)", text, re.M)
    if not m:
        sys.exit(f"missing contract_version in {path}")
    return int(m.group(1))

src, dest = Path(sys.argv[1]), Path(sys.argv[2])
if not dest.is_file():
    sys.exit(0)
cs, cd = cv(src), cv(dest)
if cs != cd:
    sys.exit(f"contract_version mismatch: source={cs} dest={cd}")
if src.read_text() != dest.read_text():
    sys.exit("content differs from dotfiles source")
print(f"ok parity contract_version={cs}")
PY
}

echo "materialize-brain-policy: source=$SOURCE (contract_version=$SRC_CV)"
echo "materialize-brain-policy: dest=$DEST"
describe_dest

if [ -e "$DEST" ] && [ -f "$DEST" ]; then
  DEST_CV="$(contract_version "$DEST")"
  echo "materialize-brain-policy: dest contract_version=$DEST_CV"
  if [ "$SRC_CV" != "$DEST_CV" ]; then
    echo "materialize-brain-policy: contract_version drift (source=$SRC_CV dest=$DEST_CV)" >&2
    if [ "$APPLY" -eq 0 ]; then
      echo "materialize-brain-policy: run with --apply to refresh copy" >&2
    fi
  elif cmp -s "$SOURCE" "$DEST"; then
    echo "materialize-brain-policy: dest already matches source"
  elif [ "$APPLY" -eq 0 ]; then
    echo "materialize-brain-policy: content differs; run with --apply to refresh copy" >&2
  fi
fi

if [ "$APPLY" -eq 0 ]; then
  echo "materialize-brain-policy: dry-run (no changes)"
  exit 0
fi

mkdir -p "$(dirname "$DEST")"
if [ -L "$DEST" ]; then
  rm "$DEST"
elif [ -e "$DEST" ] && [ ! -f "$DEST" ]; then
  echo "materialize-brain-policy: refusing to overwrite non-file dest: $DEST" >&2
  exit 1
fi

cp "$SOURCE" "$DEST"
parity_check
echo "materialize-brain-policy: applied copy to $DEST"
