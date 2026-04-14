---
name: cross-stage-feedback
description: Structured feedback propagation between pipeline stages. Use when review stages produce findings that should trigger re-implementation.
version: 1
input_schema:
  required:
    - name: source_stage
      type: string
      description: Reviewer stage ID that produced the feedback
    - name: target_stage
      type: string
      description: Implementation stage ID to receive feedback
    - name: feedback_items
      type: object[]
      description: Array of feedback items from the review stage
    - name: task_id
      type: string
      description: Task ID for tracking
  optional:
    - name: iteration
      type: number
      description: Current feedback loop iteration count
      default: 1
    - name: max_iterations
      type: number
      description: Maximum iterations before escalation
      default: 2
output_schema:
  required:
    - name: action
      type: string
      description: Next action - re_implement, accept, or escalate
    - name: iteration_count
      type: number
      description: Updated iteration count
  optional:
    - name: filtered_feedback
      type: object[]
      description: Actionable feedback items only (blocking items)
    - name: implementation_brief
      type: string
      description: Concise brief for the target stage (capped at 500 tokens)
    - name: escalation_context
      type: object
      description: Full context if escalation triggered
pre_checks:
  - description: Source stage is a review stage
    validation: source_stage ends with "_review" or "_verify" or is in [quality_review, security_verify, observability_review]
  - description: Target stage is an implementation stage
    validation: target_stage in [implement, fix, refactor]
  - description: Feedback items array exists
    validation: feedback_items is array
post_checks:
  - description: Action is valid
    validation: action in [re_implement, accept, escalate]
  - description: Iteration count is tracked
    validation: iteration_count >= 1
cacheable: false
---

# Cross-Stage Feedback

Enables review stages to send structured feedback back to implementation stages for automated fixing, with iteration caps to prevent infinite loops.

## Overview

When a review stage (quality_review, security_verify, observability_review) produces feedback, this skill:

1. Parses feedback into structured items
2. Filters for actionable (blocking) items
3. Checks iteration budget
4. Either triggers re-implementation or escalates to user

## Feedback Item Schema

```yaml
feedback_item:
  severity: blocking | advisory | informational
  file: string            # File path
  line: number | null     # Line number if applicable
  description: string     # What's wrong
  suggested_fix: string   # How to fix
  source_agent: string    # Which reviewer (ciso, staff-engineer, sre-lead)
  gate_id: string | null  # Which quality gate triggered this, if any
```

### Severity Levels

| Severity | Behavior | Example |
|----------|----------|---------|
| `blocking` | Triggers re-implementation | Security vulnerability, broken functionality |
| `advisory` | Logged, does not block | Code style suggestion, minor improvement |
| `informational` | Logged only | FYI notes, documentation suggestions |

## Protocol

### Step 1: Parse Feedback

```
Input: feedback_items[]
Output: parsed_items[]

For each item in feedback_items:
  Validate required fields:
    - severity (must be blocking | advisory | informational)
    - description (non-empty string)
  
  Normalize item:
    - Ensure file path is relative to repo root
    - Extract line number if embedded in description
    - Identify source agent from context
  
  Add to parsed_items[]

Log: "[cross-stage-feedback] Parsed {n} feedback items from {source_stage}"
```

### Step 2: Filter for Actionable Items

```
Input: parsed_items[]
Output: blocking_items[], advisory_items[]

blocking_items = filter(parsed_items, severity == "blocking")
advisory_items = filter(parsed_items, severity == "advisory")

# Advisory items are logged but don't trigger re-implementation
For each advisory in advisory_items:
  Log: "[cross-stage-feedback] Advisory: {description} ({file})"

Log: "[cross-stage-feedback] {len(blocking_items)} blocking, {len(advisory_items)} advisory"
```

### Step 3: Check Iteration Budget

```
Input: iteration, max_iterations, blocking_items[]
Output: action (re_implement | accept | escalate)

1. Load iteration state:
   - Path: session.current/feedback-{task_id}-{source_stage}-{target_stage}.md
   - If exists: read current iteration count
   - If not: iteration = 1

2. Check budget:
   If len(blocking_items) == 0:
     action = accept
     Log: "[cross-stage-feedback] No blocking items, accepting"
   
   Else if iteration >= max_iterations:
     action = escalate
     Log: "[cross-stage-feedback] Iteration cap reached ({iteration}/{max_iterations}), escalating"
   
   Else:
     action = re_implement
     iteration = iteration + 1
     Log: "[cross-stage-feedback] Triggering re-implementation (iteration {iteration})"

3. Update iteration state:
   Write to session.current/feedback-{task_id}-{source_stage}-{target_stage}.md:
   ---
   entity_name: session.current.feedback.{task_id}.{source_stage}.{target_stage}
   namespace: session.current
   category: feedback-loop
   task_id: {task_id}
   source_stage: {source_stage}
   target_stage: {target_stage}
   iteration: {iteration}
   max_iterations: {max_iterations}
   last_action: {action}
   updated_at: {timestamp}
   ---
```

### Step 4: Format Implementation Brief

```
Input: blocking_items[], action
Output: implementation_brief (string, max 500 tokens)

If action != re_implement:
  Return null (no brief needed)

Format brief:
  ## Feedback Loop: Iteration {iteration}
  
  **Source:** {source_stage} ({source_agent})
  **Target:** {target_stage}
  
  ### Issues to Address
  
  {For each blocking_item, max 5:}
  1. **{file}:{line}** - {description}
     Fix: {suggested_fix}
  
  {If more than 5 blocking items:}
  ... and {n} more issues. See full feedback in session memory.
  
  ### Priority
  Address issues in order listed. Security issues first.

Enforce 500 token cap:
  If brief > 500 tokens:
    Truncate to top 3 issues
    Add: "See full feedback in session.current/feedback-{task_id}-*.md"
```

### Step 5: Handle Escalation

```
Input: blocking_items[], iteration, task_id
Output: escalation_context

If action == escalate:
  Build escalation context:
    escalation_context = {
      task_id: task_id,
      feedback_source: source_stage,
      iterations_attempted: iteration,
      blocking_issues: blocking_items,
      full_history: load_all_feedback_files(task_id)
    }
  
  Format user message:
    ---
    ## Feedback Loop Escalation
    
    **Task:** {task_id}
    **Source:** {source_stage}
    **Iterations:** {iteration} (cap: {max_iterations})
    
    ### Unresolved Issues
    
    The following blocking issues could not be auto-resolved:
    
    {For each blocking_item:}
    - **{file}:{line}** - {description}
    
    ### Feedback History
    
    {Summarized history of all iterations}
    
    ### Options
    
    1. Fix manually and retry the task
    2. Override and accept current state
    3. Abort the task
    ---
  
  Return escalation_context
```

## Integration with Pipeline Executor

The pipeline executor invokes this skill after review stages complete:

```yaml
# In pipeline-executor, after review stage completes:
if stage.outputs contains feedback_items:
  if any(feedback_items, severity == "blocking"):
    result = invoke("cross-stage-feedback", {
      source_stage: stage.id,
      target_stage: stage.feedback_loop.target_stage,
      feedback_items: stage.outputs.feedback_items,
      task_id: task_id,
      iteration: current_iteration,
      max_iterations: stage.feedback_loop.max_iterations
    })
    
    if result.action == "re_implement":
      # Re-run target stage with feedback as additional input
      re_run_stage(
        stage_id: target_stage,
        additional_input: result.implementation_brief
      )
    
    elif result.action == "escalate":
      # Pause pipeline, present to user
      pause_pipeline(escalation_context: result.escalation_context)
    
    elif result.action == "accept":
      # Continue pipeline normally
      continue
```

## Review Stages That Can Trigger Feedback

| Stage | Agent | Typical Feedback |
|-------|-------|------------------|
| `quality_review` | staff-engineer | Code quality, maintainability, patterns |
| `security_verify` | ciso | Security vulnerabilities, auth issues |
| `observability_review` | sre-lead | Missing metrics, logging gaps |

## Iteration Defaults by Pipeline

| Pipeline | Default max_iterations | Rationale |
|----------|----------------------|-----------|
| full-feature | 2 | Balance between quality and velocity |
| bug-fix | 2 | Bug fixes should converge quickly |
| refactor | 2 | Refactors need quality but not perfection |
| security-review | 1 | Security issues escalate quickly |
| performance | 2 | Performance work may need iteration |

## Feedback Output Convention

Review stages that want to trigger feedback loops must produce outputs in this format:

```yaml
# In review stage output:
outputs:
  quality_review:
    summary: "Found 3 issues requiring attention"
    feedback_items:
      - severity: blocking
        file: src/api/auth.ts
        line: 42
        description: "Authentication bypass possible via null session check"
        suggested_fix: "Add explicit null check before session validation"
        source_agent: staff-engineer
      - severity: advisory
        file: src/api/auth.ts
        line: 55
        description: "Consider extracting session validation to helper function"
        suggested_fix: "Create validateSession() helper for reuse"
        source_agent: staff-engineer
```

## Metrics Captured

```yaml
per_feedback_loop:
  task_id: string
  source_stage: string
  target_stage: string
  iterations: number
  blocking_items_initial: number
  blocking_items_final: number
  resolved_without_escalation: boolean
  escalated: boolean
  total_duration_ms: number

aggregated:
  feedback_loop_success_rate: number  # % resolved without escalation
  avg_iterations_to_resolve: number
  most_common_feedback_sources: [{stage, count}]
  escalation_rate_by_stage: {stage: rate}
```

## Logging Format

```
[cross-stage-feedback] task={task_id} source={source} target={target} items={n} blocking={n}
[cross-stage-feedback] task={task_id} action={action} iteration={n}/{max}
[cross-stage-feedback] task={task_id} escalated reason="iteration_cap_reached"
```

## Usage Example

```yaml
Input:
  source_stage: quality_review
  target_stage: implement
  feedback_items:
    - severity: blocking
      file: src/utils/parser.ts
      line: 23
      description: "Potential null pointer dereference"
      suggested_fix: "Add null check before accessing data.items"
      source_agent: staff-engineer
    - severity: advisory
      file: src/utils/parser.ts
      line: 45
      description: "Consider using optional chaining"
      suggested_fix: "Replace data && data.items with data?.items"
      source_agent: staff-engineer
  task_id: task-a1b2c3-add-parser
  iteration: 1
  max_iterations: 2

Execution:
  1. Parse: 2 items (1 blocking, 1 advisory)
  2. Filter: blocking_items = [null pointer issue]
  3. Check budget: iteration 1 < max 2, action = re_implement
  4. Format brief:
     "## Feedback Loop: Iteration 2
      
      **Source:** quality_review (staff-engineer)
      **Target:** implement
      
      ### Issues to Address
      
      1. **src/utils/parser.ts:23** - Potential null pointer dereference
         Fix: Add null check before accessing data.items"

Output:
  action: re_implement
  iteration_count: 2
  filtered_feedback: [null pointer issue]
  implementation_brief: <formatted brief>
```
