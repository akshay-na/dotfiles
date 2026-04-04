---
name: pipeline-executor
description: Declarative pipeline execution with stages, conditions, data passing, and rollback. Use when executing multi-stage workflows.
version: 1
input_schema:
  required:
    - name: pipeline_name
      type: string
      description: Name of pipeline to execute (maps to configurations/pipelines/{name}.yml)
    - name: task_id
      type: string
      description: Task ID for state tracking
  optional:
    - name: initial_inputs
      type: object
      description: Initial data to pass to first stage
    - name: skip_stages
      type: string[]
      description: Stage IDs to skip
    - name: start_from_stage
      type: string
      description: Stage ID to resume from (for retries)
output_schema:
  required:
    - name: status
      type: string
      description: Pipeline result - success, failed, cancelled
    - name: stages_executed
      type: object[]
      description: List of executed stages with outcomes
  optional:
    - name: artifacts
      type: object
      description: Collected outputs from all stages
    - name: failed_stage
      type: string
      description: Stage ID where failure occurred
    - name: rollback_performed
      type: boolean
      description: Whether rollback was triggered
pre_checks:
  - description: Pipeline file exists
    validation: configurations/pipelines/{pipeline_name}.yml exists
  - description: Task ID is valid format
    validation: task_id matches pattern ^task-[a-z0-9]{6}-[a-z0-9-]+$
post_checks:
  - description: Status is valid
    validation: status in [success, failed, cancelled]
  - description: All stages accounted for
    validation: stages_executed includes all non-skipped stages
cacheable: false
---

# Pipeline Executor

Declarative pipeline execution with stages, conditions, data passing, and rollback for the org-level orchestration system.

## Overview

This skill provides the execution protocol for running multi-stage pipelines. It handles:

1. **Pipeline loading** (YAML parsing and validation)
2. **Condition evaluation** (stage gating based on task metadata)
3. **Stage execution** (agent invocation with proper mode)
4. **Inter-stage data passing** (artifact storage and retrieval)
5. **User approval gates** (checkpoint pausing)
6. **Retry handling** (backoff strategies per stage)
7. **Rollback orchestration** (reverse order stage undo)

## Pipeline YAML Schema

Pipelines are defined in `configurations/pipelines/{name}.yml`:

```yaml
name: string           # unique pipeline identifier
description: string    # what this pipeline does
version: number        # schema version
max_retries: number    # pipeline-level retry cap (default 5)

stages:
  - id: string                 # unique within pipeline
    agent: string              # agent name (tech-lead for execution, org agents for review)
    mode: plan | agent         # execution mode
    description: string        # what this stage does
    inputs: string[]           # artifact keys from prior stages
    outputs: string[]          # artifact keys this stage produces
    condition: string          # evaluated against task metadata (optional)
    requires_approval: boolean # pause for user (default false)
    timeout_minutes: number    # max duration (default 30)
    retry:                     # stage-level retry config (optional)
      max_attempts: number     # default 3
      backoff: exponential | linear | fixed
      initial_delay_seconds: number
    rollback:                  # how to undo this stage (optional)
      strategy: git_revert | file_restore | memory_cleanup | manual
      description: string
    skill: string              # skill to load for this stage (optional)
```

### Field Descriptions

| Field | Required | Description |
|-------|----------|-------------|
| `id` | Yes | Unique identifier within the pipeline |
| `agent` | Yes | Agent to execute this stage |
| `mode` | Yes | `plan` for read-only review, `agent` for implementation |
| `description` | Yes | Human-readable purpose |
| `inputs` | No | Artifact keys from prior stages to load |
| `outputs` | No | Artifact keys this stage will produce |
| `condition` | No | Expression that must evaluate true for stage to run |
| `requires_approval` | No | If true, pause and wait for user confirmation |
| `timeout_minutes` | No | Maximum stage duration (default 30) |
| `retry` | No | Stage-level retry configuration |
| `rollback` | No | Strategy for undoing this stage on failure |
| `skill` | No | Skill to load before executing the stage |

## Pipeline Loading Protocol

```
Input: pipeline_name
Output: pipeline_config, validation_result

1. Resolve pipeline path:
   - Path: configurations/pipelines/{pipeline_name}.yml
   - If not found → ERROR: "Pipeline '{name}' not found"

2. Parse YAML:
   - Load file contents
   - Parse as YAML
   - If parse error → ERROR: "Invalid YAML in pipeline '{name}'"

3. Validate schema:
   - Check required fields: name, description, version, stages
   - Check stages array is non-empty
   - For each stage:
     - Validate required: id, agent, mode, description
     - Validate mode in [plan, agent]
     - Validate inputs reference existing outputs from prior stages
     - Validate rollback.strategy if present

4. Check agent availability:
   - For each unique agent in stages:
     - Check agent exists (org-level or project-level)
     - If missing → ERROR: "Agent '{agent}' not found for stage '{id}'"

5. Return validated config
```

### Validation Rules

```yaml
validation_rules:
  stage_ids:
    - Must be unique within pipeline
    - Must match pattern: ^[a-z][a-z0-9_]*$
  
  input_references:
    - Each input must match an output from a prior stage
    - First stage can only use initial_inputs
  
  mode_restrictions:
    - Org agents (cto, vp-*, ciso, staff-engineer, sre-lead) should use mode: plan
    - tech-lead uses mode: agent for implementation
    - Exception: cto can use mode: agent for orchestration
  
  retry_config:
    - max_attempts: 1-10
    - backoff: exponential, linear, or fixed
    - initial_delay_seconds: 1-300
  
  rollback_strategy:
    - git_revert: Revert commits made during stage
    - file_restore: Restore files from backup
    - memory_cleanup: Remove memory entries
    - manual: Describe steps for user
```

## Condition Evaluation

Conditions gate stage execution based on task metadata.

### Evaluation Protocol

```
Input: condition_string, task_metadata
Output: should_execute (boolean)

1. Parse condition:
   - Extract variable references
   - Build expression tree

2. Bind variables from task_metadata:
   - complexity: "low" | "medium" | "high"
   - task_type: string (from classification)
   - tags: string[] (task tags)
   - always_include: string[] (agents that must run)
   - stage_outputs: object (outputs from prior stages)

3. Evaluate expression:
   - Comparison operators: ==, !=, in, not in
   - Logical operators: and, or, not
   - Parentheses for grouping

4. Return boolean result
```

### Condition Examples

```yaml
# Run only for high complexity tasks
condition: "complexity == 'high'"

# Run for security-related tasks
condition: "task_type == 'security'"

# Run if CISO review was requested
condition: "'ciso' in always_include"

# Run for high or medium complexity
condition: "complexity in ['high', 'medium']"

# Compound condition
condition: "task_type == 'feature' and complexity == 'high'"

# Check prior stage output
condition: "stage_outputs.architecture_review.risks_identified > 0"
```

### Condition Variables

| Variable | Type | Source | Description |
|----------|------|--------|-------------|
| `complexity` | string | Task classification | "low", "medium", "high" |
| `task_type` | string | Task classification | Classified task type |
| `tags` | string[] | Task metadata | Tags from task |
| `always_include` | string[] | Routing | Agents that must participate |
| `stage_outputs` | object | Prior stages | Outputs keyed by stage ID |

## Stage Execution Protocol

Execute a single stage within the pipeline.

### Execution Flow

```
Input: stage_config, task_metadata, prior_artifacts
Output: stage_result, artifacts

1. Evaluate condition:
   - If condition present and evaluates false:
     - Log: "Stage '{id}' skipped: condition not met"
     - Return: {status: skipped, reason: condition_false}

2. Load stage's agent:
   - Org agents: ~/.cursor/agents/{agent}.md
   - Project agents: {repo}/.cursor/agents/{agent}.md
   - If not found → ERROR

3. Run pre-action rule enforcement:
   - Load rule-enforcement skill
   - Execute: pre_action_check(agent, stage.description, task_id)
   - If blocked → stage fails with rule violation

4. Load stage skill (if specified):
   - Read skill from .cursor/skills/{skill}/SKILL.md
   - Attach to agent context

5. Prepare inputs:
   - For each input key in stage.inputs:
     - Load artifact from session.current/artifact-{task_id}-{source_stage}.md
     - Extract relevant output keys
     - Cap at 500 tokens per artifact
   - Merge with task context

6. Execute agent:
   - Switch to stage.mode (plan or agent)
   - Pass: task description, inputs, stage.description
   - Monitor: timeout_minutes
   - Capture: outputs, errors, metrics

7. Handle result:
   - If success:
     - Store outputs as artifacts
     - Update task state
   - If timeout:
     - Check retry config
     - Either retry or fail
   - If error:
     - Check retry config
     - Either retry or trigger rollback

8. Run post-action rule enforcement:
   - Execute: post_action_check(agent, stage_result, task_id)
   - Log any violations

9. Log metrics:
   - Duration, token usage, retry count
   - Write to session.current/metrics-{task_id}.md

10. Return stage_result with:
    - status: success | failed | skipped | timeout
    - outputs: artifact keys produced
    - duration_ms: execution time
    - retry_count: attempts made
```

### Mode Execution

```yaml
plan_mode:
  description: Read-only review and analysis
  allowed_actions:
    - Read files
    - Search codebase
    - Query memory
    - Generate recommendations
  forbidden_actions:
    - Write files
    - Execute shell commands
    - Modify memory

agent_mode:
  description: Full implementation capabilities
  allowed_actions:
    - All read operations
    - Write files
    - Execute shell commands
    - Modify memory
    - Spawn subagents (tech-lead only)
```

## Inter-Stage Data Passing

Artifacts flow between stages through the memory system.

### Artifact Storage

Location: `session.current/artifact-{task_id}-{stage_id}.md`

```yaml
---
entity_name: session.current.artifact.{task_id}.{stage_id}
namespace: session.current
category: artifact
task_id: task-a1b2c3-feature-name
stage_id: plan
agent: cto
status: success
summary: "Created 4-phase implementation plan with security considerations"
output_keys: [implementation_plan]
token_count: 450
created_at: 2026-04-04T10:15:00Z
tags: [artifact, plan, cto]
---

## implementation_plan

### Phase 1: Foundation
- Set up authentication middleware
- Create session management
- Estimated steps: 3

### Phase 2: Integration
- Connect OAuth providers
- Handle token refresh
- Estimated steps: 4

### Phase 3: Security Hardening
- Add rate limiting
- Implement audit logging
- Estimated steps: 3

### Phase 4: Testing
- Unit tests for auth flows
- Integration tests
- Estimated steps: 2
```

### Artifact Retrieval Protocol

```
Input: task_id, stage_id, required_keys[]
Output: artifact_data

1. Resolve artifact path:
   - Path: session.current/artifact-{task_id}-{stage_id}.md

2. Load artifact:
   - Read file
   - Parse frontmatter
   - Extract body content

3. Filter by required keys:
   - If required_keys specified:
     - Extract only matching sections
   - Else:
     - Use full artifact body

4. Apply token limit:
   - If content > 500 tokens:
     - Truncate with summary
     - Add: "[truncated - {n} tokens omitted]"

5. Return artifact_data with:
   - metadata: frontmatter fields
   - content: filtered body
   - token_count: actual tokens returned
```

### Artifact Token Limits

```
Per-artifact limit: 500 tokens
Per-stage input limit: 1500 tokens total (across all inputs)
Truncation strategy:
  1. Keep summary section intact
  2. Keep most recent content
  3. Truncate middle sections
  4. Add truncation marker
```

## User Approval Gates

Stages with `requires_approval: true` pause for user confirmation.

### Approval Protocol

```
Input: stage_config, stage_preview
Output: user_decision (proceed | abort)

1. Check requires_approval:
   - If false → skip, proceed automatically

2. Generate approval prompt:
   - Stage: {stage.id} - {stage.description}
   - Agent: {stage.agent}
   - Mode: {stage.mode}
   - Inputs: {summarized inputs}
   - Expected outputs: {stage.outputs}

3. Display to user:
   ---
   ## Approval Required: Stage '{stage.id}'
   
   **Description:** {stage.description}
   **Agent:** {stage.agent}
   **Mode:** {stage.mode}
   
   ### Inputs
   {input summaries}
   
   ### Expected Outputs
   {output list}
   
   Type `proceed` to continue or `abort` to cancel pipeline.
   ---

4. Wait for user response:
   - "proceed" | "yes" | "continue" → proceed
   - "abort" | "cancel" | "no" → abort
   - Other → re-prompt

5. Return decision:
   - proceed → continue pipeline
   - abort → trigger cancellation flow
```

### Abort Handling

```
On abort:
1. Mark pipeline as cancelled
2. Record abort point: stage.id
3. Check if rollback needed:
   - If prior stages modified state → offer rollback
   - If read-only → clean exit
4. Update task state to cancelled
5. Log: "Pipeline cancelled at stage '{id}' by user"
```

## Retry Handling

Stage-level retry with configurable backoff.

### Retry Configuration

```yaml
retry:
  max_attempts: 3        # 1-10, default 3
  backoff: exponential   # exponential, linear, fixed
  initial_delay_seconds: 5
```

### Backoff Strategies

```
exponential:
  delay(n) = initial_delay * 2^(n-1)
  Example (initial=5s): 5s, 10s, 20s, 40s...

linear:
  delay(n) = initial_delay * n
  Example (initial=5s): 5s, 10s, 15s, 20s...

fixed:
  delay(n) = initial_delay
  Example (initial=5s): 5s, 5s, 5s, 5s...
```

### Retry Protocol

```
Input: stage_config, error, attempt_count
Output: retry | fail

1. Check retry eligibility:
   - If no retry config → fail immediately
   - If attempt_count >= max_attempts → fail

2. Check error type:
   - Retryable: timeout, transient_error, partial_failure
   - Non-retryable: validation_error, user_abort, security_violation
   - If non-retryable → fail immediately

3. Calculate delay:
   - Apply backoff strategy
   - Cap at 5 minutes maximum

4. Wait for delay

5. Re-execute stage:
   - Increment attempt_count
   - Log: "Retry {n}/{max} for stage '{id}'"
   - Execute stage

6. On success → continue pipeline
7. On failure → repeat from step 1
```

### Retry Logging

```yaml
retry_log:
  stage_id: implement
  attempts:
    - attempt: 1
      status: failed
      error: timeout
      duration_ms: 60000
      timestamp: 2026-04-04T10:30:00Z
    - attempt: 2
      status: failed
      error: timeout
      duration_ms: 60000
      timestamp: 2026-04-04T10:31:10Z
    - attempt: 3
      status: success
      duration_ms: 45000
      timestamp: 2026-04-04T10:32:25Z
  total_duration_ms: 165000
  final_status: success
```

## Rollback Protocol

On failure, undo completed stages in reverse order.

### Rollback Strategies

| Strategy | Description | Actions |
|----------|-------------|---------|
| `git_revert` | Revert git commits | Find commits from stage, create revert commit |
| `file_restore` | Restore file backups | Copy from backup location |
| `memory_cleanup` | Remove memory entries | Delete artifacts, task state |
| `manual` | User instructions | Display rollback steps |

### Rollback Execution

```
Input: failed_stage_index, completed_stages[]
Output: rollback_result

1. Build rollback list:
   - Filter completed_stages where rollback is defined
   - Reverse order (most recent first)

2. For each stage to rollback:
   a. Log: "Rolling back stage '{id}'"
   
   b. Execute rollback strategy:
      
      git_revert:
        - Find commits with message containing task_id and stage_id
        - Create revert commit
        - Log: "Reverted {n} commits"
      
      file_restore:
        - Find backup at session.current/backup-{task_id}-{stage_id}/
        - Restore files to original locations
        - Log: "Restored {n} files"
      
      memory_cleanup:
        - Delete artifact files for this stage
        - Update task state
        - Log: "Cleaned memory entries"
      
      manual:
        - Display rollback.description to user
        - Wait for user confirmation
        - Log: "Manual rollback acknowledged"
   
   c. Record rollback result

3. Update pipeline state:
   - rollback_performed: true
   - rollback_stages: [list of rolled back stage ids]
   - rollback_status: success | partial | failed

4. Return rollback_result
```

### Rollback State Tracking

```yaml
rollback_state:
  triggered_by: implement
  trigger_error: validation_error
  stages_to_rollback: [implement, plan]
  rollback_results:
    - stage: implement
      strategy: git_revert
      status: success
      commits_reverted: 2
    - stage: plan
      strategy: memory_cleanup
      status: success
      entries_cleaned: 3
  overall_status: success
  completed_at: 2026-04-04T10:40:00Z
```

## Full Pipeline Execution Flow

Complete pipeline execution from start to finish.

### Execution Algorithm

```
Input: pipeline_name, task_id, initial_inputs, options
Output: pipeline_result

1. Load and validate pipeline:
   - Read configurations/pipelines/{pipeline_name}.yml
   - Validate schema and agent availability
   - If error → return {status: failed, error: validation}

2. Initialize task state:
   - Create/update session.current/task-{task_id}.md
   - Set: pipeline, state=running, stages_remaining
   - Store initial_inputs as artifact

3. Determine starting point:
   - If start_from_stage → find stage index
   - Else → start at index 0

4. Execute stages sequentially:
   For each stage from start_index:
   
   a. Check skip list:
      - If stage.id in skip_stages → skip
   
   b. Execute stage:
      - Follow Stage Execution Protocol
   
   c. Handle result:
      - success → store artifacts, continue
      - skipped → log, continue
      - failed:
        - If retries available → retry
        - Else → trigger rollback, exit loop
   
   d. Check approval gate:
      - If requires_approval → wait for user
      - If abort → trigger cancellation

5. Finalize:
   - Merge all stage outputs
   - Update task state to success/failed/cancelled
   - Generate pipeline summary

6. Return pipeline_result:
   - status: success | failed | cancelled
   - stages_executed: [{id, status, duration}...]
   - artifacts: merged outputs
   - failed_stage: id (if failed)
   - rollback_performed: boolean
```

### Pipeline State Machine

```
States:
  initializing → Pipeline loaded, task state created
  running      → Actively executing stages
  waiting      → Paused at approval gate
  retrying     → Retrying failed stage
  rolling_back → Executing rollback
  success      → All stages completed
  failed       → Stage failed, rollback complete
  cancelled    → User aborted

Transitions:
  initializing → running      (start execution)
  running      → waiting      (approval gate reached)
  waiting      → running      (user approved)
  waiting      → cancelled    (user aborted)
  running      → retrying     (stage failed, retries available)
  retrying     → running      (retry succeeded)
  retrying     → rolling_back (retries exhausted)
  running      → rolling_back (non-retryable failure)
  rolling_back → failed       (rollback complete)
  running      → success      (all stages done)
```

## Integration Points

### With Task Orchestration

Task orchestration skill calls pipeline-executor:

```
1. Task classified and routed
2. Pipeline selected (e.g., full-feature)
3. Call pipeline-executor with:
   - pipeline_name: "full-feature"
   - task_id: from orchestration
   - initial_inputs: {task_description, context}
4. Pipeline executor runs stages
5. Return result to orchestration for state update
```

### With Rule Enforcement

Each stage checks rules:

```
Pre-action:
  - Load rule-enforcement skill
  - Check agent permissions for stage action
  - Block if rule violation

Post-action:
  - Validate stage outputs against constraints
  - Log any warnings
```

### With Context Memory

All state persisted to memory:

```
Task state:     session.current/task-{task_id}.md
Artifacts:      session.current/artifact-{task_id}-{stage}.md
Metrics:        session.current/metrics-{task_id}.md
Dead letters:   session.current/dead-letter-{task_id}.md
```

## Usage Examples

### Execute Full Feature Pipeline

```
Input:
  pipeline_name: full-feature
  task_id: task-a1b2c3-add-auth
  initial_inputs:
    task_description: "Add OAuth2 authentication"
    complexity: high
    task_type: feature
    always_include: [ciso]

Execution:
  1. plan (cto, plan mode) → implementation_plan
  2. architecture_review (vp-architecture) → architecture_review [conditional: high complexity]
  3. security_review (ciso) → security_review [conditional: ciso in always_include]
  4. implement (tech-lead, agent mode) → code_changes [approval gate]
  5. observability_review (sre-lead) → observability_review
  6. quality_review (staff-engineer) → quality_review

Output:
  status: success
  stages_executed: [plan, architecture_review, security_review, implement, observability_review, quality_review]
  artifacts: {merged outputs}
```

### Execute Bug Fix with Retry

```
Input:
  pipeline_name: bug-fix
  task_id: task-x7y8z9-fix-login
  initial_inputs:
    task_description: "Fix login button not responding"
    error_context: "Button click event not firing on mobile"

Execution:
  1. diagnose (tech-lead) → diagnosis, affected_files
  2. fix (tech-lead) → code_changes [fails on first attempt]
     - Retry 1: backoff 5s, re-execute → fails
     - Retry 2: backoff 10s, re-execute → success
  3. verify (tech-lead) → verification_results

Output:
  status: success
  stages_executed: [diagnose, fix (3 attempts), verify]
  artifacts: {diagnosis, code_changes, verification_results}
```

### Resume from Failed Stage

```
Input:
  pipeline_name: full-feature
  task_id: task-a1b2c3-add-auth
  start_from_stage: implement
  initial_inputs: {loaded from prior artifacts}

Execution:
  - Skip: plan, architecture_review, security_review (already completed)
  - Start: implement
  - Continue: observability_review, quality_review

Output:
  status: success
  stages_executed: [implement, observability_review, quality_review]
```

## Error Handling

### Common Errors

| Error | Cause | Resolution |
|-------|-------|------------|
| Pipeline not found | Invalid pipeline_name | Check configurations/pipelines/ |
| Agent not found | Missing agent definition | Run vp-onboarding for project agents |
| Input artifact missing | Prior stage didn't produce output | Check stage outputs configuration |
| Condition parse error | Invalid condition syntax | Review condition documentation |
| Timeout | Stage exceeded time limit | Increase timeout or optimize stage |
| Rollback failed | Rollback strategy couldn't complete | Manual intervention required |

### Error Recovery

```
1. Timeout errors:
   - Check if stage is making progress
   - Consider increasing timeout_minutes
   - Split into smaller stages if needed

2. Validation errors:
   - Non-retryable
   - Review stage outputs for issues
   - Fix and re-run with start_from_stage

3. Rollback failures:
   - Check git status for uncommitted changes
   - Manually verify state
   - Use manual rollback strategy
```
