# Runbook — Subagent Response Protocol

Single-page runbook for the three alerts defined in plan §8.3 plus monthly
JSONL pruning (R15).

> **Note on telemetry (2026-04-23):** the runtime `subagent-protocol-validate`
> hook was removed to drop the python dependency. Parent-side parse is now
> rule-driven (parents execute the 8-step contract in-band). The JSONL
> telemetry below is no longer auto-written; rows appear only when a parent
> agent explicitly appends them during synthesis. Alert queries remain valid
> against any rows that do get written but will return empty on an idle log.

## Signals and sources

- Telemetry: `~/.cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl` (manual append)
- Template: `~/.cursor/templates/subagent-response.yml.tmpl`
- Contract: `~/.cursor/templates/subagent-contract-block.md`
- Rule (parent parse contract): `~/.cursor/rules/subagent-response-protocol.mdc`
- Inject hook: `~/.cursor/hooks/subagent-protocol-inject.sh`
- Lint hook: `~/.cursor/hooks/subagent-protocol-lint.sh`
- Dashboard: `~/.cursor/docs/dashboards/subagent-protocol.md`
- Quarantine: `~/.cursor/memory/projects/dotfiles/explore-dumps/<task-id>.md`

## Alert: schema_drop

- **Trigger:** `schema_valid` rate drops below 90 % over the last 20 invocations.
- **Query one-liner:**
  ```bash
  tail -n 200 ~/.cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl \
    | grep -v '^#' \
    | python3 -c "import sys,json; rows=[json.loads(l) for l in sys.stdin if l.strip()][-20:]; print(sum(1 for r in rows if r.get('schema_valid'))/max(1,len(rows)))"
  ```
- **Response:**
  1. Check the last 5 failing rows (`tail` the JSONL). Read `errors[]`.
  2. If `yaml parse failed` dominates → YAML backend issue. Confirm `pyyaml` /
     `yq` / `ruby` is installed.
  3. If `missing required field` dominates → the contract text drifted
     silently. Re-apply templates via `make stow CONFIGS="cursor"`. Run
     `subagent-protocol-lint.sh` to confirm SoT invariant.
  4. If `_marker mismatch` dominates → inject hook is failing to cache the
     marker. Inspect `${TMPDIR}/cursor-subagent-protocol/` permissions.
  5. If the pattern is a specific agent, invoke `vp-onboarding` to refresh
     that agent's protocol xref (agent bodies may have stale inlined schema).

## Alert: prose_leak

- **Trigger:** `caveman_level_detected == "normal"` AND
  `caveman_forced_normal == false`, OR non-security response where raw prose
  bytes exceed 200 in a single envelope.
- **Query one-liner:**
  ```bash
  tail -n 200 ~/.cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl \
    | grep -v '^#' \
    | python3 -c "import sys,json; rows=[json.loads(l) for l in sys.stdin if l.strip()]; print([r['task_id'] for r in rows if r.get('caveman_level_detected')=='normal' and not r.get('caveman_forced_normal')][-5:])"
  ```
- **Response:**
  1. Pull the task-ids; retrieve parent transcript to read the actual summary.
  2. Check whether caveman skill / rule drifted (run lint).
  3. If the specific agent's `description` has shifted its caveman default,
     reconcile against the role-template table in `~/.cursor/skills/caveman/SKILL.md`.

## Alert: fidelity_drop

- **Trigger:** `fidelity_flag == true` OR `redaction_hits > 0` on any
  envelope.
- **Response (treat as security incident):**
  1. The raw response is in `explore-dumps/<task-id>.md` with 0600 perms.
     Review it in a secure shell only.
  2. If a real secret matched the redactor, rotate the credential immediately.
     Do NOT propagate the raw token to Slack, Jira, or any other system.
  3. File a note under `~/.cursor/memory/projects/dotfiles/decisions/` with
     the redaction pattern name + rotation evidence.
  4. If the match was a false positive (e.g. a legitimate UUID mis-pattern),
     extend the allowlist in `find_secret_hits()`. Bump `# pattern_lib:` in
     `subagent-response.yml.tmpl` to a new commit sha before deploying.

## Weekly rollup (Fridays, manual)

Computes `token_regress` as a slow-moving signal. Not a standing alert (D24).

```bash
python3 - <<'PY'
import json, pathlib, statistics
p = pathlib.Path.home()/".cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl"
rows = [json.loads(l) for l in p.read_text().splitlines() if l and not l.startswith('#')]
bytes_by_stage = {"observe_warn": [], "enforce": []}
for r in rows:
    stage = r.get("stage")
    if stage in bytes_by_stage and r.get("out_bytes"):
        bytes_by_stage[stage].append(r["out_bytes"])
for s, v in bytes_by_stage.items():
    if v:
        print(f"{s:14} median_out_bytes={statistics.median(v):.0f} n={len(v)}")
PY
```

## Monthly JSONL prune (R15)

Single-user retention: keep 90 days of rows; archive older to `.archive/`.

```bash
JSONL=~/.cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl
ARCHIVE=~/.cursor/memory/projects/dotfiles/observability/subagent-protocol/.archive
mkdir -p "$ARCHIVE"
cutoff=$(date -v-90d +%Y-%m-%d)
python3 - <<PY
import json, pathlib
p = pathlib.Path("$JSONL")
a = pathlib.Path("$ARCHIVE") / f"responses-{pathlib.Path.cwd().name}-{'$cutoff'.replace('-','')}.jsonl"
keep, drop = [], []
for line in p.read_text().splitlines():
    if line.startswith('#') or not line.strip():
        keep.append(line); continue
    try:
        ts = json.loads(line).get('ts','')
        (keep if ts[:10] >= '$cutoff' else drop).append(line)
    except Exception:
        keep.append(line)
if drop:
    a.write_text('\n'.join(drop)+'\n')
p.write_text('\n'.join(keep)+'\n')
print(f"archived={len(drop)} kept={len(keep)} -> {a}")
PY
```

Cron is intentionally not used (single-user, low-volume). Calendar-reminder
this the first Friday of every month.

## vp-onboarding refresh (post-enforce)

Existing project agents created before the protocol shipped do not carry the
one-line xref. When the user invokes `vp-onboarding` on an existing project,
the template patcher must:

1. Detect `.cursor/agents/*.md` whose body lacks a reference to
   `subagent-response-protocol`.
2. Append a single bullet under the agent's "Rules" or "Scope" section:
   `- Subagent traffic follows `subagent-response-protocol`; hooks own the contract.`
3. Do NOT paste schema or contract text inline. The pre-commit lint blocks
   drift.
4. Run `subagent-protocol-lint.sh --staged` before committing.

## Phase flip (observe_warn ↔ enforce)

With the runtime validator removed, `phase.enforce` / `SUBAGENT_PROTOCOL_PHASE`
no longer drive any hook. Phase policy is now rule-documented intent only;
parents MUST hard-block downstream flows on a malformed-after-retry child
envelope per the enforcement-posture section of the rule. To intentionally
loosen behavior to `observe_warn` (tagging only, no hard block), edit the
rule's enforcement-posture paragraph and capture the rollback reason under
`~/.cursor/memory/projects/dotfiles/decisions/`. The `phase.enforce` file is
inert and may be deleted.

## Weekly alert check (manual cron-equivalent)

Run every Friday alongside the weekly rollup. Surfaces the three alerts
defined earlier, each returning a line suitable for Slack/standup:

```bash
python3 - <<'PY'
import json, pathlib, datetime
p = pathlib.Path.home()/".cursor/memory/projects/dotfiles/observability/subagent-protocol/responses.jsonl"
rows = [json.loads(l) for l in p.read_text().splitlines() if l and not l.startswith('#')]
recent = rows[-20:]
if recent:
    valid = sum(1 for r in recent if r.get('schema_valid'))
    rate = valid / len(recent)
    if rate < 0.90:
        print(f"ALERT schema_drop rate={rate:.2f} n={len(recent)}")
    leaks = [r for r in recent
             if r.get('caveman_level_detected') == 'normal'
             and not r.get('caveman_forced_normal')]
    if leaks:
        print(f"ALERT prose_leak n={len(leaks)} ids={[x.get('task_id') for x in leaks][:5]}")
    fidel = [r for r in rows if r.get('fidelity_flag')]
    if fidel:
        print(f"ALERT fidelity_drop total={len(fidel)} latest_ts={fidel[-1].get('ts')}")
PY
```

Ship output to the standup channel. Zero output = all clear for the week.

## Escalation

- Hook failure or corruption (`inject.sh` / `lint.sh`) → `sme-stow` for stow
  re-apply; `dev-shell` for POSIX compatibility fixes.
- Fuzzy-redaction false positives (parent-side) → extend the allowlist
  documented in the skill's fuzzy-redaction section and bump
  `# pattern_lib:` sha in the response template.
- Repeated cross-agent drift → invoke `cto` for re-evaluation; may require a
  `schema_version: 2` plan.
