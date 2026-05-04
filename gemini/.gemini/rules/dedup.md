# Dedup ladder

Apply in order; stop at first hit.

1. **Exact slug** — collision with existing `50-Published` or active draft slug → reject or bump suffix.
2. **SHA-256** of normalised `title + first 200 words` — internal **`qa-content`** during QA.
3. **Topic-set Jaccard ≥ 0.6** — internal **`kb-librarian`** against `70-Topics` + published index.
4. **Embedding cosine ≥ 0.85** (optional) — deferred until infra exists; not required at bootstrap.

## Outputs

Near-duplicate hits must surface in QA notes and `CcoRunReport.errors[]` without auto-deleting user work.
