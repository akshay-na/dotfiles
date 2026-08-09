#!/usr/bin/env bash
# brain-read-policy-advisory.sh
#
# preToolUse hook (matcher: Read|Grep). Surfaces read_policy violations on
# ai-brain paths: demoted/quarantine indexes, exclude_paths, lifecycle_state.
#
# Default: advisory (stderr warning + allow). Blocks when enforce env set.
#
# Env:
#   CURSOR_BRAIN_READ_POLICY_DISABLED=1     — kill switch (fail-open allow)
#   CURSOR_BRAIN_READ_POLICY_ENFORCE=1      — deny Read/Grep on policy violations
#   CURSOR_BRAIN_READ_POLICY_ENTRYPOINT_ENFORCE=1 — deny for entrypoint agents only
#
# G2 note: until brain_audit gate flips (verification-gates.yml), org-wide
# mechanical enforce stays deferred — advisory default. See brain-demotion.md.
#
# Manual smoke:
#   echo '{"tool_name":"Read","tool_input":{"path":"~/ai-brain/projects/dotfiles/quarantine/x.md"}}' \
#     | ./ai/cursor/tech-team/hooks/brain-read-policy-advisory.sh
#
# shellcheck disable=SC1091

set -u

__self="${BASH_SOURCE[0]}"
__real="$(realpath -q "$__self" 2>/dev/null || printf '%s' "$__self")"
__hooks_dir="$(dirname "$__real")"
# shellcheck source=./brain-common.sh
. "$__hooks_dir/brain-common.sh" 2>/dev/null || exit 0

brain_install_fail_open_trap

emit_allow() {
  if command -v jq >/dev/null 2>&1; then
    jq -nc '{permission:"allow"}'
  else
    printf '{"permission":"allow"}\n'
  fi
  exit 0
}

emit_deny() {
  local msg="$1"
  if command -v jq >/dev/null 2>&1; then
    jq -nc --arg m "$msg" '{permission:"deny",agent_message:$m}'
  else
    printf '{"permission":"deny","agent_message":"%s"}\n' "$msg"
  fi
  exit 0
}

if [ "${CURSOR_BRAIN_READ_POLICY_DISABLED:-}" = "1" ]; then
  emit_allow
fi

input="$(cat 2>/dev/null || true)"
[ -z "$input" ] && emit_allow

if ! command -v jq >/dev/null 2>&1; then
  emit_allow
fi

tool_name="$(printf '%s' "$input" | jq -r '.tool_name // empty' 2>/dev/null)"
case "$tool_name" in
  Read | Grep) ;;
  *) emit_allow ;;
esac

target_path="$(printf '%s' "$input" | jq -r '
  .tool_input.path //
  .tool_input.file_path //
  .tool_input.target_file //
  .tool_input.filePath //
  .tool_input.filename //
  empty
' 2>/dev/null)"

agent_id="$(printf '%s' "$input" | jq -r '
  .agent_id //
  .agent //
  .actor.agent_id //
  .subagent_type //
  empty
' 2>/dev/null)"

enforce_all=false
enforce_entrypoint=false
if [ "${CURSOR_BRAIN_READ_POLICY_ENFORCE:-}" = "1" ]; then
  enforce_all=true
fi
if [ "${CURSOR_BRAIN_READ_POLICY_ENTRYPOINT_ENFORCE:-}" = "1" ]; then
  enforce_entrypoint=true
fi

should_block=false
if [ "$enforce_all" = true ]; then
  should_block=true
elif [ "$enforce_entrypoint" = true ]; then
  case "$agent_id" in
    cto | tech-lead | code-reviewer | bug-bot | cco | cio | content-lead | trading-lead | n8n-builder | remotion-builder | atlassian-pm)
      should_block=true
      ;;
  esac
fi

# Grep without scoped path — advisory only (prefer kb-query L1).
if [ "$tool_name" = "Grep" ] && [ -z "$target_path" ]; then
  printf 'brain-read-policy: advisory — Grep without path may bypass read_policy; prefer brain-memory-kb kb-query L1\n' >&2
  if [ "$should_block" = true ]; then
    emit_deny "brain-read-policy: Grep without path bypasses read_policy — use kb-query L1 or set an explicit path under allowed nodes"
  fi
  emit_allow
fi

[ -z "$target_path" ] && emit_allow

# Expand ~ in path.
case "$target_path" in
  "~/"*) target_path="$HOME/${target_path#\~/}" ;;
  "~") target_path="$HOME" ;;
esac

# Resolve relative paths against workspace root when present.
workspace_root="$(printf '%s' "$input" | jq -r '
  .workspace_root //
  .workspaceRoot //
  .project_root //
  .projectRoot //
  .cwd //
  empty
' 2>/dev/null)"
case "$target_path" in
  /*) ;;
  *)
    if [ -n "$workspace_root" ]; then
      target_path="$workspace_root/$target_path"
    fi
    ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
  emit_allow
fi

check_result="$(python3 - "$target_path" "$BRAIN_ROOT" "$BRAIN_CONTRACT_POLICY" <<'PY'
import json
import re
import sys
from pathlib import Path

target = Path(sys.argv[1]).expanduser()
try:
    target = target.resolve()
except OSError:
    target = target.expanduser()

brain_root = Path(sys.argv[2]).expanduser().resolve()
policy_path = sys.argv[3] if len(sys.argv) > 3 and sys.argv[3] else ""

EXCLUDE_SEGMENTS = ("quarantine", "archive")
EXCLUDE_STATES = {"demoted", "quarantined", "invalidated"}


def load_read_policy(path: Path):
    exclude_segments = list(EXCLUDE_SEGMENTS)
    exclude_states = set(EXCLUDE_STATES)
    if not path or not Path(path).is_file():
        return exclude_segments, exclude_states
    text = Path(path).read_text(encoding="utf-8")
    in_rp = in_paths = in_states = False
    for line in text.splitlines():
        if re.match(r"^read_policy:\s*$", line):
            in_rp = True
            continue
        if not in_rp:
            continue
        if re.match(r"^\S", line) and not line.startswith(" "):
            break
        if re.match(r"^\s{2}exclude_paths:\s*$", line):
            in_paths = True
            in_states = False
            continue
        if re.match(r"^\s{2}exclude_lifecycle_states:\s*$", line):
            in_states = True
            in_paths = False
            continue
        if in_paths:
            m = re.match(r"^\s{4}-\s+(.+?)/?\s*$", line)
            if m:
                seg = m.group(1).strip().rstrip("/")
                if seg and seg not in exclude_segments:
                    exclude_segments.append(seg)
            elif line.strip() and not line.startswith("    "):
                in_paths = False
        if in_states:
            m = re.match(r"^\s{4}-\s+([a-z_]+)", line)
            if m:
                exclude_states.add(m.group(1))
            elif line.strip() and not line.startswith("    "):
                in_states = False
    return exclude_segments, exclude_states


def under_brain(p: Path, root: Path) -> bool:
    try:
        p.relative_to(root)
        return True
    except ValueError:
        return False


def vault_rel(p: Path, root: Path) -> str:
    try:
        return str(p.relative_to(root))
    except ValueError:
        return str(p)


def path_has_excluded_segment(rel: str, segments) -> bool:
    parts = [x for x in rel.replace("\\", "/").split("/") if x]
    return any(seg in parts for seg in segments)


def load_jsonl(path: Path):
    rows = []
    if not path.is_file():
        return rows
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def indexed_paths(slug: str, root: Path):
    paths = set()
    meta = root / "projects" / slug / ".meta"
    for name in ("demoted.index.jsonl", "quarantine.index.jsonl"):
        for row in load_jsonl(meta / name):
            for key in ("path", "quarantine_path"):
                val = row.get(key)
                if val:
                    paths.add(val)
    return paths


def parse_frontmatter_state(path: Path):
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return None
    if not text.startswith("---"):
        return None
    parts = text.split("---", 2)
    if len(parts) < 3:
        return None
    fm = {}
    for line in parts[1].splitlines():
        if ":" not in line:
            continue
        k, _, v = line.partition(":")
        fm[k.strip()] = v.strip()
    state = fm.get("lifecycle_state")
    if not state and fm.get("status"):
        mapping = {
            "active": "active",
            "superseded": "superseded",
            "deprecated": "superseded",
            "demoted": "demoted",
            "quarantined": "quarantined",
            "invalidated": "invalidated",
            "archived": "demoted",
        }
        state = mapping.get(str(fm["status"]).strip().lower())
    return state


def project_slug_from_rel(rel: str):
    m = re.match(r"^projects/([^/]+)/", rel)
    return m.group(1) if m else None


exclude_segments, exclude_states = load_read_policy(Path(policy_path) if policy_path else Path())

if not under_brain(target, brain_root):
    sys.exit(0)

rel = vault_rel(target, brain_root)

reasons = []

if path_has_excluded_segment(rel, exclude_segments):
    reasons.append(f"exclude_path segment in {rel}")

slug = project_slug_from_rel(rel)
if slug:
    indexed = indexed_paths(slug, brain_root)
    if rel in indexed:
        reasons.append(f"listed in demoted/quarantine index ({rel})")
    # Also match when reading quarantine_path directly.
    for ip in indexed:
        if rel == ip or rel.endswith("/" + ip.split("/")[-1]):
            if ip != rel:
                reasons.append(f"matches indexed path {ip}")

if target.suffix == ".md" and target.is_file():
    state = parse_frontmatter_state(target)
    if state in exclude_states:
        reasons.append(f"lifecycle_state={state}")

if reasons:
    print(json.dumps({"violation": True, "path": rel, "reasons": reasons}))
PY
)" || check_result=""

if [ -z "$check_result" ]; then
  emit_allow
fi

violation="$(printf '%s' "$check_result" | jq -r '.violation // false' 2>/dev/null)"
if [ "$violation" != "true" ]; then
  emit_allow
fi

rel_path="$(printf '%s' "$check_result" | jq -r '.path // empty' 2>/dev/null)"
reasons="$(printf '%s' "$check_result" | jq -r '.reasons | join("; ")' 2>/dev/null)"

printf 'brain-read-policy: advisory — Read/Grep targets excluded brain path %s (%s)\n' \
  "$rel_path" "$reasons" >&2

if [ "$should_block" = true ]; then
  emit_deny "brain-read-policy: blocked read of excluded brain path ($rel_path): $reasons — use kb-query L1 or explicit audit ref at L2+"
fi

emit_allow
