# Wrong KB node triage (dotfiles project)

## Symptom

Agent repeats wrong facts; `stale_trap` fired; demoted nodes still appear in context.

## Steps

1. Check `~/ai-brain/projects/<slug>/.meta/brain-audit-log.jsonl` for `kb_query` / `kb_demote` / `stale_trap` with shared `task_id`.
2. Join sample (fixture):

```bash
jq -s 'group_by(.task_id) | map(select(length >= 2))' \
  ~/ai-brain/projects/dotfiles/observability/fixtures/brain-audit-join-sample.jsonl
```

3. Verify node `lifecycle_state` and `retrieval_weight` in frontmatter; confirm L1 `_index.md` no longer lists demoted paths.
4. Set `session/<task-id>/flags.yaml` → `fresh_eyes: true` or coordinator `clear_stale_trap` per `memory-demotion.yml`.

## Policy

`~/ai-brain/org/global/config/memory-demotion.yml` — `read_policy`, `stale_trap`, `fresh_eyes`.
