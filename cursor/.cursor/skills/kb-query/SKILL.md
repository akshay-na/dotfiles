---
name: kb-query
description: Token-efficient query protocol for Knowledge Base. Provides tiered access to project documentation with staleness detection and budget-aware responses.
version: 1
input_schema:
  required:
    - name: query_type
      type: string
      description: Type of query - "overview", "module", "service", "dependency", "relationship", or "search"
  optional:
    - name: project_name
      type: string
      description: Project name (if known). Either project_name or project_root must be provided.
    - name: project_root
      type: string
      description: Project root path (will derive project_name via kb-identity). Either project_name or project_root must be provided.
    - name: target
      type: string
      description: Target for query - module name, service name, dependency name, or search term. Required for module, service, dependency, relationship, and search query types.
    - name: max_tokens
      type: number
      description: Token budget for response. Default 500.
output_schema:
  required:
    - name: status
      type: string
      description: Result status - "success", "not_found", "stale_warning", "kb_not_exists", or "error"
  optional:
    - name: content
      type: string
      description: Query result content with [[backlinks]] preserved
    - name: sources
      type: array
      description: List of KB files consulted
    - name: stale_files
      type: array
      description: Any consulted files marked as stale
    - name: suggestion
      type: string
      description: Suggestion if KB doesn't exist or is incomplete
    - name: error
      type: string
      description: Error message if status is error
pre_checks:
  - description: Query type must be valid
    validation: query_type in ["overview", "module", "service", "dependency", "relationship", "search"]
  - description: Project identifier must be provided
    validation: project_name or project_root is provided
  - description: Target required for targeted queries
    validation: if query_type in ["module", "service", "dependency", "relationship", "search"] then target is provided
post_checks:
  - description: Status is always returned
    validation: status is not empty
  - description: Success includes content
    validation: if status in ["success", "stale_warning"] then content is returned
  - description: Sources tracked
    validation: if status is success then sources is returned
cacheable: true
cache_ttl_minutes: 5
---

# kb-query Skill

Token-efficient query protocol for reading Knowledge Base documentation. Designed for agents that need project understanding without loading entire codebases.

## Overview

The KB query skill provides:
- Tiered token budgets for different query depths
- Staleness detection and warnings
- Graceful handling when KB doesn't exist
- Backlink preservation in responses

## Query Protocol

### Step 1: Resolve project identity

```
if project_name is provided:
    # Use directly
    kb_path = expand("~/.cursor/docs/knowledge-base/projects/" + project_name + "/")
else:
    # Derive from project_root using kb-identity
    identity = kb-identity(project_root)
    if identity.status != "success":
        return { status: "error", error: identity.error }
    project_name = identity.project_name
    kb_path = identity.kb_path
```

### Step 2: Check KB existence

```
if not exists(kb_path):
    return {
        status: "kb_not_exists",
        suggestion: "Run kb-engineer or vp-onboarding to generate KB for this project"
    }

if not exists(kb_path + "README.md"):
    return {
        status: "kb_not_exists", 
        suggestion: "KB directory exists but is incomplete. Run kb-engineer with mode=full"
    }
```

### Step 3: Check staleness

```
# Check identity.json for needs_refresh flag
identity_path = kb_path + ".meta/identity.json"
if exists(identity_path):
    identity = read_json(identity_path)
    if identity.needs_refresh:
        stale_warning = true
        stale_files.append("identity.json (needs_refresh=true)")
```

### Step 4: Route by query type

#### Overview Query

```
if query_type == "overview":
    # Level 0-1: Read README.md only
    readme_path = kb_path + "README.md"
    content = read_file(readme_path)
    
    # Check frontmatter for stale flag
    frontmatter = parse_yaml_frontmatter(content)
    if frontmatter.stale:
        stale_warning = true
        stale_files.append("README.md")
    
    # Truncate to max_tokens if needed
    content = truncate_to_tokens(content, max_tokens)
    
    return {
        status: stale_warning ? "stale_warning" : "success",
        content: content,
        sources: [readme_path],
        stale_files: stale_files
    }
```

#### Module Query

```
if query_type == "module":
    # Level 1-2: Read module index, then specific module
    sources = []
    
    # First read index to verify module exists
    index_path = kb_path + "modules/_index.md"
    if exists(index_path):
        index_content = read_file(index_path)
        sources.append(index_path)
        
        if target not in index_content:
            return { status: "not_found", error: "Module '" + target + "' not found in KB" }
    
    # Read specific module doc
    module_path = kb_path + "modules/" + target + ".md"
    if not exists(module_path):
        return { status: "not_found", error: "Module doc not found: " + module_path }
    
    content = read_file(module_path)
    sources.append(module_path)
    
    # Check staleness
    frontmatter = parse_yaml_frontmatter(content)
    if frontmatter.stale:
        stale_warning = true
        stale_files.append(module_path)
    
    content = truncate_to_tokens(content, max_tokens)
    
    return {
        status: stale_warning ? "stale_warning" : "success",
        content: content,
        sources: sources,
        stale_files: stale_files
    }
```

#### Service Query

```
if query_type == "service":
    # Level 1-2: Read service index, then specific service
    sources = []
    
    index_path = kb_path + "services/_index.md"
    if exists(index_path):
        index_content = read_file(index_path)
        sources.append(index_path)
        
        if target not in index_content:
            return { status: "not_found", error: "Service '" + target + "' not found in KB" }
    
    service_path = kb_path + "services/" + target + ".md"
    if not exists(service_path):
        return { status: "not_found", error: "Service doc not found: " + service_path }
    
    content = read_file(service_path)
    sources.append(service_path)
    
    frontmatter = parse_yaml_frontmatter(content)
    if frontmatter.stale:
        stale_warning = true
        stale_files.append(service_path)
    
    content = truncate_to_tokens(content, max_tokens)
    
    return {
        status: stale_warning ? "stale_warning" : "success",
        content: content,
        sources: sources,
        stale_files: stale_files
    }
```

#### Dependency Query

```
if query_type == "dependency":
    # Level 1: Read dependencies.md, search for target
    deps_path = kb_path + "dependencies.md"
    if not exists(deps_path):
        return { status: "not_found", error: "dependencies.md not found" }
    
    content = read_file(deps_path)
    
    # Extract section about target dependency
    section = extract_dependency_section(content, target)
    if section is null:
        return { status: "not_found", error: "Dependency '" + target + "' not found" }
    
    return {
        status: "success",
        content: section,
        sources: [deps_path]
    }
```

#### Relationship Query

```
if query_type == "relationship":
    # Level 3: Read graph.json, traverse edges
    graph_path = kb_path + "graph.json"
    if not exists(graph_path):
        return { status: "not_found", error: "graph.json not found" }
    
    graph = read_json(graph_path)
    
    # Find node
    node = find_node(graph.nodes, target)
    if node is null:
        return { status: "not_found", error: "Node '" + target + "' not found in graph" }
    
    # Find all edges involving this node
    incoming = filter(graph.edges, e => e.target == target)
    outgoing = filter(graph.edges, e => e.source == target)
    
    # Format response
    content = format_relationship_response(node, incoming, outgoing, max_tokens)
    
    return {
        status: "success",
        content: content,
        sources: [graph_path]
    }
```

#### Search Query

```
if query_type == "search":
    # Level 1-2: Scan frontmatter tags and content
    results = []
    sources = []
    
    # Search in _index files first (cheapest)
    for index_file in [kb_path + "modules/_index.md", kb_path + "services/_index.md"]:
        if exists(index_file):
            content = read_file(index_file)
            if target in content.lowercase():
                results.append({ file: index_file, type: "index" })
                sources.append(index_file)
    
    # Search in README and architecture
    for doc_file in [kb_path + "README.md", kb_path + "architecture.md", kb_path + "dependencies.md"]:
        if exists(doc_file):
            content = read_file(doc_file)
            frontmatter = parse_yaml_frontmatter(content)
            
            # Match in tags
            if target in frontmatter.tags:
                results.append({ file: doc_file, type: "tag_match" })
                sources.append(doc_file)
            # Match in content
            elif target in content.lowercase():
                results.append({ file: doc_file, type: "content_match" })
                sources.append(doc_file)
    
    if results.length == 0:
        return { status: "not_found", error: "No matches for '" + target + "'" }
    
    content = format_search_results(results, max_tokens)
    
    return {
        status: "success",
        content: content,
        sources: sources
    }
```

## Token Tiers

| Tier | Token Budget | Use For |
|------|-------------|---------|
| Level 0 | ~50 | Just project name and type from index |
| Level 1 | ~200 | README.md overview, index files |
| Level 2 | ~500 | Specific module/service docs |
| Level 3 | ~1000+ | graph.json traversal, relationship queries |

### Choosing the right tier

| Query Need | Recommended Tier | Method |
|------------|-----------------|--------|
| "What is this project?" | Level 0-1 | overview |
| "What does this project do?" | Level 1 | overview |
| "What modules exist?" | Level 1 | overview or search |
| "How does module X work?" | Level 2 | module |
| "What depends on module X?" | Level 3 | relationship |
| "Show me the architecture" | Level 2 | overview + read architecture.md |
| "What external deps does this use?" | Level 1 | dependency |

## Staleness Handling

### Detection

Check these in order:
1. `.meta/identity.json` → `needs_refresh: true`
2. Document frontmatter → `stale: true`
3. Manifest hash mismatch (if doing deep validation)

### Response behavior

When stale content is detected:
- Set `status: "stale_warning"` instead of `"success"`
- Include `stale_files` array listing affected files
- Still return the content (stale is better than nothing)
- Include suggestion to refresh KB

Example stale response:
```json
{
    "status": "stale_warning",
    "content": "... module documentation ...",
    "sources": ["modules/auth.md"],
    "stale_files": ["modules/auth.md"],
    "suggestion": "This content may be outdated. Run kb-engineer with mode=refresh-stale"
}
```

## Agent Query Discipline

Agents using this skill should:

1. **Start at Level 0/1** — Don't immediately read all docs
2. **Escalate only when needed** — Level 2/3 queries for specific tasks
3. **Cache in session** — Store query results in session memory for the task duration
4. **Never read all KB docs at once** — Defeats the purpose of tiered access
5. **Respect token budgets** — Pass appropriate `max_tokens` for the task

## Error Handling

| Condition | Status | Suggestion |
|-----------|--------|------------|
| KB directory doesn't exist | `kb_not_exists` | Run kb-engineer or vp-onboarding |
| README.md missing | `kb_not_exists` | Run kb-engineer with mode=full |
| Target module/service not found | `not_found` | Check module name spelling, or run refresh |
| graph.json missing | `not_found` | Run kb-engineer with mode=full |
| Parse error in KB file | `error` | KB may be corrupted, regenerate |

## Examples

### Query project overview

```
Input:
    project_name: "myapp"
    query_type: "overview"
    max_tokens: 200

Output:
    status: "success"
    content: "# myapp\n\nMyApp is a..."
    sources: ["~/.cursor/docs/knowledge-base/projects/myapp/README.md"]
```

### Query specific module

```
Input:
    project_name: "myapp"
    query_type: "module"
    target: "auth"
    max_tokens: 500

Output:
    status: "success"
    content: "# auth\n\n## Purpose\nHandles authentication..."
    sources: [
        "~/.cursor/docs/knowledge-base/projects/myapp/modules/_index.md",
        "~/.cursor/docs/knowledge-base/projects/myapp/modules/auth.md"
    ]
```

### Query with stale warning

```
Input:
    project_root: "/Users/dev/myapp"
    query_type: "module"
    target: "auth"

Output:
    status: "stale_warning"
    content: "# auth\n\n## Purpose\n..."
    sources: ["modules/_index.md", "modules/auth.md"]
    stale_files: ["modules/auth.md"]
    suggestion: "This content may be outdated. Run kb-engineer with mode=refresh-stale"
```

### KB doesn't exist

```
Input:
    project_name: "newproject"
    query_type: "overview"

Output:
    status: "kb_not_exists"
    suggestion: "Run kb-engineer or vp-onboarding to generate KB for this project"
```
