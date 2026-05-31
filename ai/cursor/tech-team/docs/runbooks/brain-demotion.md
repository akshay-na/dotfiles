# Brain demotion runbook

Operator guide for **advisory (pre-G2)** and **enforced (post-G2)** KB demotion, stale-trap recovery, and triage.

## Policy source

- Canonical YAML: `dotfiles/ai/ai-brain/org/global/config/memory-demotion.yml`
- Runtime copy: `~/ai-brain/org/global/config/memory-demotion.yml` (materialize via `make materialize-brain-policy` + `--apply`)
- Contract check: `make check-brain-contract`

## Pre-G2 (advisory demote)

Until G2 flip (`verification-gates.yml` → `brain_audit` e2e join passes on **live** ledger):

1. Coordinators record demote **intent** via `brain-memory-kb` → `log_brain_event` with `event_type: kb_demote`.
2. **No** automatic `lifecycle_state` disk writes except human-approved remediation runs.
3. Every demote intent should pair with a prior `kb_query` sharing `task_id` and `trace_id`.

## Post-G2 (enforced demote)

After P5 flip:

1. Demote patches node frontmatter (`lifecycle_state: demoted`), appends `demoted.index.jsonl`, rebuilds L1.
2. Missing `kb_demote` audit after demote disk write is **fail-closed** for entrypoints.
3. After `kb_demote`, rebuild session index: `~/ai-brain/scripts/brain-rebuild-session-index.sh <task-id> <slug> --apply`.

## stale_trap loop

When coordinator hits repeated failures (policy: 3 failures, 2 kinds):

1. Emit `stale_trap` brain-audit event (shared `task_id` / `trace_id`).
2. Set `session/<task-id>/flags.yaml` → `fresh_eyes: true`.
3. Entrypoint runs L0/L1 kb-query ladder before next mutation.
4. Clear via coordinator `clear_stale_trap` or policy-defined recovery.

Log rows in `~/ai-brain/org/global/orchestration/brain-stale-traps.md`.

## Wrong KB node triage

See fixture project triage doc:

- `ai/ai-brain/projects/dotfiles/observability/wrong-kb-node-triage.md`

Quick checks:

```bash
# Audit ledger for shared task_id
tail -20 ~/ai-brain/projects/<slug>/.meta/brain-audit-log.jsonl

# G2 join validator
make validate-brain-audit LEDGER=~/ai-brain/projects/<slug>/.meta/brain-audit-log.jsonl
```

## Demotion audit sink

Append human-readable rows to `~/ai-brain/org/global/orchestration/memory-demotion-audit.md` during remediation (P4c+ seeds).

## Read policy hook (P6)

`preToolUse` matcher `Read|Grep` → `hooks/brain-read-policy-advisory.sh` (`failClosed: false`).

Surfaces violations when tools target:

- Paths under `quarantine/` or `archive/` (per `read_policy.exclude_paths`)
- Nodes listed in `demoted.index.jsonl` or `quarantine.index.jsonl`
- Markdown nodes with `lifecycle_state ∈ {demoted, quarantined, invalidated}`

### Env flag matrix

| Env | Default | Effect |
|-----|---------|--------|
| *(none)* | — | **Advisory** — stderr warning, tool proceeds |
| `CURSOR_BRAIN_READ_POLICY_DISABLED=1` | off | Kill switch — hook no-op (fail-open allow) |
| `CURSOR_BRAIN_READ_POLICY_ENFORCE=1` | off | **Block** Read/Grep on policy violations (deny) |
| `CURSOR_BRAIN_READ_POLICY_ENTRYPOINT_ENFORCE=1` | off | Block violations for entrypoint agents only (`cto`, `tech-lead`, `code-reviewer`, `cco`, `cio`, `content-lead`, `trading-lead`, `n8n-builder`, `remotion-builder`, `atlassian-pm`) |

### Deferred mechanical enforce (G2 open)

Until **G2 flip** (`verification-gates.yml` → `brain_audit` live ledger join passes — see `runbook-brain-audit-g2.md`):

- Hook ships **enabled** in advisory mode only at org level.
- Do **not** set `CURSOR_BRAIN_READ_POLICY_ENFORCE=1` globally until G2 closes **and** 14 calendar days of stable G2 SLO (per plan P6).
- `CURSOR_BRAIN_READ_POLICY_ENTRYPOINT_ENFORCE=1` may be used for coordinator smoke tests after G2 flip.

**Grep without `path`:** hook emits advisory to prefer `brain-memory-kb` kb-query L1; enforce modes deny unscoped Grep.

### Manual smoke

```bash
# Advisory warning (stderr) — create a quarantine path or use an indexed node
echo '{"tool_name":"Read","tool_input":{"path":"~/ai-brain/projects/dotfiles/quarantine/smoke-test.md"}}' \
  | ./ai/cursor/tech-team/hooks/brain-read-policy-advisory.sh 2>&1

# Enforce block
echo '{"tool_name":"Read","tool_input":{"path":"~/ai-brain/projects/dotfiles/quarantine/smoke-test.md"}}' \
  | env CURSOR_BRAIN_READ_POLICY_ENFORCE=1 ./ai/cursor/tech-team/hooks/brain-read-policy-advisory.sh
```

## Related runbooks

- G2 synthetic gate: `runbook-brain-audit-g2.md`
- Portability ADR: `.cursor/docs/decisions/2026-06-01-brain-portability.md`
