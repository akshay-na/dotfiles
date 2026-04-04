---
name: task-orchestration
description: Automated task classification, agent selection, and state tracking. Use when routing tasks to agents, selecting pipelines, or managing task state.
version: 1
input_schema:
  required:
    - name: task_description
      type: string
      description: The user's task or request
  optional:
    - name: explicit_pipeline
      type: string
      description: Explicitly requested pipeline name
    - name: explicit_agents
      type: string[]
      description: Explicitly requested agents
    - name: mentioned_files
      type: string[]
      description: Files/folders mentioned in the task (@-mentions or paths)
    - name: current_working_directory
      type: string
      description: Current working directory for repo detection
    - name: context
      type: object
      description: Additional context (files, constraints)
output_schema:
  required:
    - name: task_id
      type: string
      description: Unique task identifier
    - name: task_type
      type: string
      description: Classified task type
    - name: pipeline
      type: string
      description: Selected pipeline name
    - name: agents
      type: string[]
      description: Agents to involve
    - name: target_repo
      type: string
      description: Repository this task targets
  optional:
    - name: requires_plan
      type: boolean
      description: Whether task needs planning phase
    - name: complexity
      type: string
      description: Task complexity assessment
    - name: subtasks
      type: object[]
      description: Subtasks if task spans multiple repos
    - name: tech_lead_bootstrapped
      type: boolean
      description: Whether vp-onboarding was invoked to create tech-lead
pre_checks:
  - description: Task description is provided
    validation: task_description is not empty
  - description: Explicit pipeline exists if provided
    validation: if explicit_pipeline provided then pipeline exists in configurations/pipelines/
post_checks:
  - description: Task ID is generated
    validation: task_id matches pattern ^task-[a-z0-9]{6}-[a-z0-9-]+$
  - description: Valid task type
    validation: task_type in routing-table.yml classification.task_types OR task_type is "unknown"
  - description: Agents list is non-empty
    validation: agents.length >= 1
cacheable: false
---

# Task Orchestration

Automated task classification, agent selection, and state tracking for the org-level orchestration system.

## Overview

This skill provides the core orchestration protocol for routing tasks to appropriate agents and pipelines. It handles:

1. **Multi-repo workspace detection** (identify which repo a task belongs to)
2. **Tech-lead availability check** (bootstrap via vp-onboarding if missing)
3. Pipeline override detection (explicit user directives)
4. Task classification (signal matching against routing table)
5. Agent routing (selecting appropriate agents based on task type)
6. Task state tracking (full lifecycle management)
7. Output merging (combining parallel stage outputs)
8. Dead letter handling (failed task recovery)

## Multi-Repo Workspace Detection

When working in a workspace with multiple repositories, the orchestrator MUST identify which repo the task belongs to and route to that repo's tech-lead.

### Repo Detection Protocol

```
Input: task_description, mentioned_files[], current_working_directory
Output: target_repo, repo_root_path

1. Extract file/folder references from task
   - Parse @-mentions (e.g., @src/components/Button.tsx)
   - Parse quoted paths
   - Parse inline code paths

2. For each referenced file:
   - Resolve to absolute path
   - Walk up to find .git directory
   - Record repo root path

3. Check current working directory:
   - Walk up to find .git directory
   - If found, record as fallback repo

4. Validate repo consistency:
   - If all files belong to same repo → target_repo = that repo
   - If files span multiple repos → SPLIT task into per-repo subtasks
   - If no files referenced → use current_working_directory repo

5. Return:
   - target_repo: repo name (folder name or git remote name)
   - repo_root_path: absolute path to repo root
```

### Repo Isolation Rules

```
CRITICAL: Never mix agents between repositories in the same task.

1. Each repo has its own project-level agents:
   - {repo}/.cursor/agents/tech-lead.md
   - {repo}/.cursor/agents/dev-*.md
   - {repo}/.cursor/agents/sme-*.md
   - {repo}/.cursor/agents/qa-*.md

2. Org-level agents are shared (invoked via CTO):
   - ~/.cursor/agents/cto.md
   - ~/.cursor/agents/vp-*.md
   - ~/.cursor/agents/ciso.md
   - ~/.cursor/agents/sre-lead.md
   - ~/.cursor/agents/staff-engineer.md
   - ~/.cursor/agents/docs-researcher.md

3. When task spans multiple repos:
   - Create separate task entries for each repo
   - Each subtask routes to its repo's tech-lead
   - Parent task tracks completion of all subtasks
   - Merge outputs only after all subtasks complete
```

### Multi-Repo Task Splitting

```yaml
# Original task spanning repos A and B
original_task:
  description: "Update auth logic in backend and frontend"
  files:
    - backend-repo/src/auth.ts      # Repo A
    - frontend-repo/src/AuthContext.tsx  # Repo B

# Split into:
subtasks:
  - task_id: task-abc123-auth-backend
    repo: backend-repo
    tech_lead: backend-repo/.cursor/agents/tech-lead.md
    description: "Update auth logic in backend"
    files: [backend-repo/src/auth.ts]
  
  - task_id: task-abc124-auth-frontend
    repo: frontend-repo
    tech_lead: frontend-repo/.cursor/agents/tech-lead.md
    description: "Update auth logic in frontend"
    files: [frontend-repo/src/AuthContext.tsx]

# Parent task tracks both
parent_task:
  task_id: task-abc122-auth-multiproject
  subtasks: [task-abc123-auth-backend, task-abc124-auth-frontend]
  state: running
  completed_subtasks: []
```

## Tech-Lead Availability Check

Before routing to a repo's tech-lead, verify the agent exists. If missing, bootstrap via vp-onboarding.

### Availability Protocol

```
Input: repo_root_path
Output: tech_lead_available, action_taken

1. Check for tech-lead:
   - Path: {repo_root_path}/.cursor/agents/tech-lead.md
   - If exists → tech_lead_available = true

2. If tech-lead missing:
   - Log: "tech-lead not found for {repo_name}"
   - Action: Invoke vp-onboarding agent
     - Target: {repo_root_path}
     - Purpose: Bootstrap project-level agents
     - Wait: Block until onboarding completes
   
3. Re-check after onboarding:
   - If tech-lead now exists → tech_lead_available = true
   - If still missing → ERROR: "Failed to bootstrap tech-lead"

4. Return availability status
```

### Onboarding Invocation

```yaml
# When tech-lead is missing, invoke vp-onboarding
vp_onboarding_invocation:
  agent: vp-onboarding
  target_repo: {repo_root_path}
  mode: bootstrap
  wait_for_completion: true
  on_success:
    - Re-read {repo}/.cursor/agents/ to discover new agents
    - Update agent registry for this repo
    - Proceed with original task routing
  on_failure:
    - Mark task as blocked
    - Report: "Cannot execute task - project agents not available"
    - Suggest: "Run vp-onboarding manually on {repo_name}"
```

### Agent Resolution Order

```
For any task targeting a specific repo:

1. Project-level executor (preferred):
   - {repo}/.cursor/agents/tech-lead.md
   - Owns: Project knowledge, coordinates dev/sme/qa agents

2. If tech-lead missing:
   - Trigger: vp-onboarding to create tech-lead
   - Wait for completion before proceeding

3. Org-level agents (via CTO delegation):
   - For architectural review: vp-architecture
   - For security review: ciso
   - For performance review: vp-engineering
   - For documentation: docs-researcher
   - These never execute directly in repo — they advise tech-lead
```

## Pipeline Override Detection

Check for explicit pipeline directives before classification.

### Protocol

```
1. Check for explicit pipeline directive in user request
   - Pattern: /(?:use\s+)?pipeline:\s*(\S+)/i
   - Examples:
     - "use pipeline: security-review"
     - "pipeline: bug-fix"
   - If found → use specified pipeline, skip classification

2. Validate pipeline exists
   - Check: configurations/pipelines/{name}.yml exists
   - If valid → proceed with specified pipeline
   - If invalid → return error with available pipelines list

3. Extract available pipelines for error messages
   - List configurations/pipelines/*.yml
   - Return: "Pipeline '{name}' not found. Available: bug-fix, full-feature, ..."
```

### Override Precedence

1. Explicit `pipeline:` directive (highest)
2. Explicit agent list (via `@agent` mentions)
3. Classification-derived routing (lowest)

## Classification Protocol

Match user request against signal lists to determine task type.

### Signal Matching Algorithm

```
Input: user_request (string)
Output: task_type, confidence_score

1. Tokenize user_request (lowercase, split on whitespace/punctuation)
2. For each task_type in routing-table.yml:
   a. Count signal matches: overlap = signals ∩ tokens
   b. Calculate score: len(overlap) / len(signals)
   c. Store: {task_type, score, matches}
3. Rank by score descending
4. Apply tie-breaker: prefer higher complexity
   - high > medium > low
5. Return top-scoring task_type with matches
```

### Compound Rule Application

When multiple task types score above threshold (0.3):

```
1. Collect all task types with score >= 0.3
2. Check compound_rules for matching combinations
3. If compound rule matches:
   - Use compound rule's pipeline
   - Merge always_include agents with default_agents
4. If no compound rule:
   - Use highest-scoring task type's defaults
   - Log other detected types for context
```

### Classification Output

```yaml
task_type: feature
confidence: 0.85
matched_signals: ["add", "implement", "new"]
secondary_types:
  - type: security
    confidence: 0.4
    matched_signals: ["auth"]
compound_rule_applied: ["feature", "security"]
```

## Routing Protocol

Determine pipeline and agents from classification.

### Routing Algorithm

```
Input: task_type, compound_types (optional)
Output: pipeline, agents[], requires_plan, complexity

1. Load task_type config from routing-table.yml
2. Set base values:
   - pipeline = task_type.default_pipeline
   - agents = task_type.default_agents
   - requires_plan = task_type.requires_plan
   - complexity = task_type.complexity

3. Apply always_include:
   - If task_type.always_include exists:
     agents = union(agents, always_include)

4. Apply compound rules (if compound_types provided):
   - For each compound_rule where if ⊆ compound_types:
     - Override pipeline with compound_rule.pipeline
     - Add compound_rule.always_include to agents

5. Deduplicate agents, preserve order

6. Return routing result
```

### Routing Output

```yaml
pipeline: full-feature
agents: [cto, senior-dev, ciso]
requires_plan: true
complexity: high
routing_reason: "Compound rule applied: feature + security"
```

## Task State Machine

Full lifecycle tracking for orchestrated tasks.

### States

```
pending      → classified    (task type determined)
classified   → routed        (pipeline + agents selected)
routed       → running       (first stage started)
running      → stage_done    (stage completed successfully)
stage_done   → running       (next stage started)
stage_done   → success       (all stages done)
running      → failed        (stage failed)
failed       → retrying      (retry count < max)
retrying     → running       (retry started)
failed       → dead_letter   (retries exhausted)
dead_letter  → pending       (manual re-queue by user)
any          → cancelled     (user cancels)
```

### State Transitions

| Current State | Event | Next State | Action |
|---|---|---|---|
| pending | classify | classified | Store task_type, confidence |
| classified | route | routed | Store pipeline, agents |
| routed | start_stage | running | Initialize first stage |
| running | stage_complete | stage_done | Store stage output |
| stage_done | next_stage | running | Initialize next stage |
| stage_done | all_complete | success | Merge outputs, finalize |
| running | stage_error | failed | Store error, check retries |
| failed | retry_available | retrying | Increment retry_count |
| retrying | retry_start | running | Re-execute failed stage |
| failed | retries_exhausted | dead_letter | Create dead letter entry |
| dead_letter | user_requeue | pending | Reset state, re-classify |
| * | user_cancel | cancelled | Store cancellation reason |

### Retry Policy

```yaml
max_retries: 3
backoff:
  type: exponential
  base_ms: 1000
  max_ms: 30000
retry_conditions:
  - timeout (stage exceeded time limit)
  - transient_error (network, rate limit)
  - partial_failure (some outputs missing)
no_retry:
  - validation_error
  - user_abort
  - security_violation
```

## Task State Tracking

Persistent state storage in session memory.

### Location

`session.current/` namespace in context-memory.

### File Naming

`task-{short_id}-{slug}.md`

- `short_id`: 6-character alphanumeric (e.g., `a1b2c3`)
- `slug`: Task description slug (e.g., `add-auth-flow`)

### Task File Schema

```yaml
---
entity_name: session.current.task.a1b2c3
namespace: session.current
category: task
task_id: task-a1b2c3-add-auth-flow
task_type: feature
pipeline: full-feature
current_stage: review
state: running
agents_used: [cto, senior-dev, ciso]
stages_completed: [classify, route, plan]
stages_remaining: [review, implement, verify]
retry_count: 0
max_retries: 3
started_at: 2026-04-04T10:00:00Z
updated_at: 2026-04-04T10:15:00Z
tags: [task, feature, auth]
status: accepted
---

## Task Description

Add authentication flow with JWT tokens.

## Stage Outputs

### classify
- task_type: feature
- confidence: 0.85
- secondary: [security]

### route
- pipeline: full-feature
- agents: [cto, senior-dev, ciso]
- compound_rule: feature + security

### plan
- phases: 4
- estimated_steps: 12
- risks: 2 identified
```

### State Updates

Every state transition must:

1. Update `state` field
2. Update `updated_at` timestamp
3. Append stage output if applicable
4. Move completed stages to `stages_completed`
5. Remove from `stages_remaining`

## Output Merging Protocol

Combine outputs from parallel pipeline stages.

### Merge Algorithm

```
Input: stage_outputs[] (from parallel stages)
Output: merged_output

1. Group outputs by artifact type:
   - summaries, risks, recommendations, code_changes

2. For each artifact type:
   a. Concatenate with stage headers:
      "### {stage_name}\n{content}\n"
   b. Deduplicate overlapping concerns:
      - Exact match → keep first
      - Semantic overlap → merge into single item
   c. Cap at 500 tokens per artifact type

3. Resolve conflicts:
   - Contradictory recommendations → flag for user review
   - Different risk assessments → use highest severity

4. Return merged_output with:
   - Combined summaries
   - Unified risk register
   - Consolidated recommendations
   - Merged code changes (if any)
```

### Merge Output Format

```markdown
## Merged Stage Outputs

### Summary
{combined summaries from all stages}

### Risks
| Source | Risk | Severity | Mitigation |
|---|---|---|---|
| vp-architecture | ... | high | ... |
| ciso | ... | critical | ... |

### Recommendations
1. {deduplicated recommendation 1}
2. {deduplicated recommendation 2}

### Conflicts Requiring Review
- {stage_a} says X, but {stage_b} says Y
```

## Dead Letter Protocol

Handle tasks that exhaust retries.

### Dead Letter Entry

Location: `session.current/dead-letter-{task_id}.md`

```yaml
---
entity_name: session.current.dead_letter.a1b2c3
namespace: session.current
category: dead_letter
original_task_id: task-a1b2c3-add-auth-flow
failed_stage: implement
retry_count: 3
failure_chain:
  - attempt: 1
    error: timeout
    timestamp: 2026-04-04T10:30:00Z
  - attempt: 2
    error: timeout
    timestamp: 2026-04-04T10:32:00Z
  - attempt: 3
    error: validation_error
    timestamp: 2026-04-04T10:35:00Z
strategies_attempted:
  - retry with backoff
  - reduced scope
  - alternative agent
tags: [dead_letter, failed, auth]
status: accepted
created_at: 2026-04-04T10:35:00Z
---

## Original Task

Add authentication flow with JWT tokens.

## Failure Analysis

Task failed at implement stage after 3 retries.

### Error Chain

1. **Attempt 1** (timeout): Stage exceeded 60s limit
2. **Attempt 2** (timeout): Stage exceeded 60s limit
3. **Attempt 3** (validation_error): Generated code failed linting

### Agent Outputs

#### senior-dev (attempt 3)
```
Partial implementation created but lint errors:
- Missing import for AuthService
- Undefined variable: tokenExpiry
```

## Recovery Options

1. **Manual fix**: User addresses specific errors and re-queues
2. **Reduced scope**: Break task into smaller pieces
3. **Alternative approach**: Use different implementation strategy

## Re-queue

To re-queue this task: "retry task-a1b2c3"
```

### Re-queue Protocol

```
1. User requests: "retry task-{id}"
2. Find dead letter entry
3. Create new task entry with:
   - New task_id (new short_id, same slug)
   - original_task_id reference
   - State: pending
   - Retry context attached
4. Remove dead letter entry
5. Process from classification (may use cached type)
```

## Integration Points

### With Routing Table

Read `configurations/routing-table.yml` for:
- Task type definitions and signals
- Default pipelines and agents
- Compound rules
- Fallback configuration

### With Pipeline Definitions

Read `configurations/pipelines/{name}.yml` for:
- Stage sequence
- Stage-specific agents
- Parallel stage configuration
- Success criteria

### With Context Memory

Use `context-memory` skill for:
- Task state persistence
- Dead letter storage
- Cross-session task lookup

### With CTO Agent

CTO agent uses this skill for:
- Initial task classification
- Agent selection guidance
- Pipeline recommendation

Note: Orchestrator classification is advisory. CTO can override with documented reason.

## Usage Examples

### Basic Classification

```
Input:
  task_description: "Fix the login button not responding on mobile"

Process:
  1. No pipeline override detected
  2. Signal match: "fix" → bug_fix (0.5)
  3. No compound rules apply

Output:
  task_id: task-x7y8z9-fix-login-button
  task_type: bug_fix
  pipeline: bug-fix
  agents: [senior-dev]
  requires_plan: false
  complexity: low
```

### Compound Classification

```
Input:
  task_description: "Add user authentication with OAuth integration"

Process:
  1. No pipeline override detected
  2. Signal matches:
     - feature: "add" (0.33)
     - security: "auth" (0.25)
  3. Compound rule applies: feature + security

Output:
  task_id: task-a1b2c3-add-oauth-auth
  task_type: feature
  pipeline: full-feature
  agents: [cto, senior-dev, ciso]
  requires_plan: true
  complexity: high
```

### Explicit Pipeline Override

```
Input:
  task_description: "pipeline: security-review - Review the new API endpoints"

Process:
  1. Pipeline override detected: "security-review"
  2. Validate: configurations/pipelines/security-review.yml exists
  3. Skip classification, use specified pipeline

Output:
  task_id: task-d4e5f6-review-api-endpoints
  task_type: security (inferred from pipeline)
  pipeline: security-review
  agents: [ciso, senior-dev]
  requires_plan: true
  complexity: high
```
