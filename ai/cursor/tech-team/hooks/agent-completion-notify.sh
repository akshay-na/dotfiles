#!/usr/bin/env bash
# agent-completion-notify.sh
#
# Cursor `stop` hook — Apprise alert when the agent loop ends.
# Calls apprise directly with -g agent-alert (does NOT wrap via `notify`).
# Destinations: APPRISE_URLS only (same as notify; no --config / -c).
#
# Format:
#   Title (one of):
#     ✅ Agent Finished
#     ❌ Agent Failed
#     ⚠️ Agent Unresponsive
#     🌐 Host Offline
#   (aborted / cancelled stops are silent — no Discord alert)
#   Body: fenced code block with emoji labels —
#     Task / Host / Harness / Sub-agents counts + used list /
#     Total agent time / Tool calls / Chat ID
#
# Fail-open. Guardrails: skip if APPRISE_URLS or apprise missing.

set -u

trap 'exit 0' ERR

HARNESS_NAME="Cursor Chat"
APPRISE_TAG="agent-alert"
CONVERSATION_DB="${HOME}/Library/Application Support/Cursor/User/globalStorage/conversation-search.db"
TELEMETRY_DIR="${CURSOR_TELEMETRY_DIR:-$HOME/.cursor/logs/telemetry}"

_skip() {
  cat >/dev/null 2>&1 || true
  exit 0
}

[ -n "${APPRISE_URLS:-}" ] || _skip

export PATH="/opt/homebrew/bin:/usr/local/bin:${PATH:-/usr/bin:/bin}"

command -v apprise >/dev/null 2>&1 || _skip
command -v jq >/dev/null 2>&1 || _skip
command -v python3 >/dev/null 2>&1 || _skip

input="$(cat 2>/dev/null || true)"

status="$(printf '%s' "$input" | jq -r '.status // "completed"' 2>/dev/null || echo completed)"
status_lc="$(printf '%s' "$status" | tr '[:upper:]' '[:lower:]')"

# No Discord alert for user/system aborts.
case "$status_lc" in
aborted | abort | cancelled | canceled)
  exit 0
  ;;
esac

# Optional hint fields (undocumented / future-proof) — never logged raw if secret-like.
status_hint="$(printf '%s' "$input" | jq -r '[.reason // empty, .error // empty, .error_class // empty, .message // empty] | map(select(length > 0)) | join(" ")' 2>/dev/null || true)"
conversation_id="$(printf '%s' "$input" | jq -r '.conversation_id // empty' 2>/dev/null || true)"
transcript_path="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
[ -z "$transcript_path" ] && transcript_path="${CURSOR_TRANSCRIPT_PATH:-}"

host="$(hostname 2>/dev/null || echo unknown)"

# Normalize + classify into user-facing titles (aborted already exited above).
hint_lc="$(printf '%s' "$status_hint" | tr '[:upper:]' '[:lower:]')"
combined_lc="${status_lc} ${hint_lc}"

status_msg=""
case "$status_lc" in
completed | success | done | finished)
  status_msg="✅ Agent Finished"
  ;;
error | failed | failure)
  status_msg="❌ Agent Failed"
  ;;
unresponsive | timeout | timed_out | timed-out | hung | stalled)
  status_msg="⚠️ Agent Unresponsive"
  ;;
offline | disconnected | host_offline | unreachable)
  status_msg="🌐 Host Offline"
  ;;
esac

# Keyword overrides from hint / combined text (when status is generic error or unknown).
if [ -z "$status_msg" ] || [ "$status_msg" = "❌ Agent Failed" ]; then
  case "$combined_lc" in
  *offline* | *disconnect* | *unreachable* | *enossh* | *econnrefused*)
    status_msg="🌐 Host Offline"
    ;;
  *unresponsive* | *timeout* | *timed_out* | *timed-out* | *hung* | *stall*)
    status_msg="⚠️ Agent Unresponsive"
    ;;
  esac
  # Phrase with space (invalid in case glob patterns above)
  case "$combined_lc" in
  *"timed out"*)
    status_msg="⚠️ Agent Unresponsive"
    ;;
  esac
fi

# Remote agent + hard error often means the remote host dropped.
if [ -z "$status_msg" ] || [ "$status_msg" = "❌ Agent Failed" ]; then
  if [ "${CURSOR_CODE_REMOTE:-}" = "1" ] || [ "${CURSOR_CODE_REMOTE:-}" = "true" ]; then
    case "$combined_lc" in
    *offline* | *disconnect* | *network* | *unreachable*)
      status_msg="🌐 Host Offline"
      ;;
    esac
  fi
fi

# Final fallback for unknown statuses.
if [ -z "$status_msg" ]; then
  case "$status_lc" in
  "") status_msg="✅ Agent Finished" ;;
  *) status_msg="❌ Agent Failed" ;;
  esac
fi

# Build title + body via Python (task title, subagent tree, duration).
export _ACN_HOST="$host"
export _ACN_HARNESS="$HARNESS_NAME"
export _ACN_CHAT_ID="${conversation_id:-unknown}"
export _ACN_TRANSCRIPT="${transcript_path:-}"
export _ACN_CONV_DB="$CONVERSATION_DB"
export _ACN_TELEMETRY_DIR="$TELEMETRY_DIR"
export _ACN_TITLE="$status_msg"

body="$(
  python3 - <<'PY' 2>/dev/null || true
import json
import os
import re
from collections import Counter
from datetime import datetime
from glob import glob
from pathlib import Path

host = os.environ.get("_ACN_HOST", "unknown")
harness = os.environ.get("_ACN_HARNESS", "Cursor Chat")
chat_id = os.environ.get("_ACN_CHAT_ID", "unknown")
transcript = os.environ.get("_ACN_TRANSCRIPT", "")
conv_db = os.environ.get("_ACN_CONV_DB", "")
telem_dir = os.environ.get("_ACN_TELEMETRY_DIR", "")


def clean_line(s: str, n: int = 72) -> str:
    s = re.sub(r"\s+", " ", (s or "").replace("\n", " ").replace("\r", " ").replace("\t", " ")).strip()
    if len(s) <= n:
        return s
    cut = s[: n + 1]
    if " " in cut:
        cut = cut.rsplit(" ", 1)[0]
    return cut.rstrip(".,;:") + "…"


def title_ok(t: str) -> bool:
    if not t:
        return False
    low = t.lower()
    if t.startswith("<") or "<timestamp>" in low or "</timestamp>" in low:
        return False
    return True


def task_from_db(cid: str) -> str:
    if not cid or not conv_db or not Path(conv_db).is_file():
        return ""
    try:
        import sqlite3

        con = sqlite3.connect(f"file:{conv_db}?mode=ro", uri=True)
        row = con.execute(
            "SELECT title FROM conversations WHERE id = ? LIMIT 1", (cid,)
        ).fetchone()
        con.close()
        if row and row[0]:
            t = clean_line(row[0])
            return t if title_ok(t) else ""
    except Exception:
        pass
    return ""


def task_from_transcript(path: str) -> str:
    if not path or not Path(path).is_file():
        return ""
    text = ""
    try:
        with open(path, encoding="utf-8", errors="replace") as fh:
            for line in fh:
                try:
                    o = json.loads(line)
                except Exception:
                    continue
                if o.get("role") != "user":
                    continue
                c = (o.get("message") or {}).get("content")
                if isinstance(c, list):
                    text = " ".join(
                        x.get("text", "")
                        for x in c
                        if isinstance(x, dict) and x.get("type") == "text"
                    )
                elif isinstance(c, str):
                    text = c
                if text.strip():
                    break
    except Exception:
        return ""
    if not text:
        return ""
    m = re.search(r"<user_query>\s*(.*?)\s*</user_query>", text, re.S | re.I)
    if m:
        text = m.group(1)
    else:
        text = re.sub(r"<timestamp>.*?</timestamp>", " ", text, flags=re.S | re.I)
        text = re.sub(r"<uploaded_documents>.*?</uploaded_documents>", " ", text, flags=re.S | re.I)
        text = re.sub(r"</?[a-zA-Z_][\w.-]*>", " ", text)
    # Prefer short task headline: first line, before "so that" / em-dash / period
    text = text.strip().split("\n")[0].strip()
    m2 = re.split(r"\s+so that\s+|\s+—\s+|\.\s+", text, maxsplit=1, flags=re.I)
    text = m2[0].strip() if m2 else text
    text = clean_line(text, 72)
    if text and text[0].islower():
        text = text[0].upper() + text[1:]
    return text if title_ok(text) else ""


def parse_ts(s: str):
    if not s:
        return None
    s = s.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(s)
    except Exception:
        return None


def fmt_duration(seconds: float) -> str:
    if seconds < 0:
        seconds = 0
    total = int(round(seconds))
    h, rem = divmod(total, 3600)
    m, sec = divmod(rem, 60)
    if h:
        return f"{h}h {m}m {sec}s"
    if m:
        return f"{m}m {sec}s"
    return f"{sec}s"


def session_stats(cid: str):
    """Return (type_counts, completed, aborted, tool_calls, duration_s)."""
    type_counts: Counter = Counter()
    completed = 0
    aborted = 0
    starts = 0
    stops = 0
    tool_calls = 0
    first = last = None
    if not cid or not telem_dir:
        return type_counts, 0, 0, 0, None
    files = []
    p = Path(telem_dir)
    if (p / "events.jsonl").is_file():
        files.append(p / "events.jsonl")
    files.extend(sorted(p.glob("events-*.jsonl")))
    for fp in files:
        try:
            with open(fp, encoding="utf-8", errors="replace") as fh:
                for line in fh:
                    try:
                        o = json.loads(line)
                    except Exception:
                        continue
                    if o.get("session_id") != cid:
                        continue
                    ts = parse_ts(o.get("ts") or "")
                    if ts:
                        if first is None or ts < first:
                            first = ts
                        if last is None or ts > last:
                            last = ts
                    et = o.get("event_type")
                    if et == "preToolUse":
                        tool_calls += 1
                    elif et == "subagentStart":
                        starts += 1
                        st = o.get("subagent_type") or "unknown"
                        type_counts[st] += 1
                    elif et == "subagentStop":
                        stops += 1
                        outcome = (o.get("outcome") or "").lower()
                        if outcome in ("success", "completed", "ok", "done"):
                            completed += 1
                        else:
                            aborted += 1
        except Exception:
            continue
    # In-flight / missing stop → count as aborted
    if starts > stops:
        aborted += starts - stops
    total_sa = completed + aborted
    if total_sa == 0 and starts:
        total_sa = starts
    dur = (last - first).total_seconds() if first and last else None
    return type_counts, completed, aborted, tool_calls, dur


task = task_from_db(chat_id) or task_from_transcript(transcript)
if not task:
    task = chat_id[:8] if chat_id and chat_id != "unknown" else "Untitled chat"

type_counts, completed, aborted, tool_calls, dur_s = session_stats(chat_id)
total_sa = completed + aborted
if total_sa == 0:
    total_sa = sum(type_counts.values())
duration = fmt_duration(dur_s) if dur_s is not None else "n/a"

# Align Completed/Aborted values in a small column
comp_s = str(completed)
abor_s = str(aborted)
pad = max(len(comp_s), len(abor_s))

used_lines = []
if type_counts:
    items = sorted(type_counts.items(), key=lambda kv: (-kv[1], kv[0].lower()))
    used_lines = [f"{name} × {n}" for name, n in items]
else:
    used_lines = ["(none)"]

parts = [
    "📋 Task",
    task,
    "",
    "💻 Host",
    host,
    "",
    "🎛️ Harness",
    harness,
    "",
    f"👥 Sub-agents counts: {total_sa}",
    f"Completed: {comp_s.rjust(pad)}",
    f"Aborted:   {abor_s.rjust(pad)}",
    "",
    "🧩 Sub-agents used:",
]
parts.extend(used_lines)
parts.extend(
    [
        "",
        f"⏱️ Total agent time: {duration}",
        f"🔧 Tool calls: {tool_calls}",
        "",
        "💬 Chat ID",
        chat_id,
    ]
)

inner = "\n".join(parts)
print(f"```\n{inner}\n```")
PY
)"

[ -n "$body" ] || exit 0

title="${status_msg}"

log_dir="${HOME}/.cursor/logs"
mkdir -p "$log_dir" 2>/dev/null || true
{
  printf 'title: %s\n' "$title"
  printf '%s\n' "$body"
  printf -- '----\n'
} >>"${log_dir}/agent-completion-notify.log" 2>/dev/null || true

# Apprise ignores -g when APPRISE_URLS is set — keep only URLs tagged agent-alert.
filtered_urls="$(
  TAG="$APPRISE_TAG" python3 - <<'PY' 2>/dev/null || true
import os, re
from urllib.parse import urlparse, parse_qs

want = os.environ.get("TAG", "agent-alert")
raw = os.environ.get("APPRISE_URLS", "")
parts = [p for p in re.split(r"[\s,;]+", raw.strip()) if p]
kept = []
for u in parts:
    q = parse_qs(urlparse(u).query)
    tags = []
    for key in ("tag", "tags"):
        for v in q.get(key, []):
            tags.extend(t.strip() for t in v.split(",") if t.strip())
    if want in tags:
        kept.append(u)
print("\n".join(kept), end="")
PY
)"

if [ -z "$filtered_urls" ]; then
  printf '%s | skip: no APPRISE_URLS tagged %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$APPRISE_TAG" \
    >>"${log_dir}/agent-completion-notify.log" 2>/dev/null || true
  exit 0
fi

set --
while IFS= read -r u; do
  [ -n "$u" ] || continue
  set -- "$@" "$u"
done <<EOF
$filtered_urls
EOF

# Clear APPRISE_URLS so only filtered argv destinations are used.
APPRISE_URLS= apprise -t "$title" -b "$body" -i markdown "$@" >/dev/null 2>&1 || true

exit 0
