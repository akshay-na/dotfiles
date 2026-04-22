---
title: "Datastore: {{datastore_name}}"
type: datastore
project: {{project_name}}
tags:
  - kb
  - kb/project/{{project_name}}
  - kb/project/{{project_name}}/datastore/{{datastore_name}}
  - kb/type/datastore
generated_at: {{timestamp}}
generated_by: kb-engineer
source_files: {{source_files}}
discovery_sources: {{discovery_sources}}
port: {{port}}
protocol: {{protocol}}
kind: {{datastore_kind}}
confidence: {{confidence}}
stale: false
aliases: {{aliases}}
---

# Datastore: {{datastore_name}}

Back to [[{{project_name}}|{{project_name}}]].

## Purpose

{{purpose}}

Kind: **{{datastore_kind}}** — one of database, cache, or message broker.

Source content is capped at ~400 tokens per datastore doc.

## Image / Version

| Field | Value |
|-------|-------|
| Image | {{image}} |
| Version | {{image_version}} |
| Port | {{port_display}} |
| Protocol | {{protocol_display}} |

## Consumers

Services that read from or write to this datastore (backlinks so they render as graph edges).

{{consuming_services}}

## Topics / Tables / Keys Referenced

{{topics_tables_keys}}

## Consumer Graph

```mermaid
{{datastore_consumer_mermaid}}
```

## Connection Source

How this datastore was discovered — compose image, env var patterns like `*_DSN` / `*_DATABASE_URL` / `*_DB_*`, Kubernetes service refs, or `.proto` definitions.

| Source | Signal |
|--------|--------|
{{connection_sources_table}}

## Related

{{related_service_links}}
