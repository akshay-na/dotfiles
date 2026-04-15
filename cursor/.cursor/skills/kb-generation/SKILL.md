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
| `incremental` | Compare file hashes via manifest, regenerate only changed |
| `refresh-stale` | Check frontmatter `stale: true`, regenerate those docs |

## Step 3: Analyze Project

### Files to Read

| Category | Files |
|----------|-------|
| Manifests | `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json` |
| Config | `tsconfig.json`, `.eslintrc`, `docker-compose.yml`, `Dockerfile` |
| Entry points | `index.*`, `main.*`, `app.*`, `mod.rs`, `__init__.py` |

### Skip

`node_modules/`, `vendor/`, `.git/`, `build/`, `dist/`, `target/`, `__pycache__/`, lock files, generated files, binaries.

### Extract

- **Modules**: Directories with index/entry files → name, path, exports, imports
- **Services**: Directories with Dockerfile/main entry → name, port, protocol, endpoints
- **Dependencies**: From manifest → name, version, type (prod/dev/peer)
- **Edges**: Import statements → source, target, relation, confidence

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
| `services/_index.md` | `services-index.md` | Service inventory, communication matrix |
| `services/<name>.md` | `service-doc.md` | Purpose, endpoints, deployment |
| `graph.json` | (schema) | Nodes + edges for programmatic queries |

### Template Variables

Fill templates with: `{{project_name}}`, `{{timestamp}}`, `{{confidence}}`, `{{module_nodes}}`, `{{service_nodes}}`, etc.

## Step 5: Build graph.json

```json
{
  "version": 1,
  "project": "<name>",
  "generated_at": "<ISO8601>",
  "nodes": [{ "id": "", "label": "", "type": "module|service|external_dep", "kb_doc": "" }],
  "edges": [{ "source": "", "target": "", "relation": "imports|depends_on|calls", "confidence": "EXTRACTED|INFERRED" }]
}
```

Validate against `_schema/graph.schema.json`.

## Step 6: Update Manifest

Write to `.meta/manifest.json`:

```json
{
  "version": 1,
  "project": "<name>",
  "generated_at": "<ISO8601>",
  "files": {
    "<path>": { "sha256": "<hash>", "last_analyzed": "<ISO8601>", "contributed_to": ["README.md"] }
  }
}
```

## Step 7: Update Home.md

**MANDATORY** — Update `~/.cursor/docs/knowledge-base/Home.md` after every generation.

1. If missing, create from `templates/home.md`
2. Update project row in Projects table
3. Refresh statistics
4. Update recently updated list

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
