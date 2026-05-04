# metrics-current.json contract

## Top-level

- `schema_version` (int, current `1`).
- `updated_at` (ISO8601 UTC string or `null` before first steward run).
- `source` (`manual` | `export`).
- `channels` (object): keys `blog` | `twitter` | `linkedin` | `shorts` | `newsletter` (subset allowed).
- Each channel object may include KPIs: `views`, `likes`, `shares`, `saves`, `comments`, `ctr`, `watch_time_avg_sec`, `subs_net` — all optional numbers or `null`.
- `notes` (string, short).

## Steward behaviour

1. `git pull` on content repo, then validate inbound JSON against this contract; unknown keys allowed if `schema_version` matches tolerant mode (default: **tolerant** — steward preserves unknown channel keys in snapshot but normalises known ones).
2. Before overwrite: copy current file to `kb/90-Analytics/history/<updated_at>.json` (filename from new timestamp).
3. Write `metrics-current.json`, rewrite `metrics-summary.md` (short human prose).
4. Update `memory/org/metrics-latest.md` frontmatter + pointer paragraph.
5. Run `bash "$HOME/.gemini/scripts/kb-sync.sh" sync` (diff-driven commit; see `rules/repo-hygiene.md`).

## Readers

`cco` **METRICS_READ** loads `metrics-current.json` + `metrics-latest.md`; internal editors use metrics for length, CTA strength, and topic mix — never fabricate numbers not present in file.
