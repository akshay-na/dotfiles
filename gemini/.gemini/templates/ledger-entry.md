Ledger entries are stored in `kb/_meta/ledger.json` by **`archivist`** inside **`cco`**.

Shape (example):

```json
{
  "entries": [
    {
      "slug": "example-slug",
      "content_hash": "sha256:…",
      "canonical_url": "https://…",
      "published_at": "2026-05-04T12:00:00Z",
      "channels": ["blog"]
    }
  ]
}
```
