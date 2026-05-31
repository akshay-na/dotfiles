#!/usr/bin/env bash
# Shared helpers for ai-brain batch scripts (P3a).
set -euo pipefail

BRAIN_SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BRAIN_PACK_ROOT="$(cd "$BRAIN_SCRIPTS_DIR/.." && pwd)"
BRAIN_ROOT="${BRAIN_ROOT:-${HOME:?}/ai-brain}"
POLICY_SOURCE="$BRAIN_PACK_ROOT/org/global/config/memory-demotion.yml"

resolve_dotfiles_root() {
  if [[ -n "${DOTFILES_DIR:-}" && -d "$DOTFILES_DIR/ai/cursor/tech-team" ]]; then
    printf '%s\n' "$DOTFILES_DIR"
    return 0
  fi
  local candidate
  candidate="$(cd "$BRAIN_PACK_ROOT/../../.." 2>/dev/null && pwd || true)"
  if [[ -n "$candidate" && -d "$candidate/ai/cursor/tech-team" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi
  return 1
}

brain_lib_usage() {
  echo "brain-lib: sourced only" >&2
  exit 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && brain_lib_usage

resolve_policy_path() {
  local runtime="$BRAIN_ROOT/org/global/config/memory-demotion.yml"
  if [[ -f "$runtime" ]]; then
    echo "$runtime"
  elif [[ -f "$POLICY_SOURCE" ]]; then
    echo "$POLICY_SOURCE"
  else
    echo "brain-lib: missing memory-demotion policy" >&2
    return 1
  fi
}

sha256_file() {
  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    echo "brain-lib: shasum or sha256sum required" >&2
    return 1
  fi
}

find_signed_quarantine_manifest() {
  local slug="$1"
  local meta="$BRAIN_ROOT/projects/$slug/.meta"
  local f newest=""
  if [[ ! -d "$meta" ]]; then
    return 1
  fi
  newest=""
  while IFS= read -r -d '' f; do
    newest="$f"
  done < <(find "$meta" -maxdepth 1 -name 'pre-migrate-quarantine-*.yaml' -print0 2>/dev/null | sort -z)
  if [[ -z "$newest" || ! -f "$newest" ]]; then
    return 1
  fi
  if grep -Eq '^signed_off:[[:space:]]*true[[:space:]]*$' "$newest"; then
    echo "$newest"
    return 0
  fi
  return 1
}

kb_spine_dirs() {
  printf '%s\n' decisions constraints risks principles
}

list_kb_nodes() {
  local slug="$1"
  local base="$BRAIN_ROOT/projects/$slug"
  local d f
  for d in $(kb_spine_dirs); do
    [[ -d "$base/$d" ]] || continue
    find "$base/$d" -type f -name '*.md' ! -name '_index.md' -print 2>/dev/null
  done
}

vault_rel_path() {
  python3 - "$BRAIN_ROOT" "$1" <<'PY'
import os, sys
root, path = sys.argv[1], sys.argv[2]
print(os.path.relpath(path, root))
PY
}

brain_python() {
  python3 - "$@" <<'PY'
import hashlib, json, os, re, sys
from datetime import datetime, timezone
from pathlib import Path

BRAIN_ROOT = Path(os.environ.get("BRAIN_ROOT", Path.home() / "ai-brain"))
POLICY_PATH = Path(sys.argv[1])
CMD = sys.argv[2]
ARGS = sys.argv[3:]

STATUS_MAP = {
    "active": "active",
    "superseded": "superseded",
    "deprecated": "superseded",
    "demoted": "demoted",
    "quarantined": "quarantined",
    "invalidated": "invalidated",
    "archived": "demoted",
}

INJECTION_PATTERNS = [
    re.compile(r"ignore\s+(all\s+)?previous\s+instructions", re.I),
    re.compile(r"disregard\s+(all\s+)?(prior|above)", re.I),
    re.compile(r"<\s*script", re.I),
    re.compile(r"system\s+prompt", re.I),
    re.compile(r"you\s+are\s+now", re.I),
    re.compile(r"jailbreak", re.I),
    re.compile(r"\bDAN\s+mode\b", re.I),
]


def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def parse_scalar(val: str):
    val = val.strip()
    if val in ("null", "~", ""):
        return None
    if val == "true":
        return True
    if val == "false":
        return False
    if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
        return val[1:-1]
    try:
        if "." in val:
            return float(val)
        return int(val)
    except ValueError:
        return val


def parse_simple_yaml(text: str) -> dict:
    data = {}
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("- "):
            continue
        if ":" not in stripped:
            continue
        key, _, val = stripped.partition(":")
        data[key.strip()] = parse_scalar(val)
    return data


def yaml_quote(val: str) -> str:
    if re.search(r'[:#\n\'"]', val) or val != val.strip():
        return json.dumps(val)
    return val


def dump_scalar(val) -> str:
    if val is None:
        return "null"
    if isinstance(val, bool):
        return "true" if val else "false"
    if isinstance(val, float):
        if val == int(val):
            return str(int(val)) if val == 1.0 else str(val)
        return str(val)
    if isinstance(val, int):
        return str(val)
    return yaml_quote(str(val))


def dump_simple_yaml(data: dict) -> str:
    lines = [f"{k}: {dump_scalar(v)}" for k, v in data.items()]
    return "\n".join(lines) + "\n"


def dump_triage_manifest(manifest: dict) -> str:
    lines = [
        f"slug: {yaml_quote(manifest['slug'])}",
        f"generated_at: {yaml_quote(manifest['generated_at'])}",
        f"generated_by: {yaml_quote(manifest['generated_by'])}",
        "signed_off: false",
        "candidates:",
    ]
    for item in manifest.get("candidates") or []:
        lines.append(f"  - path: {yaml_quote(item['path'])}")
        lines.append("    signals:")
        for sig in item.get("signals") or []:
            lines.append(f"      - signal: {yaml_quote(sig['signal'])}")
            lines.append(f"        detail: {yaml_quote(sig.get('detail', ''))}")
    return "\n".join(lines) + "\n"


def parse_triage_manifest(text: str) -> dict:
    manifest = {"candidates": []}
    current = None
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("slug:"):
            manifest["slug"] = parse_scalar(stripped.partition(":")[2])
        elif stripped.startswith("- path:"):
            current = {"path": parse_scalar(stripped.partition(":")[2]), "signals": []}
            manifest["candidates"].append(current)
        elif stripped.startswith("signal:") and current is not None:
            sig = parse_scalar(stripped.partition(":")[2])
            current.setdefault("signals", []).append({"signal": sig})
        elif stripped.startswith("detail:") and current is not None and current.get("signals"):
            current["signals"][-1]["detail"] = parse_scalar(stripped.partition(":")[2])
    return manifest


def dump_session_index(doc: dict) -> str:
    lines = [
        f"contract_version: {doc['contract_version']}",
        f"task_id: {yaml_quote(doc['task_id'])}",
        f"project_slug: {yaml_quote(doc['project_slug'])}",
        f"generated_at: {yaml_quote(doc['generated_at'])}",
        f"generated_by: {yaml_quote(doc['generated_by'])}",
        "",
        "nodes:",
    ]
    for node in doc.get("nodes") or []:
        lines.append(f"  - path: {yaml_quote(node['path'])}")
        lines.append(f"    lifecycle_state: {yaml_quote(node['lifecycle_state'])}")
        weight = node["retrieval_weight"]
        lines.append(f"    retrieval_weight: {weight if isinstance(weight, float) else float(weight)}")
        if node.get("title"):
            lines.append(f"    title: {yaml_quote(node['title'])}")
        if node.get("type"):
            lines.append(f"    type: {yaml_quote(node['type'])}")
    return "\n".join(lines) + "\n"


def load_policy(path: Path):
    text = path.read_text()
    weights = {}
    state = None
    for line in text.splitlines():
        m = re.match(r"^\s{2}([a-z_]+):\s*$", line)
        if m and m.group(1) in STATUS_MAP:
            state = m.group(1)
            continue
        m = re.match(r"^\s{4}retrieval_weight:\s*([0-9.]+)", line)
        if m and state:
            weights[state] = float(m.group(1))
    exclude_states = []
    in_exclude = False
    for line in text.splitlines():
        if re.match(r"^read_policy:\s*$", line):
            in_exclude = False
        if re.match(r"^\s{2}exclude_lifecycle_states:\s*$", line):
            in_exclude = True
            continue
        if in_exclude:
            m = re.match(r"^\s{4}-\s+([a-z_]+)", line)
            if m:
                exclude_states.append(m.group(1))
            elif line and not line.startswith(" "):
                in_exclude = False
    policy = {"read_policy": {"exclude_lifecycle_states": exclude_states}}
    return policy, weights


def split_frontmatter(text: str):
    if not text.startswith("---"):
        return {}, text
    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}, text
    fm = parse_simple_yaml(parts[1])
    body = parts[2]
    if body.startswith("\n"):
        body = body[1:]
    return fm, body


def dump_frontmatter(fm: dict, body: str) -> str:
    order = list(fm.keys())
    lines = [f"{k}: {dump_scalar(fm[k])}" for k in order]
    return "---\n" + "\n".join(lines) + "\n---\n" + body


def vault_rel(path: Path) -> str:
    try:
        return str(path.relative_to(BRAIN_ROOT))
    except ValueError:
        return str(path)


def parse_node(path: Path):
    text = path.read_text(encoding="utf-8")
    fm, body = split_frontmatter(text)
    return fm, body, text


def migration_plan(fm: dict, weights: dict):
    status = fm.get("status")
    existing = fm.get("lifecycle_state")
    conflict = None
    target = None

    if status is not None and existing is not None:
        mapped = STATUS_MAP.get(str(status).strip().lower())
        if mapped and mapped != existing:
            conflict = f"dual_field_drift status={status} lifecycle_state={existing}"
        elif mapped:
            target = existing
        else:
            conflict = f"unknown_status_with_lifecycle status={status}"
    elif existing is not None:
        target = existing
    elif status is not None:
        key = str(status).strip().lower()
        if key in STATUS_MAP:
            target = STATUS_MAP[key]
        else:
            conflict = f"unknown_status status={status}"
    else:
        target = "active"

    if conflict:
        return None, None, conflict

    weight = weights.get(target, 0.0)
    new_fm = dict(fm)
    new_fm["lifecycle_state"] = target
    new_fm["retrieval_weight"] = weight
    if "status" in new_fm:
        del new_fm["status"]
    return new_fm, target, None


def is_unmigrated(fm: dict) -> bool:
    if "status" in fm:
        return True
    if "lifecycle_state" not in fm:
        return True
    if "retrieval_weight" not in fm:
        return True
    return False


LEGACY_SPINE_GLOBS = (
    "decision-*.md",
    "constraint-*.md",
    "risk-*.md",
    "principle-*.md",
)


def iter_spine_nodes(base: Path):
    """KB spine nodes: subdir trees plus legacy flat decision-/constraint-/… at project root."""
    seen = set()
    for spine in ("decisions", "constraints", "risks", "principles"):
        d = base / spine
        if d.is_dir():
            for path in sorted(d.rglob("*.md")):
                if path.name == "_index.md":
                    continue
                seen.add(path)
                yield spine, path
    for spine, pattern in zip(
        ("decisions", "constraints", "risks", "principles"),
        LEGACY_SPINE_GLOBS,
    ):
        for path in sorted(base.glob(pattern)):
            if path not in seen:
                seen.add(path)
                yield spine, path


def iter_migrate_nodes(base: Path):
    for _, path in iter_spine_nodes(base):
        yield path


def injection_hits(body: str):
    hits = []
    for pat in INJECTION_PATTERNS:
        if pat.search(body):
            hits.append(pat.pattern)
    return hits


def load_jsonl(path: Path):
    rows = []
    if not path.is_file():
        return rows
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            rows.append(json.loads(line))
        except json.JSONDecodeError:
            continue
    return rows


def stale_trap_signals(slug: str, rel: str):
    signals = []
    meta = BRAIN_ROOT / "projects" / slug / ".meta"
    for row in load_jsonl(meta / "demoted.index.jsonl"):
        if row.get("path") == rel and row.get("demotion_reason") == "stale_trap":
            signals.append("demoted_index_stale_trap")
    audit = meta / "brain-audit-log.jsonl"
    for row in load_jsonl(audit):
        if row.get("event_type") == "stale_trap" and rel in json.dumps(row):
            signals.append("audit_stale_trap")
    traps = BRAIN_ROOT / "org/global/orchestration/brain-stale-traps.md"
    if traps.is_file() and rel in traps.read_text():
        signals.append("stale_traps_sink")
    return signals


def dual_field_signal(fm: dict):
    if "status" not in fm or "lifecycle_state" not in fm:
        return None
    status = str(fm.get("status", "")).strip().lower()
    existing = fm.get("lifecycle_state")
    mapped = STATUS_MAP.get(status)
    if mapped and mapped != existing:
        return f"status={fm.get('status')} lifecycle_state={existing}"
    if mapped is None:
        return f"unknown_status={fm.get('status')} with lifecycle_state={existing}"
    return f"both_keys status={fm.get('status')} lifecycle_state={existing}"


def cmd_migrate(args):
    slug, apply_flag, report_path = args[0], args[1] == "apply", Path(args[2])
    _, weights = load_policy(POLICY_PATH)
    base = BRAIN_ROOT / "projects" / slug
    if not base.is_dir():
        sys.stderr.write(f"migrate: missing project {slug}\n")
        sys.exit(1)

    manifest_path = args[3] if len(args) > 3 and args[3] else ""
    manifest_sha = ""
    if manifest_path:
        mp = Path(manifest_path)
        if mp.is_file():
            import hashlib
            manifest_sha = hashlib.sha256(mp.read_bytes()).hexdigest()

    report_path.parent.mkdir(parents=True, exist_ok=True)
    header = {
        "record_type": "header",
        "slug": slug,
        "generated_at": utc_now(),
        "mode": "apply" if apply_flag else "dry-run",
        "manifest_path": manifest_path or None,
        "manifest_sha256": manifest_sha or None,
    }
    lines = [json.dumps(header, sort_keys=True)]

    migrated = conflicts = skipped = 0
    for path in iter_migrate_nodes(base):
        rel = vault_rel(path)
        fm, body, raw = parse_node(path)
        if not is_unmigrated(fm) and "status" not in fm:
            skipped += 1
            continue
        new_fm, target, conflict = migration_plan(fm, weights)
        rec = {
            "record_type": "node",
            "path": rel,
            "status_stripped": False,
        }
        if conflict:
            rec["outcome"] = "conflict"
            rec["reason"] = conflict
            conflicts += 1
            lines.append(json.dumps(rec, sort_keys=True))
            continue
        rec["outcome"] = "migrate"
        rec["lifecycle_state"] = target
        rec["retrieval_weight"] = new_fm.get("retrieval_weight")
        rec["had_status"] = "status" in fm
        if apply_flag:
            new_text = dump_frontmatter(new_fm, body)
            path.write_text(new_text, encoding="utf-8")
            rec["status_stripped"] = "status" not in new_fm
        else:
            rec["status_stripped"] = "status" not in new_fm
            rec["would_strip_status"] = "status" in fm
        migrated += 1
        lines.append(json.dumps(rec, sort_keys=True))

    summary = {
        "record_type": "summary",
        "migrated": migrated,
        "conflicts": conflicts,
        "skipped_already_migrated": skipped,
    }
    lines.append(json.dumps(summary, sort_keys=True))
    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(json.dumps(summary))
    if conflicts:
        sys.exit(2 if not apply_flag else 3)
    sys.exit(0)


def cmd_check_slug(args):
    slug = args[0]
    base = BRAIN_ROOT / "projects" / slug
    if not base.is_dir():
        sys.stderr.write(f"check-slug: missing project {slug}\n")
        sys.exit(1)
    count = 0
    for path in iter_migrate_nodes(base):
        fm, _, _ = parse_node(path)
        if is_unmigrated(fm):
            count += 1
            print(vault_rel(path))
    if count:
        sys.stderr.write(f"check-slug: {count} unmigrated node(s) in {slug}\n")
        sys.exit(1)
    print(f"check-slug: ok {slug}")
    sys.exit(0)


def cmd_triage(args):
    slug, out_path = args[0], Path(args[1]) if len(args) > 1 and args[1] else None
    base = BRAIN_ROOT / "projects" / slug
    if not base.is_dir():
        sys.stderr.write(f"triage: missing project {slug}\n")
        sys.exit(1)
    candidates = []
    for spine, path in iter_spine_nodes(base):
        rel = vault_rel(path)
        fm, body, _ = parse_node(path)
        signals = []
        dual = dual_field_signal(fm)
        if dual:
            signals.append({"signal": "dual_field_drift", "detail": dual})
        inj = injection_hits(body)
        if inj:
            signals.append({"signal": "injection_suspect", "detail": "; ".join(inj[:3])})
        stale = stale_trap_signals(slug, rel)
        for s in stale:
            signals.append({"signal": "stale_trap", "detail": s})
        if signals:
            candidates.append({"path": rel, "signals": signals})

    manifest = {
        "slug": slug,
        "generated_at": utc_now(),
        "generated_by": "brain-quarantine-triage.sh",
        "signed_off": False,
        "candidates": candidates,
    }
    text = dump_triage_manifest(manifest)
    if out_path:
        out_path.parent.mkdir(parents=True, exist_ok=True)
        out_path.write_text(text, encoding="utf-8")
        print(f"triage: wrote {out_path} ({len(candidates)} candidate(s))")
    else:
        print(text, end="")
    sys.exit(0)


def cmd_quarantine_apply(args):
    slug, manifest_path, apply_flag = args[0], Path(args[1]), args[2] == "apply"
    manifest = parse_triage_manifest(manifest_path.read_text())
    base = BRAIN_ROOT / "projects" / slug
    quarantine_dir = base / "quarantine"
    index_path = base / ".meta" / "quarantine.index.jsonl"
    applied = 0
    for item in manifest.get("candidates") or []:
        rel = item.get("path")
        if not rel:
            continue
        src = BRAIN_ROOT / rel
        if not src.is_file():
            print(json.dumps({"path": rel, "outcome": "missing"}))
            continue
        fm, body, _ = parse_node(src)
        dest_name = Path(rel).name
        dest = quarantine_dir / dest_name
        rec = {"path": rel, "signal": item.get("signals", [{}])[0].get("signal", "unknown")}
        if apply_flag:
            quarantine_dir.mkdir(parents=True, exist_ok=True)
            (base / ".meta").mkdir(parents=True, exist_ok=True)
            fm["lifecycle_state"] = "quarantined"
            fm["retrieval_weight"] = 0
            fm["demotion_reason"] = rec["signal"]
            new_text = dump_frontmatter(fm, body)
            dest.write_text(new_text, encoding="utf-8")
            src.unlink()
            row = {
                "at": utc_now(),
                "path": rel,
                "quarantine_path": vault_rel(dest),
                "reason": rec["signal"],
            }
            with index_path.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(row, sort_keys=True) + "\n")
            rec["outcome"] = "quarantined"
            applied += 1
        else:
            rec["outcome"] = "would_quarantine"
            rec["quarantine_path"] = vault_rel(dest)
        print(json.dumps(rec, sort_keys=True))
    print(json.dumps({"applied": applied, "mode": "apply" if apply_flag else "dry-run"}))
    sys.exit(0)


def cmd_rebuild_l1(args):
    slug, apply_flag = args[0], args[1] == "apply"
    _, weights = load_policy(POLICY_PATH)
    base = BRAIN_ROOT / "projects" / slug
    index_path = base / "_index.md"
    rows = []
    for spine, path in iter_spine_nodes(base):
        fm, body, _ = parse_node(path)
        state = fm.get("lifecycle_state")
        if not state and fm.get("status"):
            key = str(fm["status"]).strip().lower()
            state = STATUS_MAP.get(key, "active")
        if state not in ("active", "superseded"):
            continue
        title = fm.get("title") or path.stem
        summary = ""
        for line in body.splitlines():
            line = line.strip()
            if line.startswith("#"):
                title = line.lstrip("#").strip() or title
                continue
            if line and not line.startswith("|") and not line.startswith(">"):
                summary = line[:80]
                break
        node_id = fm.get("id") or path.stem
        rows.append((spine, node_id, fm.get("type", spine.rstrip("s")), summary or title))

    lines = [
        f"# Index: project.{slug}",
        "",
        f"> Last updated: {utc_now()[:10]}",
        "",
        "## Summary",
        "",
        f"Project KB L1 index for `{slug}`. Lists active and superseded nodes only.",
        "",
        "## Memory Entries",
        "",
        "| ID | Type | Summary |",
        "|----|------|---------|",
    ]
    for _, node_id, ntype, summary in sorted(rows, key=lambda r: (r[0], r[1])):
        safe_summary = summary.replace("|", "\\|")
        lines.append(f"| {node_id} | {ntype} | {safe_summary} |")

    content = "\n".join(lines) + "\n"
    if apply_flag:
        index_path.write_text(content, encoding="utf-8")
        print(f"rebuild-l1: wrote {index_path} ({len(rows)} row(s))")
    else:
        print(content, end="")
        print(f"rebuild-l1: dry-run {len(rows)} row(s)", file=sys.stderr)
    sys.exit(0)


def cmd_rebuild_session(args):
    task_id, slug, apply_flag = args[0], args[1], args[2] == "apply"
    _, weights = load_policy(POLICY_PATH)
    policy, _ = load_policy(POLICY_PATH)
    exclude_states = set((policy.get("read_policy") or {}).get("exclude_lifecycle_states") or [])
    nodes = []
    base = BRAIN_ROOT / "projects" / slug
    for spine in ("decisions", "constraints", "risks", "principles"):
        d = base / spine
        if not d.is_dir():
            continue
        for path in sorted(d.rglob("*.md")):
            if path.name == "_index.md":
                continue
            rel = vault_rel(path)
            if "/quarantine/" in rel or "/archive/" in rel:
                continue
            fm, _, _ = parse_node(path)
            state = fm.get("lifecycle_state")
            if not state and fm.get("status"):
                state = STATUS_MAP.get(str(fm["status"]).strip().lower(), "active")
            if not state:
                state = "active"
            weight = fm.get("retrieval_weight")
            if weight is None:
                weight = weights.get(state, 0.0)
            if state in exclude_states:
                continue
            entry = {
                "path": rel,
                "lifecycle_state": state,
                "retrieval_weight": float(weight),
            }
            if fm.get("title"):
                entry["title"] = fm["title"]
            if fm.get("type"):
                entry["type"] = fm["type"]
            nodes.append(entry)

    doc = {
        "contract_version": 1,
        "task_id": task_id,
        "project_slug": slug,
        "generated_at": utc_now(),
        "generated_by": "brain-rebuild-session-index.sh",
        "nodes": nodes,
    }
    out = BRAIN_ROOT / "session" / task_id / "memory.index.yaml"
    text = dump_session_index(doc)
    if apply_flag:
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(text, encoding="utf-8")
        print(f"rebuild-session: wrote {out} ({len(nodes)} node(s))")
    else:
        print(text, end="")
        print(f"rebuild-session: dry-run {len(nodes)} node(s)", file=sys.stderr)
    sys.exit(0)


SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

DEFAULT_BLURBS = {
    "dotfiles": "DotMate: stow-based dotfiles + AI pack template transpiler",
    "home-server": "Homelab Ansible / k3s / automation (migration platform repo)",
    "uprelay": "OpenAI-compatible multi-provider Cursor proxy",
    "migration-platform-repo": "Homelab platform migration (Terraform, Ansible, GitOps)",
    "trading-foundry": "Private trading / quant content and automation workspace",
}


def is_project_slug(name: str) -> bool:
    return bool(SLUG_RE.match(name))


def load_manifest(slug: str):
    for rel in (f"projects/{slug}/manifest.json", f"projects/{slug}/.meta/manifest.json"):
        path = BRAIN_ROOT / rel
        if path.is_file():
            try:
                return json.loads(path.read_text(encoding="utf-8"))
            except json.JSONDecodeError:
                return None
    return None


def manifest_blurb(manifest: dict) -> str:
    if not manifest:
        return ""
    for key in ("compass_blurb", "home_blurb", "description", "summary", "title"):
        val = manifest.get(key)
        if isinstance(val, str) and val.strip():
            return val.strip().replace("\n", " ")[:120]
    return ""


def spine_blurb(slug: str) -> str:
    for name in (f"{slug}.md", "README.md"):
        path = BRAIN_ROOT / "projects" / slug / name
        if not path.is_file():
            continue
        _, body, _ = parse_node(path)
        for line in body.splitlines():
            line = line.strip()
            if not line:
                continue
            if line.startswith(("#", "|", "-", ">", "---")):
                continue
            return line.replace("\n", " ")[:120]
    return ""


def hub_href(slug: str) -> str:
    base = f"projects/{slug}"
    for tail in (f"{slug}.md", "_index.md", "README.md"):
        if (BRAIN_ROOT / base / tail).is_file():
            return f"{base}/{tail}"
    return f"{base}/"


def discover_project_slugs():
    projects = BRAIN_ROOT / "projects"
    if not projects.is_dir():
        return []
    slugs = []
    for entry in sorted(projects.iterdir()):
        if not entry.is_dir():
            continue
        name = entry.name
        if not is_project_slug(name):
            continue
        slugs.append(name)
    return slugs


def cmd_sync_home(args):
    apply_flag = args[0] == "apply"
    slugs = discover_project_slugs()
    entries = []
    for slug in slugs:
        manifest = load_manifest(slug)
        blurb = manifest_blurb(manifest) or spine_blurb(slug) or DEFAULT_BLURBS.get(slug, slug.replace("-", " "))
        entries.append((slug, hub_href(slug), blurb))

    lines = [
        "# ai-brain Home",
        "",
        "## Projects",
        "",
    ]
    for slug, href, blurb in entries:
        lines.append(f"- [{slug}]({href}) — {blurb}")
    lines.extend(["", "## Org", "", "- [Org global compass](org/global/_index.md)", "- [Operator profile](org/global/operator-profile/README.md)", ""])
    content = "\n".join(lines)

    home_path = BRAIN_ROOT / "Home.md"
    if apply_flag:
        home_path.write_text(content, encoding="utf-8")
        print(f"sync-home: wrote {home_path} ({len(entries)} project(s))")
    else:
        print(content, end="")
        print(f"sync-home: dry-run {len(entries)} project(s)", file=sys.stderr)
    sys.exit(0)


handlers = {
    "migrate": cmd_migrate,
    "check-slug": cmd_check_slug,
    "triage": cmd_triage,
    "quarantine-apply": cmd_quarantine_apply,
    "rebuild-l1": cmd_rebuild_l1,
    "rebuild-session": cmd_rebuild_session,
    "sync-home": cmd_sync_home,
}

if CMD not in handlers:
    sys.stderr.write(f"brain-lib python: unknown cmd {CMD}\n")
    sys.exit(2)
handlers[CMD](ARGS)
PY
}
