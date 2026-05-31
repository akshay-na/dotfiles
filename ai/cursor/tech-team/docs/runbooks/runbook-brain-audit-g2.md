# G2 brain-audit gate runbook

Gate **G2** (`verification-gates.yml` → `brain_audit`) blocks enforced demote until jq join proves **live** ledger events are joinable by `task_id`.

## Required event shape

Each JSONL line in `~/ai-brain/projects/<slug>/.meta/brain-audit-log.jsonl`:

| Field | Required |
|-------|----------|
| `trace_id` | yes |
| `task_id` | yes |
| `event_type` | `kb_query`, `kb_demote`, `session_flag`, or `stale_trap` |
| `ladder_depth` | yes (e.g. `L1` query, `L2` demote) |

**Join rule:** at least one `task_id` must appear in **≥2** events (typically `kb_query` + `kb_demote`).

Fixture reference:

```bash
jq -s 'group_by(.task_id) | map(select(length >= 2))' \
  ai/ai-brain/projects/dotfiles/observability/fixtures/brain-audit-join-sample.jsonl
```

## Verification commands (P3c)

```bash
# Contract + materialized policy parity
make check-brain-contract

# Fixture join (must pass before G2 work)
make validate-brain-audit

# Synthetic episode on live ledger (required before G2 flip — P5)
make brain-audit-synthetic SLUG=dotfiles

# Or explicit paths
LEDGER="$HOME/ai-brain/projects/dotfiles/.meta/brain-audit-log.jsonl"
./ai/ai-brain/scripts/brain-audit-synthetic-episode.sh \
  --ledger "$LEDGER" --slug dotfiles \
  --task-id "g2-flip-$(date -u +%Y%m%d)" \
  --trace-id "g2-flip-$(date -u +%Y%m%d)-exec"

make validate-brain-audit LEDGER="$LEDGER"
make check-g2-ready LEDGER="$LEDGER"
```

**Fixture-only** (mechanics smoke, **not** G2 sign-off):

```bash
./ai/ai-brain/scripts/brain-audit-synthetic-episode.sh --fixture-only --slug dotfiles
```

## Forbidden

- G2 sign-off on **fixture-only** join without a **live** ledger synthetic pass.
- Flip demote enforcement while `make check-g2-ready` exits non-zero.

## SLO rollup

After synthetic pass, append efficiency row:

```bash
make brain-efficiency-rollup
head -5 ~/ai-brain/org/global/orchestration/brain-efficiency-audit.md
```

Columns: `ts_utc | window_hours | entrypoint_episodes | l0l1_before_mutation_pct | bootstrap_degraded_pct | kb_query_events | slo_l0l1_met | slo_bootstrap_met`

Targets (7d window): L0/L1 before mutation ≥80%; bootstrap degraded <1%.

## Post-flip drift detection

G2 synthetic script proves jq join mechanics, not live coordinator emission. Monitor:

- `≥1 task_id/week` joinable per active project (`brain-audit-dashboard.md`)
- `brain-efficiency-audit.md` SLO rows

## stale_trap cross-link

Demotion + stale context recovery: `brain-demotion.md`

Wrong node triage: `ai/ai-brain/projects/dotfiles/observability/wrong-kb-node-triage.md`

## Rollback

Revert G2 flip in plan metadata (`g2_status: open`); restore advisory demote wording in `brain-memory-kb` skill.
