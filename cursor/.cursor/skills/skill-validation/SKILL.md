---
name: skill-validation
description: Defines input/output schema validation for skills. Use when creating or validating skills, composing skill chains, or checking skill contracts. Agents load this skill to understand how to validate skill I/O.
version: 1
---

# Skill Validation Protocol

## Overview

This skill defines the validation protocol for all other skills. It enables type-safe skill composition, runtime validation, and caching. Load this skill when creating new skills, validating skill contracts, or chaining skills together.

## Enhanced Skill Frontmatter Schema

Every skill MUST have YAML frontmatter with these fields:

```yaml
---
# Required fields
name: string              # Unique skill identifier (kebab-case)
description: string       # Single sentence describing when to use
version: number           # Schema version, default 1

# Optional: Input specification
input_schema:
  required:               # Inputs that MUST be provided
    - name: string        # Parameter name
      type: string | string[] | number | boolean | object
      description: string # What this input represents
  optional:               # Inputs that MAY be provided
    - name: string
      type: string | string[] | number | boolean | object
      description: string
      default: any        # Default value if not provided

# Optional: Output specification
output_schema:
  required:               # Outputs that MUST be produced
    - name: string        # Output field name
      type: string        # Type description
      description: string # What this output represents
  optional:               # Outputs that MAY be produced
    - name: string
      type: string
      description: string

# Optional: Validation checks
pre_checks:               # Validate before execution
  - description: string   # What to validate
    validation: string    # How to validate (instruction or condition)

post_checks:              # Validate after execution
  - description: string   # What to validate
    validation: string    # How to validate

# Optional: Caching
cacheable: boolean        # Whether outputs can be cached (default: false)
cache_ttl_minutes: number # Cache lifetime (default: 0, only if cacheable: true)
---
```

## Type System

### Supported Types

| Type | Description | Example |
|------|-------------|---------|
| `string` | Single text value | `"namespace"` |
| `string[]` | Array of strings | `["tag1", "tag2"]` |
| `number` | Numeric value | `42`, `3.14` |
| `boolean` | True or false | `true`, `false` |
| `object` | Structured data | `{ "key": "value" }` |

### Type Coercion Rules

- `string` accepts any scalar converted to string
- `string[]` accepts a single string (wrapped in array)
- `number` accepts numeric strings (parsed)
- `boolean` accepts `"true"/"false"` strings (parsed)
- `object` accepts JSON strings (parsed)

## Pre-Execution Validation Protocol

Before using a skill, agents MUST validate inputs:

### Step 1: Check Required Inputs Exist

```
For each input in input_schema.required:
  If input.name not provided:
    FAIL with: "Missing required input: {input.name}"
```

### Step 2: Validate Input Types

```
For each provided input:
  If input value type does not match declared type:
    If type coercion possible:
      Coerce value to declared type
    Else:
      FAIL with: "Type mismatch for {input.name}: expected {type}, got {actual_type}"
```

### Step 3: Apply Default Values

```
For each input in input_schema.optional:
  If input.name not provided and default exists:
    Set input.name = default
```

### Step 4: Run Pre-Checks

```
For each check in pre_checks:
  Evaluate check.validation
  If validation fails:
    FAIL with: "Pre-check failed: {check.description}"
```

### Validation Failure Format

When validation fails, return structured error:

```yaml
validation_error:
  skill: skill-name
  phase: pre_execution | post_execution
  check: description of what failed
  expected: what was expected
  actual: what was found
  suggestion: how to fix
```

## Post-Execution Validation Protocol

After skill execution, agents MUST validate outputs:

### Step 1: Check Required Outputs Exist

```
For each output in output_schema.required:
  If output.name not in result:
    FAIL with: "Missing required output: {output.name}"
```

### Step 2: Validate Output Types

```
For each declared output:
  If output present and type does not match:
    WARN: "Output type mismatch for {output.name}"
```

### Step 3: Run Post-Checks

```
For each check in post_checks:
  Evaluate check.validation
  If validation fails:
    FAIL with: "Post-check failed: {check.description}"
```

## Skill Chaining Protocol

Skills can be composed into chains where outputs feed into inputs.

### Chain Definition

```yaml
chain:
  - skill: skill-a
    inputs: { param: value }
    outputs_as: step1
  - skill: skill-b
    inputs:
      data: $step1.result   # Reference previous output
    outputs_as: step2
```

### Schema Compatibility Checking

Before executing a chain, validate compatibility:

```
For each step after the first:
  For each input that references a previous output:
    source_output = resolve $reference
    Verify source skill's output_schema includes the field
    Verify types are compatible (or coercible)
    If incompatible:
      FAIL with: "Chain incompatibility: {source_skill}.{output_field} 
                  cannot feed {target_skill}.{input_field}"
```

### Chain Example

```yaml
# Step 1: Read memory
- skill: context-memory
  inputs:
    operation: read
    namespace: org.global
    query: auth patterns
  outputs_as: memory_read

# Step 2: Generate prompt using memory
- skill: ai-orchestration-prompt-engineering
  inputs:
    task_description: $memory_read.entities[0].body
    constraints: ["must be verifiable", "structured output"]
  outputs_as: prompt_result
```

### Compatibility Matrix

| Source Type | Target Type | Compatible | Notes |
|-------------|-------------|------------|-------|
| `string` | `string` | Yes | Direct pass |
| `string[]` | `string` | Yes | Join or first element |
| `object` | `string` | Yes | Serialize to JSON |
| `string` | `string[]` | Yes | Wrap in array |
| `number` | `string` | Yes | Convert to string |
| `boolean` | `string` | Yes | `"true"` or `"false"` |

## Skill Caching Protocol

Skills marked `cacheable: true` can have their outputs cached.

### Cache Key Format

```
{skill_name}:{hash_of_sorted_inputs}
```

Example:
```
context-memory:a1b2c3d4e5f6
```

Where hash is SHA-256 of canonical JSON representation of inputs.

### Cache Storage

Cache entries are stored in session memory:

```
Location: session/current/cache/
Filename: {skill_name}-{short_hash}.md
```

### Cache Entry Schema

```yaml
---
entity_name: session.current.cache.{skill_name}.{short_hash}
namespace: session.current
category: cache
status: accepted
tags: [cache, {skill_name}]
created_at: 2026-04-04T10:00:00Z
cache_key: {full_cache_key}
cache_ttl_minutes: {ttl}
expires_at: 2026-04-04T10:30:00Z
---

{serialized output as JSON or YAML}
```

### Cache Lookup Protocol

```
1. Compute cache_key from skill name and inputs
2. Check session/current/cache/ for matching entry
3. If found and not expired:
   Return cached output
4. If expired:
   Delete cache entry
   Continue to execution
5. If not found:
   Continue to execution
6. After execution (if cacheable):
   Write cache entry with TTL
```

### TTL-Based Invalidation

- Check `expires_at` before using cached value
- Delete expired entries on access
- Session end clears all session cache entries

### When to Use Caching

| Use Case | Cacheable | Reason |
|----------|-----------|--------|
| Memory reads | Yes | File content stable within session |
| Expensive analysis | Yes | Avoid repeated computation |
| External API calls | Yes | Reduce latency and cost |
| State mutations | No | Must execute every time |
| Time-sensitive data | No | Results change over time |

## Validation Examples

### Example 1: Valid Skill Frontmatter

```yaml
---
name: context-memory
description: File-based Markdown memory at ~/.cursor/memory/. Any agent can read/write directly using this skill.
version: 1
input_schema:
  required:
    - name: operation
      type: string
      description: Operation type - read, write, update, or delete
    - name: namespace
      type: string
      description: Target namespace (e.g., org.global, projects.myapp)
  optional:
    - name: query
      type: string
      description: Search query for read operations
    - name: content
      type: object
      description: Entity content for write operations
output_schema:
  required:
    - name: status
      type: string
      description: Operation result - success, not_found, or error
  optional:
    - name: entities
      type: object[]
      description: Retrieved or created entities
    - name: index
      type: object
      description: Updated index state
pre_checks:
  - description: Namespace follows naming convention
    validation: namespace matches pattern ^(org|projects|session)\..+$
  - description: Operation is valid
    validation: operation in [read, write, update, delete]
post_checks:
  - description: Status is returned
    validation: status is not empty
  - description: Write operations update index
    validation: if operation in [write, update] then index is updated
cacheable: true
cache_ttl_minutes: 5
---
```

### Example 2: Validation Failure

**Input provided:**
```yaml
operation: read
# namespace missing!
query: "auth patterns"
```

**Error output:**
```yaml
validation_error:
  skill: context-memory
  phase: pre_execution
  check: Required input validation
  expected: namespace (string) must be provided
  actual: namespace was not provided
  suggestion: Add namespace parameter, e.g., namespace: "org.global"
```

### Example 3: Skill Chain with Compatible Schemas

```yaml
# Chain: Memory → Prompt → Validation
chain:
  - skill: context-memory
    inputs:
      operation: read
      namespace: org.global
      query: security decisions
    outputs_as: memory
    # Output: { status: "success", entities: [...] }

  - skill: ai-orchestration-prompt-engineering
    inputs:
      task_description: "Review these security decisions"
      context: $memory.entities      # object[] → feeds into context
      output_format: structured
    outputs_as: prompt
    # Output: { prompt: "...", validation_rules: [...] }

  - skill: failure-engineering
    inputs:
      system_description: $prompt.prompt
      failure_scenarios: ["network timeout", "auth failure"]
    outputs_as: resilience
    # Output: { recommendations: [...], risk_assessment: {...} }
```

**Schema compatibility check:**
- `memory.entities` (object[]) → `prompt.context` (object): Compatible via array access
- `prompt.prompt` (string) → `resilience.system_description` (string): Compatible

## Creating Validated Skills

When creating a new skill:

1. Start with required frontmatter: `name`, `description`, `version`
2. Define `input_schema` based on what the skill needs to function
3. Define `output_schema` based on what the skill produces
4. Add `pre_checks` for input validation beyond type checking
5. Add `post_checks` for output quality validation
6. Set `cacheable: true` only if outputs are deterministic for given inputs
7. Test validation by providing invalid inputs and verifying error messages

## Validating Existing Skills

To add validation to an existing skill:

1. Read the skill content thoroughly
2. Identify all inputs mentioned in the protocol
3. Identify all outputs the skill produces
4. Derive pre-checks from stated preconditions
5. Derive post-checks from stated guarantees
6. Add schema to frontmatter without modifying content
7. Verify YAML frontmatter is valid
