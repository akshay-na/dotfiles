---
name: kb-generation
description: Core generation protocol for Knowledge Base documents. Analyzes project structure, generates Obsidian-compatible markdown with mermaid diagrams, builds relationship graphs, and tracks manifests for incremental updates.
version: 1
input_schema:
  required:
    - name: project_root
      type: string
      description: Absolute path to the project root directory
    - name: mode
      type: string
      description: Generation mode - "full", "incremental", or "refresh-stale"
  optional:
    - name: scope
      type: string
      description: What to generate - "all", "architecture", "modules", "services", "dependencies". Default is "all".
output_schema:
  required:
    - name: status
      type: string
      description: Result status - success, partial, not_git_repo, or error
    - name: project_name
      type: string
    - name: kb_path
      type: string
  optional:
    - name: documents_generated
      type: number
    - name: documents_updated
      type: number
    - name: documents_skipped
      type: number
    - name: stats
      type: object
    - name: error
      type: string
pre_checks:
  - validation: project_root is not empty
  - validation: mode in ["full", "incremental", "refresh-stale"]
post_checks:
  - validation: status is not empty
  - validation: if status is success then kb_path is returned
cacheable: false
---

# kb-generation Skill

Generates Obsidian-compatible KB docs from project source code.

## Protocol Summary

```
1. kb-identity → project_name, kb_path
2. Analyze project → modules, services, deps, edges
3. Generate docs → README, architecture, modules/*, services/*, deps, graph.json
4. Update meta → manifest.json, identity.json
5. Update Home.md
```

## Step 1: Identity

Invoke `kb-identity(project_root)` → Returns `project_name`, `kb_path`, `identity_hash`.

## Step 2: Mode Behavior

| Mode | Behavior |
|------|----------|
| `full` | Clear existing docs (except `.meta/identity.json`), regenerate all |
| `incremental` | Compare source + manifest file hashes AND detect generator drift (agent/skill/template/schema version changes), fill missing docs, regenerate drifted docs, refresh `.obsidian/graph.json` if the color contract changed. Idempotent when nothing is drifted. |
| `refresh-stale` | Check frontmatter `stale: true`, regenerate those docs |

`incremental` runs Step 3.6 ("Detect generator drift") before Step 3 so it can fill gaps (missing required docs, missing per-entity docs, schema drift, template drift, skill drift, agent-version drift) in addition to responding to source-file changes.

## Step 3: Analyze Project

### Files to Read

| Category | Files |
|----------|-------|
| Package manifests | `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json` |
| Workspace manifests | `pnpm-workspace.yaml`, `go.work`, `Cargo.toml` `[workspace]`, `lerna.json`, `turbo.json`, `nx.json`, `package.json` `workspaces` |
| Service manifests | `docker-compose.yml`, `compose.yaml`, `docker-compose.*.yml`, `Dockerfile*` |
| Kubernetes | `k8s/**/*.yaml`, `deploy/**/*.yaml`, `charts/**/templates/*.yaml`, `manifests/**/*.yaml` |
| Process managers | `Procfile`, `supervisord.conf`, `systemd/*.service` |
| CI inference | `.github/workflows/*.yml`, `.gitlab-ci.yml` |
| Protocol definitions | `**/*.proto` |
| Config | `tsconfig.json`, `.eslintrc`, `.env`, `.env.*` |
| Entry points | `index.*`, `main.*`, `app.*`, `mod.rs`, `__init__.py`, `cmd/*/main.*`, `apps/*/`, `services/*/` |

### Skip

`node_modules/`, `vendor/`, `.git/`, `build/`, `dist/`, `target/`, `__pycache__/`, lock files, generated files, binaries, tests (for Phase 2 deep-read).

### Extract

- **Modules**: Directories with index/entry files → name, path, exports, imports
- **Services**: priority-ordered multi-source detection (see table below). Dedup by directory path relative to repo root. Merge duplicates into one node; record all sources in `discovery_sources[]`. Name precedence: compose service key > k8s `metadata.name` > directory basename.
- **Datastores**: Databases, caches, brokers referenced by any service (compose images like `postgres`/`mysql`/`redis`/`mongo`/`kafka`, env vars matching `*_DSN`/`*_DB_*`/`*_DATABASE_URL`). Emit as `datastore` nodes with their own docs.
- **Dependencies**: From manifest → name, version, type (prod/dev/peer)
- **Edges** (intra-code): Import statements → source, target, relation, confidence
- **Inter-Service Dependencies**: See extraction rules below.

### Service Discovery — Priority-Ordered Sources

Detect services from these sources in this order; merge duplicates by directory path.

| Priority | Source | Files | Yields | Confidence |
|----------|--------|-------|--------|------------|
| P1 | Compose | `docker-compose.yml`, `compose.yaml`, `docker-compose.*.yml` | YAML `services:` keys, image, ports, `depends_on`, networks, environment | EXTRACTED |
| P2 | Kubernetes | `k8s/**/*.yaml`, `deploy/**/*.yaml`, `charts/**/templates/*.yaml`, `manifests/**/*.yaml` | `kind: Deployment\|StatefulSet\|Service`, `.metadata.name`, container ports, service refs | EXTRACTED |
| P3 | Workspace manifests | `pnpm-workspace.yaml` (`packages`), `package.json` (`workspaces`), `go.work` (`use`), `Cargo.toml` (`[workspace] members`), `lerna.json`/`turbo.json`/`nx.json` | Workspace member paths | EXTRACTED |
| P4 | Convention dirs | `cmd/*/main.go`, `cmd/*/main.rs`, `apps/*/`, `services/*/` | Service name from directory basename | INFERRED |
| P5 | Process managers | `Procfile`, `supervisord.conf`, `systemd/*.service` | Process names, commands | EXTRACTED |
| P6 | CI inference | `.github/workflows/*.yml`, `.gitlab-ci.yml` matrix/job names | Service-like job names | INFERRED (weak) |
| P7 | Dockerfile fallback | `**/Dockerfile*` with `EXPOSE`/`ENTRYPOINT`/`CMD` | Service from containing directory | INFERRED |

Canonical dedup key = directory path relative to repo root. Merge into one node; record every source in `discovery_sources[]` (array of priority labels like `"compose"`, `"k8s"`, `"dockerfile"`).

### Inter-Service Dependencies

Extract edges between detected services and datastores using these rules:

| Source | Signal | Edge | Confidence |
|--------|--------|------|------------|
| Compose | `depends_on` | `invokes` | EXTRACTED |
| Compose | Shared non-default `networks` | (informational only, no edge) | — |
| Env vars | `*_URL`, `*_HOST`, `*_ENDPOINT`, `*_ADDR` in Dockerfile `ENV`, compose `environment`, `.env` | `invokes` | INFERRED |
| Kubernetes | Ingress `serviceName`, `svc.cluster.local` refs in env | `invokes` | EXTRACTED |
| Protobuf | `.proto` `import` / `service` definitions | `invokes` | EXTRACTED |
| Messaging | Kafka topic patterns (`producer.send("topic")`, `@KafkaListener(topics=...)`, consumer group configs) | `publishes_to` / `subscribes_to` | INFERRED |
| Datastore | DB connection strings (`*_DB_*`, `*_DSN`, `*_DATABASE_URL`), compose images (`postgres`/`mysql`/`redis`/`mongo`) | `shares_datastore` | INFERRED |

Edges surface in:
- `graph.json` — canonical.
- `services/<name>.md` — "Upstream Dependencies" + "Downstream Dependents" sections (max 5 lines each).
- `dependencies.md` — "Inter-Service Dependencies" section (table + mermaid topology).
- `services/_index.md` — topology mermaid diagram.

## Step 3.5: Two-Phase Discovery

To keep monorepo analysis bounded, split discovery into two phases.

**Phase 1 — Manifest scan (~<2000 tokens for large monorepos).**

- Glob and read only small declarative files: compose, k8s, workspace manifests, Procfile, CI workflows, proto files.
- Extract service names, ports, container images, inter-service edges, datastore refs.
- Build a preliminary node/edge map. No source reads yet.

**Phase 2 — Targeted deep-read (per identified service).**

- For each service from Phase 1, read at most:
  - The service's entry point (`main.*`, `index.*`, etc.)
  - Its router / handler registration file (if any)
  - A service-local `README.md` (if present)
- Skip: tests, vendor, generated files, internal implementation details.
- **Cap ~400 tokens of extracted source content per `services/<name>.md`.**

**Budget caps:**

| Output | Cap |
|--------|-----|
| `services/_index.md` | ~300 tokens |
| `services/<name>.md` | ~400 tokens of extracted source content |
| Total service discovery reads (10+ service monorepo) | ~5000 tokens |
| `dependencies.md` — Inter-Service Dependencies section | ~200 tokens |
| `datastores/<name>.md` | ~400 tokens |

**Incremental manifest hashing.** Add `manifests` map to `.meta/manifest.json` (path → `{ sha256, last_analyzed }`). In `incremental` mode, if all Phase-1 manifest hashes are unchanged, skip Phase 1 entirely and only re-read services whose source directories changed.

## Step 3.6: Detect Generator Drift

Run at the start of every `incremental` pass, before Step 3 proper. Produces a gap list consumed by Step 4.

1. Load `.meta/manifest.json`; read the `generator` block (see Step 6).
2. Compare against the current runtime versions:
   - `kb_engineer_version` vs the current kb-engineer agent version.
   - `skill_versions.*` vs each skill's `version:` frontmatter.
   - `schema_versions.*` vs the version declared in `_schema/*.schema.json`.
   - `template_hashes[*]` vs the sha256 of each current template file.
3. Compute the gap list:
   - **Missing required docs** — any of `{project}.md`, `architecture.md`, `dependencies.md`, `modules/_index.md`, `graph.json` absent → regenerate.
   - **Missing per-entity docs** — for every graph.json node of type `module`/`service`/`datastore`, ensure the corresponding `modules/<name>.md` / `services/<name>.md` / `datastores/<name>.md` exists. Missing → regenerate that one.
   - **Schema drift** — `schema_versions.*` < current → re-validate all docs; regenerate ones that fail (e.g. missing new frontmatter fields, missing new graph edge types).
   - **Template drift** — any `template_hashes[*]` differs from the current file hash → mark docs generated from that template as stale and regenerate.
   - **Skill drift** — any `skill_versions.*` < current → rerun the affected step (new `kb-generation` → redo discovery + graph build; new `kb-query` does not force regen).
   - **Agent drift** — `kb_engineer_version` differs → run all checks above, then update the stored version on success.
4. Merge the gap list with the source-hash delta from Step 3. Both drive Step 4.

Gap-fill is **additive**: it regenerates only what's missing or drifted, preserves unchanged docs, is bounded by the same per-doc token caps as normal generation, and is idempotent — rerunning with no drift produces no writes.

## Step 4: Generate Documents

Use templates from `~/.cursor/docs/knowledge-base/templates/`.

**IMPORTANT:** The main project file is named `{project_name}.md` (NOT README.md) so it appears as the project name in Obsidian's graph.

| Document | Template | Content |
|----------|----------|---------|
| `{project_name}.md` | `project-readme.md` | Overview, tech stack, module/service links, stats |
| `architecture.md` | `architecture-doc.md` | System diagram, layers, boundaries |
| `dependencies.md` | `dependencies-doc.md` | Dep table, graph, security notes |
| `modules/_index.md` | `modules-index.md` | Module inventory, dependency matrix |
| `modules/<name>.md` | `module-doc.md` | Purpose, API, deps, dependents |
| `services/_index.md` | `services-index.md` | Service inventory + topology table + mermaid `flowchart LR` derived from graph.json |
| `services/<name>.md` | `service-doc.md` | Purpose, endpoints, deployment, Upstream Dependencies, Downstream Dependents |
| `datastores/_index.md` | `datastores-index.md` | Datastore inventory + consumer graph |
| `datastores/<name>.md` | `datastore-doc.md` | Purpose (db/cache/broker), image/version, consumers, topics/tables/keys, connection source |
| `graph.json` | (schema) | Nodes + edges for programmatic queries |

Every `datastore` graph node must have `kb_doc: "datastores/<name>.md"` pointing to its generated file.

### Template Variables

Fill templates with: `{{project_name}}`, `{{timestamp}}`, `{{confidence}}`, `{{module_nodes}}`, `{{service_nodes}}`, etc.

## Step 5: Build graph.json

```json
{
  "version": 1,
  "project": "<name>",
  "generated_at": "<ISO8601>",
  "nodes": [
    {
      "id": "",
      "label": "",
      "type": "module|service|datastore|external_dep|config|function|class",
      "kb_doc": "",
      "discovery_sources": ["compose", "k8s", "workspace", "convention", "procfile", "ci", "dockerfile"],
      "port": 0,
      "protocol": ""
    }
  ],
  "edges": [
    {
      "source": "",
      "target": "",
      "relation": "imports|depends_on|calls|exposes|configures|extends|implements|invokes|subscribes_to|publishes_to|shares_datastore",
      "confidence": "EXTRACTED|INFERRED"
    }
  ]
}
```

- `discovery_sources`, `port`, `protocol` are **optional** on nodes; emit them only when detected.
- Every `datastore` node MUST have `kb_doc` pointing to its `datastores/<name>.md` file.
- Validate against `_schema/graph.schema.json`.

## Step 6: Update Manifest

**Location (authoritative).** `.meta/manifest.json` lives under the KB, NOT the target project repo:

```
~/.cursor/docs/knowledge-base/projects/<project_name>/.meta/manifest.json
```

The target project repo is read-only input to kb-engineer. The KB folder is the only write surface. Same rule applies to `.meta/identity.json` and `.meta/generation-log.json`.

Write to `.meta/manifest.json`:

```json
{
  "version": 1,
  "project": "<name>",
  "generated_at": "<ISO8601>",
  "files": {
    "<path>": { "sha256": "<hash>", "last_analyzed": "<ISO8601>", "contributed_to": ["{project}.md"] }
  },
  "manifests": {
    "docker-compose.yml": { "sha256": "<hash>", "last_analyzed": "<ISO8601>" },
    "k8s/deployment.yaml": { "sha256": "<hash>", "last_analyzed": "<ISO8601>" }
  },
  "generator": {
    "kb_engineer_version": "<semver or short hash>",
    "skill_versions": {
      "kb-generation": 1,
      "kb-query": 1,
      "kb-identity": 1
    },
    "schema_versions": {
      "graph": 1,
      "frontmatter": 1,
      "manifest": 1
    },
    "template_hashes": {
      "project-readme.md": "<sha256>",
      "module-doc.md": "<sha256>",
      "service-doc.md": "<sha256>",
      "datastore-doc.md": "<sha256>",
      "architecture-doc.md": "<sha256>",
      "dependencies-doc.md": "<sha256>",
      "modules-index.md": "<sha256>",
      "services-index.md": "<sha256>",
      "datastores-index.md": "<sha256>",
      "home.md": "<sha256>"
    }
  }
}
```

- `files` — per-source-file hashes used by incremental mode (unchanged behavior).
- `manifests` — per-manifest-file hashes (compose / k8s / workspace / Procfile). Used to skip Phase-1 service re-discovery when all entries are unchanged.
- `generator` — versions + template hashes used by Step 3.6 drift detection. Refreshed on every successful generation.

## Step 7: Update Home.md

**MANDATORY** — Update `~/.cursor/docs/knowledge-base/Home.md` after every generation.

1. If missing, create from `templates/home.md`
2. Update project row in Projects table
3. Refresh statistics
4. Update recently updated list

## Step 7.5: Write/Merge Vault `.obsidian/graph.json`

**Location:** `~/.cursor/docs/knowledge-base/.obsidian/graph.json` — one per vault, not per project. Run on `full`, `incremental`, and `refresh-stale` modes.

**Merge semantics (merge-by-key):**

- If the file is absent → write the full block below.
- If the file exists → overwrite only these authoritative keys: `search`, `showTags`, `showAttachments`, `showOrphans`, `colorGroups`. Preserve every other key the user may have added (e.g. `nodeSize`, `lineSize`, `scale`, `centerStrength`).
- `colorGroups` is replaced wholesale (7 entries, Section D palette), never merged entry-by-entry — the 7-entry contract is authoritative.

**Full authoritative block:**

```json
{
  "collapse-filter": false,
  "search": "-path:templates -path:_schema -path:.meta -file:_index",
  "showTags": false,
  "showAttachments": false,
  "showOrphans": false,
  "collapse-color-groups": false,
  "colorGroups": [
    { "query": "tag:#kb/type/hub",       "color": { "a": 1, "rgb": 4886233 } },
    { "query": "tag:#kb/type/service",   "color": { "a": 1, "rgb": 16636981 } },
    { "query": "tag:#kb/type/module",    "color": { "a": 1, "rgb": 8172354 } },
    { "query": "tag:#kb/type/datastore", "color": { "a": 1, "rgb": 15021365 } },
    { "query": "tag:#kb/type/arch",      "color": { "a": 1, "rgb": 16750848 } },
    { "query": "tag:#kb/type/deps",      "color": { "a": 1, "rgb": 10233520 } },
    { "query": "tag:#kb/type/home",      "color": { "a": 1, "rgb": 48340 } }
  ]
}
```

rgb integers encode as `(r << 16) | (g << 8) | b`, matching Obsidian's storage format. All values < `0x7FFFFFFF` so signed/unsigned reads are identical.

Search filter `-path:templates -path:_schema -path:.meta -file:_index` enforces the content-nodes-only principle (Step D of the contract). Combined with `showAttachments: false` and `showOrphans: false`, the Obsidian graph shows only documents a human would click into.

## Backlink Rules (Star Topology)

All docs link **TO** `{project_name}.md` (hub). Hub links **OUT** to all children.

**IMPORTANT:** Hub file is named `{project_name}.md` so it shows as the project name in Obsidian's graph.

| Document | Must Link To |
|----------|-------------|
| All non-hub docs | `[[{project_name}\|{project_name}]]` (REQUIRED) |
| `{project_name}.md` (hub) | All modules, services, architecture, deps, connected projects |
| Module/Service | Hub + related siblings + cross-project deps |

### Cross-Project Links

| Type | Syntax |
|------|--------|
| Hub-to-hub | `[[../other-project/other-project\|other-project]]` |
| Module-to-module | `[[../other-project/modules/api\|Other API]]` |

## Incremental Algorithm

```
1. Read manifest.json
2. For each source file:
   - New → analyze, add to manifest
   - Changed hash → analyze, mark contributed_to docs stale
   - Deleted → remove from manifest, mark docs stale
   - Unchanged → skip
3. Regenerate stale docs
4. Update manifest
```

## Error Handling

| Condition | Behavior |
|-----------|----------|
| kb-identity fails | Return error immediately |
| Cannot read file | Skip, continue, log |
| Corrupted manifest | Regenerate from scratch |
| Missing template | Use inline default |
| Schema validation fails | Log warning, write anyway |

## Output

```json
{
  "status": "success",
  "project_name": "myapp",
  "kb_path": "~/.cursor/docs/knowledge-base/projects/myapp/",
  "documents_generated": 12,
  "stats": { "modules": 5, "services": 2, "dependencies": 23, "edges": 47 }
}
```
