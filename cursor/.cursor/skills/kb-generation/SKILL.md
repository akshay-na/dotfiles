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
      description: Derived project name
    - name: kb_path
      type: string
      description: Path to generated KB directory
  optional:
    - name: documents_generated
      type: number
      description: Count of documents created
    - name: documents_updated
      type: number
      description: Count of documents updated (incremental mode)
    - name: documents_skipped
      type: number
      description: Count of unchanged documents skipped
    - name: stats
      type: object
      description: Generation statistics - modules, services, dependencies, edges
    - name: error
      type: string
      description: Error message if status is error
pre_checks:
  - description: Project root must be provided
    validation: project_root is not empty
  - description: Mode must be valid
    validation: mode in ["full", "incremental", "refresh-stale"]
  - description: Scope must be valid if provided
    validation: if scope provided then scope in ["all", "architecture", "modules", "services", "dependencies"]
post_checks:
  - description: Status is always returned
    validation: status is not empty
  - description: Success returns path
    validation: if status is success then kb_path is returned
  - description: Manifest updated on success
    validation: if status is success then .meta/manifest.json exists
cacheable: false
---

# kb-generation Skill

Core protocol for generating Knowledge Base documentation. This skill is used by `kb-engineer` to analyze projects and produce Obsidian-compatible documentation.

## Overview

The generation process:
1. Invokes `kb-identity` to derive project identity
2. Analyzes project structure by reading files directly (no shell)
3. Generates markdown documents with mermaid diagrams
4. Builds `graph.json` with relationship data
5. Updates manifest for incremental tracking

## Generation Protocol

### Step 1: Invoke kb-identity skill

```
identity = kb-identity(project_root)

if identity.status != "success":
    return { status: identity.status, error: identity.error }

project_name = identity.project_name
kb_path = identity.kb_path
```

### Step 2: Determine KB path and mode behavior

```
kb_projects_path = expand("~/.cursor/docs/knowledge-base/projects/")
project_kb_path = kb_projects_path + project_name + "/"

if mode == "full":
    # Generate everything from scratch
    # Clear existing docs if any (except .meta/identity.json)
    
elif mode == "incremental":
    # Read existing manifest
    manifest = read_json(project_kb_path + ".meta/manifest.json")
    # Compute current file hashes
    # Only regenerate docs for changed files
    
elif mode == "refresh-stale":
    # Read existing docs
    # Check frontmatter for stale: true
    # Regenerate only stale docs
```

### Step 3: Analyze project structure

Read files directly (NO SHELL COMMANDS):

#### 3a. Read package manifests

```
# Detect project type and read appropriate manifest
supported_manifests = [
    "package.json",      # Node.js
    "Cargo.toml",        # Rust
    "pyproject.toml",    # Python (modern)
    "setup.py",          # Python (legacy)
    "go.mod",            # Go
    "pom.xml",           # Java/Maven
    "build.gradle",      # Java/Gradle
    "Gemfile",           # Ruby
    "composer.json",     # PHP
    "pubspec.yaml",      # Dart/Flutter
]

for manifest in supported_manifests:
    if exists(project_root + "/" + manifest):
        content = read_file(project_root + "/" + manifest)
        extract: name, version, dependencies, dev_dependencies, scripts
```

#### 3b. Map directory structure

```
# Identify module boundaries
# Common patterns:
#   - src/<module>/
#   - packages/<module>/
#   - lib/<module>/
#   - apps/<service>/
#   - services/<service>/

modules = []
services = []

# Read directory structure
for entry in list_directory(project_root):
    if is_directory(entry):
        # Check for module indicators
        if has_index_file(entry) or has_mod_file(entry):
            modules.append(analyze_module(entry))
        
        # Check for service indicators
        if has_dockerfile(entry) or has_main_entry(entry):
            services.append(analyze_service(entry))
```

#### 3c. Read entry points and exports

```
# For each module, read key files
for module in modules:
    entry_files = [
        module.path + "/index.ts",
        module.path + "/index.js",
        module.path + "/mod.rs",
        module.path + "/__init__.py",
        module.path + "/main.go",
    ]
    
    for file in entry_files:
        if exists(file):
            content = read_file(file)
            extract: exports, imports, public_api
```

#### 3d. Build relationship graph

```
nodes = []
edges = []

# Add module nodes
for module in modules:
    nodes.append({
        id: module.name,
        label: module.name,
        type: "module",
        source_file: module.entry_point,
        kb_doc: "modules/" + module.name + ".md"
    })

# Add service nodes
for service in services:
    nodes.append({
        id: service.name,
        label: service.name,
        type: "service",
        source_file: service.entry_point,
        kb_doc: "services/" + service.name + ".md"
    })

# Add external dependency nodes
for dep in external_dependencies:
    nodes.append({
        id: "ext:" + dep.name,
        label: dep.name,
        type: "external_dep"
    })

# Add edges
for module in modules:
    for import in module.imports:
        edges.append({
            source: module.name,
            target: resolve_target(import),
            relation: "imports",
            confidence: "EXTRACTED",
            source_location: import.file + ":" + import.line
        })
```

### Step 4: Generate documents

Use templates from `~/.cursor/docs/knowledge-base/templates/`.

#### 4a. README.md (overview)

```
template = read_file(templates_path + "project-readme.md")
content = fill_template(template, {
    project_name: project_name,
    description: extracted_description,
    tech_stack_rows: format_tech_stack(tech_stack),
    module_links: format_module_links(modules),
    service_links: format_service_links(services),
    module_count: modules.length,
    service_count: services.length,
    dep_count: dependencies.length,
    timestamp: now_iso8601(),
    confidence: calculate_confidence()
})
write_file(project_kb_path + "README.md", content)
```

#### 4b. architecture.md

```
template = read_file(templates_path + "architecture-doc.md")
content = fill_template(template, {
    project_name: project_name,
    overview: generate_architecture_overview(),
    # Generate mermaid diagram nodes
    internal_nodes: generate_mermaid_nodes(modules, services),
    connections: generate_mermaid_edges(edges),
    ...
})
write_file(project_kb_path + "architecture.md", content)
```

#### 4c. modules/*.md

```
ensure_directory(project_kb_path + "modules/")

# Generate index
index_content = generate_module_index(modules)
write_file(project_kb_path + "modules/_index.md", index_content)

# Generate per-module docs
for module in modules:
    template = read_file(templates_path + "module-doc.md")
    content = fill_template(template, {
        module_name: module.name,
        project_name: project_name,
        purpose: module.description,
        module_path: module.path,
        entry_point: module.entry_point,
        public_api: format_api(module.exports),
        internal_dependencies: format_deps(module.internal_deps),
        external_dependencies: format_deps(module.external_deps),
        dependents: find_dependents(module, edges),
        timestamp: now_iso8601(),
        ...
    })
    write_file(project_kb_path + "modules/" + module.name + ".md", content)
```

#### 4d. services/*.md

```
ensure_directory(project_kb_path + "services/")

# Generate index
index_content = generate_service_index(services)
write_file(project_kb_path + "services/_index.md", index_content)

# Generate per-service docs
for service in services:
    template = read_file(templates_path + "service-doc.md")
    content = fill_template(template, {
        service_name: service.name,
        project_name: project_name,
        purpose: service.description,
        port: service.port,
        protocol: service.protocol,
        api_endpoints: format_endpoints(service.endpoints),
        # Generate mermaid sequence diagram
        sequence_diagram_content: generate_sequence_diagram(service),
        ...
    })
    write_file(project_kb_path + "services/" + service.name + ".md", content)
```

#### 4e. dependencies.md

```
content = generate_dependency_doc(dependencies, {
    # Mermaid flowchart for dependency graph
    mermaid_graph: generate_dependency_mermaid(dependencies)
})
write_file(project_kb_path + "dependencies.md", content)
```

#### 4f. graph.json

```
graph = {
    version: 1,
    project: project_name,
    generated_at: now_iso8601(),
    nodes: nodes,
    edges: edges
}

# Validate against schema
validate_json(graph, "_schema/graph.schema.json")

write_file(project_kb_path + "graph.json", json_stringify(graph))
```

### Step 5: Update manifest

```
ensure_directory(project_kb_path + ".meta/")

manifest = {
    version: 1,
    project: project_name,
    generated_at: now_iso8601(),
    files: {}
}

for file in analyzed_files:
    manifest.files[file.path] = {
        sha256: compute_sha256(file.content),
        last_analyzed: now_iso8601(),
        contributed_to: file.contributed_docs
    }

write_file(project_kb_path + ".meta/manifest.json", json_stringify(manifest))
```

### Step 6: Update identity.json

```
identity_record = {
    project_name: project_name,
    identity_hash: identity.identity_hash,
    full_identity: identity.full_identity,
    remote_url: identity.remote_url,
    derived_from: identity.derived_from,
    is_worktree: identity.is_worktree,
    main_repo_path: identity.main_repo_path,
    derived_at: now_iso8601(),
    needs_refresh: false
}

write_file(project_kb_path + ".meta/identity.json", json_stringify(identity_record))
```

### Step 7: Update Home.md

```
home_path = expand("~/.cursor/docs/knowledge-base/Home.md")
home_content = read_file(home_path)

# Update or add project row in Projects table
project_row = "| " + project_name + " | " + now_date() + " | " + modules.length + " | " + services.length + " | ✓ |"

# Replace existing row or append new row
home_content = update_project_table(home_content, project_name, project_row)

write_file(home_path, home_content)
```

## File Scope Rules

### ALWAYS Analyze

- Package manifests: `package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`, `Gemfile`, `composer.json`
- Config files: `tsconfig.json`, `.eslintrc`, `docker-compose.yml`, `Dockerfile`
- Entry points: `index.*`, `main.*`, `app.*`, `mod.rs`, `__init__.py`
- README files at any level

### ANALYZE on First Pass (full mode)

- All source files in detected languages
- But: read only imports/exports/public API, not full function bodies
- Focus on structure, not implementation details

### SKIP

- `node_modules/`, `vendor/`, `.git/`, `build/`, `dist/`, `target/`, `__pycache__/`
- Generated files: `*.generated.*`, `*.g.dart`
- Test files (note presence, but skip detailed analysis)
- Binary files, images, fonts
- Lock files: `package-lock.json`, `yarn.lock`, `Cargo.lock`, `poetry.lock`

## Incremental Update Algorithm

```
1. Read existing manifest.json
2. Walk project source directories (respect .gitignore patterns)
3. For each file:
   a. Compute SHA256 by reading file content
   b. Compare against manifest:
      - New file → add to analysis queue
      - Changed hash → add to analysis queue + mark contributed_to docs as stale
      - Deleted file → remove from manifest + mark contributed_to docs as stale
      - Unchanged → skip

4. For each doc to regenerate:
   a. Re-analyze contributing files
   b. Regenerate doc with updated content
   c. Update frontmatter: generated_at, stale=false

5. Update manifest with new hashes
```

## Staleness Detection

When KB docs may be stale:
- `manifest.json` file hash differs from current file hash
- Frontmatter `stale: true`
- `.meta/identity.json` has `needs_refresh: true`

Response:
- Set `needs_refresh: true` in identity.json
- On next generation run (incremental or refresh-stale), regenerate affected docs

## Error Handling

| Condition | Behavior |
|-----------|----------|
| kb-identity fails | Return error immediately |
| Cannot read project file | Skip file, continue, note in generation-log |
| Cannot parse manifest | Treat as corrupted, regenerate from scratch |
| Template missing | Use default inline template |
| Schema validation fails | Log warning, write anyway with warning in doc |

## Output Example

```
{
    status: "success",
    project_name: "myapp",
    kb_path: "/Users/dev/.cursor/docs/knowledge-base/projects/myapp/",
    documents_generated: 12,
    documents_updated: 0,
    documents_skipped: 0,
    stats: {
        modules: 5,
        services: 2,
        dependencies: 23,
        edges: 47
    }
}
```
