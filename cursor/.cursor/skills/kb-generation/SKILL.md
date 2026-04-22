---
name: kb-generation
description: Core generation protocol for Knowledge Base documents. Analyzes project structure, canonicalizes datastores (shared at vault level vs project-owned), enforces atomic write guards against empty/duplicate files, generates Obsidian-compatible markdown with mermaid diagrams, builds relationship graphs with fine-grained cross-project edges (no hub-to-hub), and tracks manifests for incremental updates.
version: 2
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

| Mode            | Behavior                                                                                                                                                                                                                                                      |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `full`          | Clear existing docs (except `.meta/identity.json`), regenerate all                                                                                                                                                                                            |
| `incremental`   | Compare source + manifest file hashes AND detect generator drift (agent/skill/template/schema version changes), fill missing docs, regenerate drifted docs, refresh `.obsidian/graph.json` if the color contract changed. Idempotent when nothing is drifted. |
| `refresh-stale` | Check frontmatter `stale: true`, regenerate those docs                                                                                                                                                                                                        |

`incremental` runs Step 3.6 ("Detect generator drift") before Step 3 so it can fill gaps (missing required docs, missing per-entity docs, schema drift, template drift, skill drift, agent-version drift) in addition to responding to source-file changes.

## Step 3: Analyze Project

### Files to Read

| Category             | Files                                                                                                                            |
| -------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| Package manifests    | `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`                  |
| Workspace manifests  | `pnpm-workspace.yaml`, `go.work`, `Cargo.toml` `[workspace]`, `lerna.json`, `turbo.json`, `nx.json`, `package.json` `workspaces` |
| Service manifests    | `docker-compose.yml`, `compose.yaml`, `docker-compose.*.yml`, `Dockerfile*`                                                      |
| Kubernetes           | `k8s/**/*.yaml`, `deploy/**/*.yaml`, `charts/**/templates/*.yaml`, `manifests/**/*.yaml`                                         |
| Process managers     | `Procfile`, `supervisord.conf`, `systemd/*.service`                                                                              |
| CI inference         | `.github/workflows/*.yml`, `.gitlab-ci.yml`                                                                                      |
| Protocol definitions | `**/*.proto`                                                                                                                     |
| Config               | `tsconfig.json`, `.eslintrc`, `.env`, `.env.*`                                                                                   |
| Entry points         | `index.*`, `main.*`, `app.*`, `mod.rs`, `__init__.py`, `cmd/*/main.*`, `apps/*/`, `services/*/`                                  |

### Skip

`node_modules/`, `vendor/`, `.git/`, `build/`, `dist/`, `target/`, `__pycache__/`, lock files, generated files, binaries, tests (for Phase 2 deep-read).

### Extract

- **Modules**: Directories with index/entry files → name, path, exports, imports
- **Services**: priority-ordered multi-source detection (see table below). Dedup by directory path relative to repo root. Merge duplicates into one node; record all sources in `discovery_sources[]`. Name precedence: compose service key > k8s `metadata.name` > directory basename.
- **Datastores**: Databases, caches, brokers, queues, search engines referenced by any service. Sources: compose images (`postgres`/`mysql`/`redis`/`mongo`/`kafka`/`rabbitmq`/`elasticsearch`/etc.), env vars matching `*_DSN`/`*_DB_*`/`*_DATABASE_URL`/`*_HOST`/`*_BROKER`, k8s StatefulSet/Deployment names, `.proto` service references. **Must canonicalize + classify** (see Step 3.7 below) — two refs that normalize to the same ID are ONE datastore, ONE node, ONE file.
- **Dependencies**: From manifest → name, version, type (prod/dev/peer)
- **Edges** (intra-code): Import statements → source, target, relation, confidence
- **Inter-Service Dependencies**: See extraction rules below. Cross-project edges must resolve to service/module level — never hub-to-hub.

### Service Discovery — Priority-Ordered Sources

Detect services from these sources in this order; merge duplicates by directory path.

| Priority | Source              | Files                                                                                                                                                           | Yields                                                                                    | Confidence      |
| -------- | ------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------- | --------------- |
| P1       | Compose             | `docker-compose.yml`, `compose.yaml`, `docker-compose.*.yml`                                                                                                    | YAML `services:` keys, image, ports, `depends_on`, networks, environment                  | EXTRACTED       |
| P2       | Kubernetes          | `k8s/**/*.yaml`, `deploy/**/*.yaml`, `charts/**/templates/*.yaml`, `manifests/**/*.yaml`                                                                        | `kind: Deployment\|StatefulSet\|Service`, `.metadata.name`, container ports, service refs | EXTRACTED       |
| P3       | Workspace manifests | `pnpm-workspace.yaml` (`packages`), `package.json` (`workspaces`), `go.work` (`use`), `Cargo.toml` (`[workspace] members`), `lerna.json`/`turbo.json`/`nx.json` | Workspace member paths                                                                    | EXTRACTED       |
| P4       | Convention dirs     | `cmd/*/main.go`, `cmd/*/main.rs`, `apps/*/`, `services/*/`                                                                                                      | Service name from directory basename                                                      | INFERRED        |
| P5       | Process managers    | `Procfile`, `supervisord.conf`, `systemd/*.service`                                                                                                             | Process names, commands                                                                   | EXTRACTED       |
| P6       | CI inference        | `.github/workflows/*.yml`, `.gitlab-ci.yml` matrix/job names                                                                                                    | Service-like job names                                                                    | INFERRED (weak) |
| P7       | Dockerfile fallback | `**/Dockerfile*` with `EXPOSE`/`ENTRYPOINT`/`CMD`                                                                                                               | Service from containing directory                                                         | INFERRED        |

Canonical dedup key = directory path relative to repo root. Merge into one node; record every source in `discovery_sources[]` (array of priority labels like `"compose"`, `"k8s"`, `"dockerfile"`).

### Inter-Service Dependencies

Extract edges between detected services and datastores using these rules:

| Source     | Signal                                                                                                           | Edge                             | Confidence |
| ---------- | ---------------------------------------------------------------------------------------------------------------- | -------------------------------- | ---------- |
| Compose    | `depends_on`                                                                                                     | `invokes`                        | EXTRACTED  |
| Compose    | Shared non-default `networks`                                                                                    | (informational only, no edge)    | —          |
| Env vars   | `*_URL`, `*_HOST`, `*_ENDPOINT`, `*_ADDR` in Dockerfile `ENV`, compose `environment`, `.env`                     | `invokes`                        | INFERRED   |
| Kubernetes | Ingress `serviceName`, `svc.cluster.local` refs in env                                                           | `invokes`                        | EXTRACTED  |
| Protobuf   | `.proto` `import` / `service` definitions                                                                        | `invokes`                        | EXTRACTED  |
| Messaging  | Kafka topic patterns (`producer.send("topic")`, `@KafkaListener(topics=...)`, consumer group configs)            | `publishes_to` / `subscribes_to` | INFERRED   |
| Datastore  | DB connection strings (`*_DB_*`, `*_DSN`, `*_DATABASE_URL`), compose images (`postgres`/`mysql`/`redis`/`mongo`) | `shares_datastore`               | INFERRED   |

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

| Output                                                 | Cap                                     |
| ------------------------------------------------------ | --------------------------------------- |
| `services/_index.md`                                   | ~300 tokens                             |
| `services/<name>.md`                                   | ~400 tokens of extracted source content |
| Total service discovery reads (10+ service monorepo)   | ~5000 tokens                            |
| `dependencies.md` — Inter-Service Dependencies section | ~200 tokens                             |
| `datastores/<name>.md`                                 | ~400 tokens                             |

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

## Step 3.7: Datastore Canonicalization & Classification

Every datastore reference collected in Step 3 passes through canonicalization BEFORE any write decision. This step is the source of truth for dedup and for the shared-vs-project scope split. See `agents/kb-engineer.md` Section 5 for the authoritative rules and alias map; this skill implements them.

**3.7.1 Canonicalize.**

For each raw datastore ref (image name, env var host, k8s StatefulSet name, `.proto` service, code literal):

1. Lowercase.
2. Strip trailing digits and `-N` index suffixes (`kafka-01` → `kafka`, `redis-0` → `redis`).
3. Strip infrastructure suffixes: `-broker`, `-brokers`, `-cluster`, `-primary`, `-replica`, `-readonly`, `-master`, `-slave`, `-leader`, `-follower`.
4. Look up in the alias map (agent Section 5). If found, replace with canonical key.
5. If name has a purpose-scoped prefix that is not a vendor string (e.g. `auth-db`, `cart-cache`, `session-store`, `orders-redis`), preserve it — this is a project-owned datastore and the prefix is its identity. Otherwise use the bare canonical (`postgres`, `redis`, `kafka`).

Result: one canonical ID per real datastore, stable across discovery sources.

**3.7.2 Build dedup table.**

Maintain `{canonical_id → { consumers: Set<(project, service)>, raw_refs: [], images: [], env_keys: [] }}` in memory for the whole generation pass. Every ref updates the same entry. At the end of Step 3, iterate this table once to decide scope and target file path — do NOT write inside the loop.

**3.7.3 Classify.**

Apply the rules in order (first match wins):

| #   | Rule                                                                                                                             | Scope                                 |
| --- | -------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| 1   | Canonical ID ∈ {`kafka`, `rabbitmq`, `nats`, `zookeeper`, `etcd`, `consul`, `vault`, `elasticsearch`, `clickhouse`, `cassandra`} | `shared`                              |
| 2   | `consumers` span ≥2 distinct projects                                                                                            | `shared`                              |
| 3   | `consumers` span ≥2 services inside one project AND canonical ID is a bare vendor name (`postgres`/`redis`/`mysql`/`mongo`)      | `shared`                              |
| 4   | Canonical ID has a purpose-scoped prefix AND has exactly one consumer                                                            | `project`                             |
| 5   | Fallback                                                                                                                         | `project` (to the sole/first project) |

**3.7.4 Resolve target path.**

| Scope     | Path                                                                                   |
| --------- | -------------------------------------------------------------------------------------- |
| `shared`  | `~/.cursor/docs/knowledge-base/datastores/<canonical_id>.md`                           |
| `project` | `~/.cursor/docs/knowledge-base/projects/<owning_project>/datastores/<canonical_id>.md` |

Record the resolved path as the `kb_doc` field on every `datastore` node in graph.json, and also on the corresponding node in the vault-level cross-project graph index (if one exists). The node's `scope` field matches.

**3.7.5 Promotion / demotion on incremental runs.**

Compare today's classification vs the one persisted in `.meta/manifest.json` under `datastore_classifications`:

- Was `project` → now `shared`: move file to vault-level, rewrite backlinks in every consumer doc, delete the old file, update both graph.jsons.
- Was `shared` → now `project`: move file under the owning project, same rewrites.
- No change: no-op.

Promotion/demotion is idempotent — running twice produces the same result.

## Step 3.8: Orphan & Stub Sweep (incremental + refresh-stale)

Run at the very start of `incremental` and `refresh-stale` modes, before Step 3 proper.

1. Walk every `.md` under `~/.cursor/docs/knowledge-base/` except `_schema/`, `templates/`, `.meta/`.
2. For each file, load frontmatter + body. Apply the minimum-content threshold (below).
3. Files that fail are stubs from crashed/partial runs. Delete them. Remove any `[[<file>]]` backlinks pointing at the deleted path from other docs. Remove the node from all `graph.json` files.
4. Canonicalize each remaining datastore file's filename vs its canonical ID. If a file's filename doesn't match its canonical ID (e.g. `kafka-broker.md` still on disk), either rename (if no conflict) or delete the duplicate (if the canonical file already exists and is populated).
5. If two files on disk canonicalize to the same ID, keep the one with longer populated body; delete the other. Rewrite backlinks to point at the kept file.

**Minimum-content threshold (per doc type):**

| Doc                    | Required sections                                                | Min body length |
| ---------------------- | ---------------------------------------------------------------- | --------------- |
| `{project}.md`         | Overview, Tech Stack, (Modules OR Services), Related             | 400 chars       |
| `architecture.md`      | Overview, ≥1 mermaid diagram, Module OR Service boundaries       | 400 chars       |
| `dependencies.md`      | Overview, Dep table ≥1 row OR Inter-Service Dependencies section | 200 chars       |
| `modules/<name>.md`    | Purpose, (Public API OR Key files)                               | 200 chars       |
| `services/<name>.md`   | Purpose, (API endpoints OR Configuration)                        | 200 chars       |
| `datastores/<name>.md` | Purpose, Consuming Services (≥1 backlink)                        | 200 chars       |

The sweep is cheap and idempotent. Running it twice produces no further changes.

## Step 3.9: Atomic Write Guards

Every `.md` write MUST use this pattern. The skill does NOT write directly to disk mid-generation.

1. Compute full target path (datastore path resolved by Step 3.7.4).
2. Buffer the full rendered content in memory.
3. Apply the Step 3.8 minimum-content threshold to the buffered content.
   - **Fail → SKIP the write entirely.** Log a warning with the doc path and the missing sections. Do NOT write an empty or stub file.
4. If an existing file is present at the path:
   - Existing is a stub (fails threshold) → overwrite.
   - Existing is populated AND new content is also populated → overwrite.
   - Existing is populated AND new content FAILS threshold → **keep existing**, log the skip.
5. Write the `.md` file AND append/update its hash in `.meta/manifest.json.files` in the same logical transaction.

This is the fix for the bug where kafka.md was written three times with two empty stubs: canonicalize (Step 3.7.1) collapses to one ID, the dedup table (Step 3.7.2) collects all sources, the threshold check (Step 3.9.3) ensures only populated content reaches disk.

## Step 4: Generate Documents

Use templates from `~/.cursor/docs/knowledge-base/templates/`.

**IMPORTANT:** The main project file is named `{project_name}.md` (NOT README.md) so it appears as the project name in Obsidian's graph.

| Document                                 | Template              | Content                                                                                                                                                                                                |
| ---------------------------------------- | --------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `{project_name}.md`                      | `project-readme.md`   | Overview, tech stack, module/service links, stats, shared-datastore-used section                                                                                                                       |
| `architecture.md`                        | `architecture-doc.md` | System diagram, layers, boundaries                                                                                                                                                                     |
| `dependencies.md`                        | `dependencies-doc.md` | Dep table, graph, security notes, Inter-Service Dependencies                                                                                                                                           |
| `modules/_index.md`                      | `modules-index.md`    | Module inventory, dependency matrix                                                                                                                                                                    |
| `modules/<name>.md`                      | `module-doc.md`       | Purpose, API, deps, dependents                                                                                                                                                                         |
| `services/_index.md`                     | `services-index.md`   | Service inventory + topology table + mermaid `flowchart LR` derived from graph.json                                                                                                                    |
| `services/<name>.md`                     | `service-doc.md`      | Purpose, endpoints, deployment, Upstream Dependencies, Downstream Dependents, Datastores used (backlinks to project-owned + shared)                                                                    |
| `projects/<name>/datastores/_index.md`   | `datastores-index.md` | **Project-owned** datastore inventory only                                                                                                                                                             |
| `projects/<name>/datastores/<name>.md`   | `datastore-doc.md`    | Project-owned micro datastore. `scope: project`. Purpose, image/version, consumers (within project), topics/tables/keys, connection source                                                             |
| **`datastores/<name>.md`** (vault-level) | `datastore-doc.md`    | **Shared** datastore. `scope: shared`. Purpose, image/version, consumers across all projects (cross-project table), topics/tables/keys, ownership. Lives at VAULT ROOT, not inside any project folder. |
| `graph.json`                             | (schema)              | Nodes + edges for programmatic queries                                                                                                                                                                 |

Every `datastore` graph node MUST include:

- `scope`: `"shared"` or `"project"` (from Step 3.7.3 classification)
- `kb_doc`: the resolved path from Step 3.7.4 (vault-level `datastores/<name>.md` for shared, or `projects/<name>/datastores/<name>.md` for project-owned)

Cross-project edges in `graph.json` must use service-level or module-level source/target IDs, never project-hub IDs. The edge `source`/`target` encode as `<project>/<service|module>/<name>` so the reader can tell which project and which granularity.

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
      "discovery_sources": [
        "compose",
        "k8s",
        "workspace",
        "convention",
        "procfile",
        "ci",
        "dockerfile"
      ],
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
    "<path>": {
      "sha256": "<hash>",
      "last_analyzed": "<ISO8601>",
      "contributed_to": ["{project}.md"]
    }
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

**MANDATORY** — Update `~/.cursor/docs/knowledge-base/Home.md` after every generation. Home.md is hidden from the graph view (via `-file:Home` in the search filter) but remains the primary navigation page for humans browsing the vault's file tree.

1. If missing, create from `templates/home.md`.
2. Update project row in Projects table.
3. **Update shared-datastore listing.** Section `## Shared Infrastructure` lists every file under vault-level `datastores/` with a link, its `scope: shared` tag, and its consumer count. Add/remove rows as promotions/demotions happen.
4. Refresh statistics (project count, shared datastore count, total modules/services across vault).
5. Update recently updated list.

Home.md must have frontmatter tags `kb`, `kb/type/home`. It still carries the `kb/type/home` tag even though no color group references it — the tag remains useful for Obsidian's file-search and for tag-based queries outside the graph.

## Step 7.5: Write/Merge Vault `.obsidian/graph.json`

**Location:** `~/.cursor/docs/knowledge-base/.obsidian/graph.json` — one per vault, not per project. Run on `full`, `incremental`, and `refresh-stale` modes.

**Merge semantics (merge-by-key):**

- If the file is absent → write the full block below.
- If the file exists → overwrite only these authoritative keys: `search`, `showTags`, `showAttachments`, `showOrphans`, `colorGroups`. Preserve every other key the user may have added (e.g. `nodeSize`, `lineSize`, `scale`, `centerStrength`).
- `colorGroups` is replaced wholesale (6 entries, Section D palette), never merged entry-by-entry — the 6-entry contract is authoritative.

**Full authoritative block:**

```json
{
  "collapse-filter": false,
  "search": "-path:templates -path:_schema -path:.meta -file:_index -file:Home",
  "showTags": false,
  "showAttachments": false,
  "showOrphans": false,
  "collapse-color-groups": false,
  "colorGroups": [
    { "query": "tag:#kb/type/hub", "color": { "a": 1, "rgb": 4886233 } },
    { "query": "tag:#kb/type/service", "color": { "a": 1, "rgb": 16636981 } },
    { "query": "tag:#kb/type/module", "color": { "a": 1, "rgb": 8172354 } },
    { "query": "tag:#kb/type/datastore", "color": { "a": 1, "rgb": 15021365 } },
    { "query": "tag:#kb/type/arch", "color": { "a": 1, "rgb": 16750848 } },
    { "query": "tag:#kb/type/deps", "color": { "a": 1, "rgb": 10233520 } }
  ]
}
```

rgb integers encode as `(r << 16) | (g << 8) | b`, matching Obsidian's storage format. All values < `0x7FFFFFFF` so signed/unsigned reads are identical.

Search filter `-path:templates -path:_schema -path:.meta -file:_index -file:Home` enforces the content-nodes-only principle (including hiding `Home.md`, which is a navigation scaffold, not a concept). Combined with `showAttachments: false` and `showOrphans: false`, the Obsidian graph shows only documents a human would click into.

The previous `kb/type/home` color group is removed because the node it would color is hidden by the search filter — defining a color for an invisible node just creates contract drift.

## Backlink Rules (Star Topology + Shared Infrastructure)

All per-project docs link **TO** `{project_name}.md` (hub). The hub links **OUT** to all its children AND to every shared datastore the project consumes. Cross-project connectivity is fine-grained: service↔service, module↔module, or via vault-level shared datastores. **Hub-to-hub cross-project links are forbidden.**

**IMPORTANT:** Hub file is named `{project_name}.md` so it shows as the project name in Obsidian's graph.

| Document                               | Must Link To                                                                                                                                        |
| -------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| All non-hub project docs               | `[[{project_name}\|{project_name}]]` (REQUIRED)                                                                                                     |
| `{project_name}.md` (hub)              | All own modules, services, architecture, deps, own (project-owned) datastores, every shared datastore the project uses. **NOT** other project hubs. |
| Module                                 | Hub + related siblings + (for cross-project) specific modules in other projects                                                                     |
| Service                                | Hub + related siblings + (for cross-project) specific services in other projects + datastores consumed (project-owned + shared)                     |
| Project-owned datastore doc            | Hub + consuming services within project                                                                                                             |
| **Shared datastore doc (vault-level)** | Every consuming service/module across every project (full cross-project consumer list)                                                              |

### Cross-Project Links (fine-grained only)

| Type                    | Syntax                                                                | When to use                                                  |
| ----------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| Service-to-service      | `[[../other-project/services/worker\|other-project: worker]]`         | Service in project A invokes service in project B            |
| Module-to-module        | `[[../other-project/modules/api\|other-project: API]]`                | Module in project A imports module in project B              |
| Any-to-shared-datastore | `[[../../datastores/kafka\|kafka]]`                                   | Any project's service/module/hub consumes a shared datastore |
| Hub → shared datastore  | `[[../../datastores/postgres-main\|postgres-main]]`                   | Project hub lists its shared infrastructure usage            |
| Hub → other project hub | **FORBIDDEN** — use service-level or module-level cross-links instead | —                                                            |

### Datastore Backlink Directionality

- **Shared datastore doc** (vault-level): lists every `consumer` with a backlink of the form `[[../projects/<name>/services/<svc>|<name>: <svc>]]`. The doc's own inbound links are `projects/<name>/services/<svc>.md` or `projects/<name>/<name>.md` (hub) using `[[../../datastores/<ds>|<ds>]]`.
- **Project-owned datastore doc**: inbound from hub + local consuming services; outbound to hub only.

## Incremental Algorithm

```
1. Run Step 3.8 orphan/stub sweep (delete empty .md files, dedup canonical
   datastore IDs, remove dangling backlinks and graph nodes)
2. Read manifest.json
3. For each source file:
   - New → analyze, add to manifest
   - Changed hash → analyze, mark contributed_to docs stale
   - Deleted → remove from manifest, mark docs stale
   - Unchanged → skip
4. Run Step 3.7 datastore canonicalization + classification
   - Compare against persisted classifications
   - Promote (project → shared) or demote (shared → project) as needed,
     rewriting backlinks and moving files atomically
5. Regenerate stale docs through Step 3.9 atomic write guards (stubs skipped)
6. Update manifest (files + manifests + generator + datastore_classifications)
7. Write/merge .obsidian/graph.json (6-color palette, -file:Home filter)
```

## Error Handling

| Condition               | Behavior                  |
| ----------------------- | ------------------------- |
| kb-identity fails       | Return error immediately  |
| Cannot read file        | Skip, continue, log       |
| Corrupted manifest      | Regenerate from scratch   |
| Missing template        | Use inline default        |
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
