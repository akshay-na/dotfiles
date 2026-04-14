---
name: closed-loop-execution
description: Generate → execute → fail → analyze → fix → repeat cycle with failure pattern recognition. Use when implementing changes that need verification and automatic recovery.
version: 1
input_schema:
  required:
    - name: task_id
      type: string
      description: Task ID for state tracking
    - name: action
      type: object
      description: What to generate/execute (code change, command, etc.)
  optional:
    - name: success_criteria
      type: string[]
      description: Explicit success criteria (overrides defaults)
    - name: max_retries
      type: number
      description: Maximum retry attempts (default 3)
    - name: previous_attempts
      type: object[]
      description: History of previous attempts for context
output_schema:
  required:
    - name: status
      type: string
      description: Result - success, failed, escalated
    - name: attempts
      type: number
      description: Number of attempts made
  optional:
    - name: result
      type: object
      description: Final output if successful
    - name: failure_pattern
      type: string
      description: Identified failure pattern if failed
    - name: escalation_reason
      type: string
      description: Why escalation was needed
pre_checks:
  - description: Task ID is valid
    validation: task_id matches pattern ^task-[a-z0-9]{6}-[a-z0-9-]+$
  - description: Action is provided
    validation: action is not empty
post_checks:
  - description: Status is valid
    validation: status in [success, failed, escalated]
  - description: Attempts recorded
    validation: attempts >= 1
cacheable: false
---

# Closed-Loop Execution

Generate → execute → fail → analyze → fix → repeat cycle with failure pattern recognition and automatic escalation for the org-level orchestration system.

## Overview

This skill implements the core execution loop that:

1. **Generates** code changes, configs, or commands
2. **Executes** the generated output
3. **Evaluates** against success criteria
4. **Analyzes** failures using pattern matching
5. **Fixes** issues using strategy-specific recovery
6. **Escalates** when automatic recovery fails

The loop continues until success, escalation, or retry budget exhaustion.

## Execution Loop Protocol

The closed-loop execution follows a strict state machine with seven phases.

### Phase Diagram

```
                    ┌─────────────┐
                    │   GENERATE  │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
              ┌─────│   VALIDATE  │─────┐
              │     └─────────────┘     │
              │ PASS                    │ FAIL
              ▼                         │
        ┌─────────────┐                 │
        │   EXECUTE   │                 │
        └──────┬──────┘                 │
               │                        │
               ▼                        │
        ┌─────────────┐                 │
  ┌─────│   EVALUATE  │─────┐           │
  │     └─────────────┘     │           │
  │ PASS                    │ FAIL      │
  ▼                         ▼           │
┌──────────┐          ┌─────────────┐   │
│ SUCCESS  │          │   ANALYZE   │◄──┘
└──────────┘          └──────┬──────┘
                             │
                ┌────────────┼────────────┐
                │            │            │
                ▼            ▼            ▼
          ┌──────────┐ ┌──────────┐ ┌─────────────┐
          │   FIX    │ │ ESCALATE │ │ DEAD LETTER │
          └────┬─────┘ └──────────┘ └─────────────┘
               │
               └───────────► GENERATE (loop, not VALIDATE)
```

### VALIDATE Phase (NEW)

Pre-execution validation catches errors before writing to disk.

```
Input: generated_output, target_files, task_type, task_id, complexity
Output: validation_result

1. Invoke pre-execution-validation skill:
   validation_result = invoke("pre-execution-validation", {
     generated_output: generated_output,
     target_files: action.files,
     task_type: task_context.task_type,
     task_id: task_id,
     complexity: task_context.complexity
   })

2. Handle result:
   
   If validation_result.passed == true:
     - Log: "[closed-loop] task={task_id} validation=passed gates={count}"
     - Proceed to EXECUTE phase
   
   If validation_result.passed == false:
     - Log: "[closed-loop] task={task_id} validation=failed violations={count}"
     - Route to ANALYZE phase with validation context:
       error_context = {
         source: "pre_validation",
         violations: validation_result.violations,
         gates_checked: validation_result.gates_checked
       }
     - ANALYZE treats validation failures like any other failure
     - After FIX, loop back to GENERATE (not VALIDATE)
       This ensures a clean regeneration rather than patching

3. Capture metrics:
   - pre_validation_runs: increment
   - pre_validation_passed: increment if passed
   - pre_validation_catches: append violation types
   - gates_run: validation_result.gates_checked.length
   - duration_ms: validation_result total duration
```

**Why loop to GENERATE, not VALIDATE:**

When validation fails, the FIX phase modifies the approach or expands context. Returning to GENERATE produces a fresh, clean output incorporating the fix. This is more reliable than trying to patch the invalid output.

### GENERATE Phase

Agent produces output for the current task.

```
Input: task_context, previous_error (if retry), strategy_hint (if retry)
Output: generated_output

1. Load task context:
   - Task description and requirements
   - Files to modify
   - Success criteria

2. If retry (previous_attempts > 0):
   - Load previous error context (summarized, <200 tokens)
   - Load strategy being applied
   - Load what was already tried
   - Adjust approach based on failure analysis
   - NOTE: Retries come from ANALYZE→FIX, not from VALIDATE
     (validation failures route through ANALYZE like any failure)

3. Generate output:
   - Code changes (file edits)
   - Configuration updates
   - Shell commands to run

4. Capture generation metadata:
   - Files targeted
   - Commands planned
   - Dependencies involved
   - Timestamp

5. Return:
   generated_output: {
     type: code_change | config_update | command,
     files: string[],
     commands: string[],
     description: string
   }

6. Next phase: VALIDATE (pre-execution validation)
```

### EXECUTE Phase

Apply the generated output.

```
Input: generated_output
Output: execution_result

1. Apply output based on type:

   code_change:
     - Write file modifications
     - Stage changes (git add)
     - Capture diff

   config_update:
     - Write config files
     - Validate syntax (YAML, JSON, TOML)
     - Capture before/after

   command:
     - Execute shell command
     - Capture stdout, stderr
     - Record exit code

2. Capture execution metadata:
   - Start time, end time
   - Files modified
   - Commands executed
   - stdout/stderr (truncated to 2000 chars)
   - Exit codes

3. Return:
   execution_result: {
     applied: boolean,
     files_modified: string[],
     commands_run: [{cmd, exit_code, stdout, stderr}],
     duration_ms: number
   }
```

### EVALUATE Phase

Run success criteria checks.

```
Input: execution_result, success_criteria[]
Output: evaluation_result

1. Determine success criteria:
   - If explicit criteria provided → use those
   - Else → load defaults from failure-patterns.yml based on task_type

2. Run each criterion:

   lint_check:
     - Run: npm run lint / biome check / etc.
     - Parse output for errors
     - Result: pass if exit_code == 0

   type_check:
     - Run: tsc --noEmit / pyright / etc.
     - Parse output for type errors
     - Result: pass if exit_code == 0

   test_check:
     - Run: npm test / pytest / etc.
     - Parse output for failures
     - Result: pass if all tests pass

   build_check:
     - Run: npm run build / cargo build / etc.
     - Parse output for errors
     - Result: pass if exit_code == 0

   custom_check:
     - Execute custom command/script
     - Evaluate against expected output

3. Aggregate results:
   - ALL pass → proceed to SUCCESS
   - ANY fail → proceed to ANALYZE

4. Return:
   evaluation_result: {
     passed: boolean,
     checks: [{name, passed, output, duration_ms}],
     first_failure: {name, output} | null
   }
```

### ANALYZE Phase

Parse failure and match against known patterns.

```
Input: evaluation_result.first_failure
Output: analysis_result

1. Extract error output:
   - failure.output (full error message)
   - failure.name (which check failed)

2. Run pattern matching algorithm:
   - Input: error_output
   - Output: matched_pattern, confidence, strategy
   - See "Pattern Matching Algorithm" section

3. Check retry history:
   - Load attempts[] for this task
   - Find: same pattern seen before?
   - Find: same strategy attempted before?

4. Apply same-error escalation rule:
   - If same pattern + same strategy attempted before:
     - Must try alternate strategy OR escalate
     - See "Same-Error Escalation Rule" section

5. Check retry budget:
   - retry_count = len(attempts)
   - max_retries = task.max_retries or pattern.max_auto_retries or 3
   - If retry_count >= max_retries → proceed to DEAD LETTER

6. Select recovery path:
   - If pattern.strategy == escalate → ESCALATE
   - If retry budget exhausted → DEAD LETTER
   - If alternate strategy available → FIX with alternate
   - Else → FIX with pattern.strategy

7. Return:
   analysis_result: {
     pattern_id: string,
     confidence: number,
     strategy: string,
     same_pattern_count: number,
     retry_budget_remaining: number,
     next_action: fix | escalate | dead_letter
   }
```

### FIX Phase

Execute the recovery strategy.

```
Input: analysis_result, error_context
Output: fix_result

1. Load strategy from configurations/failure-patterns.yml:
   - strategy.description
   - strategy.steps[]

2. Execute strategy steps:

   auto_fix:
     a. Detect fix command:
        - npm run lint:fix / prettier --write
        - biome check --apply
        - eslint --fix
     b. Run fix command
     c. Verify fix resolved issue (re-run check)
     d. If resolved → return to GENERATE

   context_expand:
     a. Parse error for missing context:
        - Type definitions needed
        - Import sources needed
        - Related files needed
     b. Read additional files
     c. Summarize expanded context (<500 tokens)
     d. Return to GENERATE with context

   analyze_then_fix:
     a. Parse error location (file:line)
     b. Read surrounding code (±50 lines)
     c. Compare expected vs actual
     d. Generate targeted fix
     e. Apply fix
     f. Return to GENERATE

   dependency_check:
     a. Parse module name from error
     b. Check package manifest
     c. If missing: install dependency
     d. If present: check version conflicts
     e. Return to GENERATE

   retry_with_backoff:
     a. Calculate delay: 5s * 2^(attempt-1)
     b. Wait for delay
     c. Return to GENERATE (no changes)

3. Increment retry_count

4. Update task state in memory:
   - Append to attempts[]
   - Record strategy used
   - Record timestamp

5. Return:
   fix_result: {
     strategy_executed: string,
     fix_applied: string,
     context_expanded: boolean,
     ready_for_retry: boolean
   }
```

### DEAD LETTER Phase

Halt execution and persist failure for manual review.

```
Input: task_id, error_chain[], attempts[]
Output: dead_letter_entry

1. Compile full failure context:
   - task_id
   - Original task description
   - All attempts (summarized)
   - All patterns matched
   - All strategies tried
   - Final error state

2. Write dead-letter entry:
   - Location: session.current/dead-letter-{task_id}.md
   - Format: see "Dead Letter Format" section

3. Report to user:
   ---
   ## Execution Failed: {task_id}

   **Attempts made:** {attempts.length}
   **Patterns matched:** {unique patterns}
   **Strategies tried:** {unique strategies}

   ### Error Chain
   {chronological error summary}

   ### Suggested Manual Steps
   {based on final pattern}

   ### Files Modified
   {list of files touched}

   Task is now blocked. Address the issues manually and retry.
   ---

4. Update task state:
   - status: dead_letter
   - blocked_at: timestamp
   - blocked_reason: retry_budget_exhausted | unrecoverable_error

5. Halt execution
```

## Regression Detection Protocol

Catches regressions in dependent files after changes are applied.

### Complexity Gate

Regression detection is expensive. Skip it for low-complexity tasks:

```
Input: task_context.complexity
Output: run_regression_check (boolean)

1. Load complexity from task metadata:
   complexity = task_context.complexity  # low | medium | high

2. Check project-level override:
   If .cursor/configurations/verification-gates-local.yml exists:
     Load regression_detection.enabled_for_complexity
   Else:
     Use default: ["medium", "high"]

3. Evaluate gate:
   If complexity in enabled_for_complexity:
     run_regression_check = true
     Log: "[closed-loop] regression_check=enabled complexity={complexity}"
   Else:
     run_regression_check = false
     Log: "[closed-loop] regression_check=skipped complexity={complexity}"
```

### Baseline Capture (Before GENERATE)

```
Trigger: First iteration AND complexity gate passes

1. Identify files to be modified:
   target_files = action.files

2. Find dependent files:
   For each target_file:
     Find files that import/reference target_file
     Add to dependent_files[]
   
   Methods by language:
     TypeScript/JavaScript: Parse imports, check tsconfig paths
     Python: Parse imports, check __init__.py
     Go: Parse import statements

3. Capture baseline test results:
   For each file in (target_files + dependent_files):
     Run tests for this file
     Record: {file, test_count, pass_count, fail_count}
   
   Store as baseline_results

4. Store baseline:
   Write to session.current/baseline-{task_id}.md:
   ---
   entity_name: session.current.baseline.{task_id}
   namespace: session.current
   category: regression-baseline
   task_id: {task_id}
   target_files: [...]
   dependent_files: [...]
   baseline_results: [...]
   captured_at: {timestamp}
   ---
```

### Regression Check (After EVALUATE Passes)

```
Trigger: EVALUATE passes all checks AND run_regression_check is true

1. Load baseline:
   baseline = read(session.current/baseline-{task_id}.md)

2. Re-run tests for dependent files:
   For each file in baseline.dependent_files:
     Run tests for this file
     Record: {file, test_count, pass_count, fail_count}
   
   Store as current_results

3. Compare against baseline:
   regressions = []
   
   For each file in current_results:
     baseline_file = find(baseline.baseline_results, file)
     
     # New failures = regression
     new_failures = current_results.fail_count - baseline_file.fail_count
     
     If new_failures > 0:
       regressions.append({
         file: file,
         baseline_pass: baseline_file.pass_count,
         current_pass: current_results.pass_count,
         new_failures: new_failures
       })

4. Handle results:
   If len(regressions) > 0:
     Log: "[closed-loop] regressions_detected={len(regressions)}"
     
     # Treat as evaluation failure
     evaluation_result.passed = false
     evaluation_result.first_failure = {
       name: "regression_check",
       output: format_regression_report(regressions)
     }
     
     # Route to ANALYZE with regression pattern
     # Pattern: regression-detected
     # Strategy: context_expand (read dependent file, understand why)
     
   Else:
     Log: "[closed-loop] regression_check=passed dependents={len(dependent_files)}"
```

### Regression Report Format

```markdown
## Regression Detected

{n} dependent files have new test failures after your changes:

| File | Baseline | Current | New Failures |
|------|----------|---------|--------------|
| src/utils/helper.ts | 5/5 pass | 3/5 pass | 2 |
| src/api/client.ts | 8/8 pass | 7/8 pass | 1 |

### Affected Tests

**src/utils/helper.ts:**
- `should parse valid input` - was passing, now failing
- `should handle empty input` - was passing, now failing

### Suggested Investigation

1. Read the dependent file to understand its usage of modified code
2. Check if API contract changed (function signature, return type)
3. Update dependent code or add backwards compatibility
```

### Regression Analysis Strategy

When `regression-detected` pattern matches:

```yaml
strategy: context_expand

steps:
  1. Read the dependent file that has new failures
  2. Identify how it uses the modified code:
     - Function calls
     - Type dependencies
     - Imported constants/configs
  3. Determine if the change broke the contract:
     - Signature change?
     - Return type change?
     - Side effect change?
  4. Generate fix:
     - If contract should change: update dependent file
     - If contract should stay: revert breaking change, find alternative
```

### Project-Level Override

Projects can customize regression detection via `verification-gates-local.yml`:

```yaml
# .cursor/configurations/verification-gates-local.yml
version: 1
extends: global

regression_detection:
  # Default: [medium, high]
  # Always on: [low, medium, high]
  # Only expensive tasks: [high]
  enabled_for_complexity: [medium, high]
  
  # Scope of dependent file search
  search_depth: 2  # How many levels of imports to follow
  
  # Skip certain patterns from regression checks
  exclude_patterns:
    - "**/*.test.ts"
    - "**/*.spec.ts"
    - "**/mocks/**"
```

## Same-Error Escalation Rule

Prevents infinite loops by detecting repeated failures.

### Rule Definition

```
RULE: Identical Retry Prevention

IF:
  - The same failure pattern fires twice
  - AND the same strategy was attempted both times
  - AND the error output is substantially similar (>80% token overlap)

THEN the agent MUST either:
  a) Try a different strategy from the pattern's alternatives
  b) Escalate to user

Retrying identically is FORBIDDEN.
```

### Alternative Strategy Selection

```
Input: current_pattern, current_strategy, attempt_history
Output: alternate_strategy | escalate

1. Load pattern from failure-patterns.yml

2. Build strategy options:
   - Primary: pattern.strategy
   - Fallbacks: [context_expand, analyze_then_fix] (universal fallbacks)

3. Filter out already-tried strategies:
   - Check attempt_history for this pattern
   - Remove strategies already attempted

4. If options remain:
   - Select first available
   - Return alternate_strategy

5. If no options:
   - Return escalate
```

### Escalation Protocol

```
When escalation triggered:

1. Summarize the situation:
   - What was attempted
   - Why each attempt failed
   - What strategies were tried

2. Provide actionable guidance:
   - Based on pattern type
   - Specific files/lines to check
   - Potential root causes

3. Offer options:
   - "Fix manually and retry"
   - "Provide additional context"
   - "Abort this task"

4. Wait for user input before proceeding
```

## Success Criteria by Task Type

Default success criteria loaded from `configurations/failure-patterns.yml`:

| Task Type | Success Criteria |
|-----------|-----------------|
| `bug_fix` | Error no longer reproducible, tests pass, linter clean |
| `feature` | Feature works as specified, tests pass, linter clean, no regressions |
| `refactor` | Behavior unchanged, tests pass, linter clean, code quality improved |
| `security` | Vulnerability resolved, security tests pass, CISO review passed |
| `config_change` | Config valid, tool loads without error |

### Criterion Evaluation

```yaml
bug_fix:
  checks:
    - name: error_resolved
      type: custom
      command: "reproduce the original error"
      expected: "error does not occur"
    - name: tests_pass
      type: test
      command: "npm test" | "pytest" | etc.
    - name: lint_clean
      type: lint
      command: "npm run lint" | "biome check" | etc.

feature:
  checks:
    - name: feature_works
      type: custom
      description: "Verify feature matches specification"
    - name: tests_pass
      type: test
    - name: lint_clean
      type: lint
    - name: no_regressions
      type: test
      scope: "affected files and their dependents"

refactor:
  checks:
    - name: behavior_unchanged
      type: test
      description: "All existing tests still pass"
    - name: tests_pass
      type: test
    - name: lint_clean
      type: lint
    - name: quality_improved
      type: custom
      description: "Code complexity reduced, readability improved"

security:
  checks:
    - name: vulnerability_resolved
      type: custom
      description: "Security issue no longer exploitable"
    - name: security_tests_pass
      type: test
      scope: "security-related tests"
    - name: ciso_review
      type: approval
      agent: ciso

config_change:
  checks:
    - name: config_valid
      type: syntax
      description: "Config file parses without error"
    - name: tool_loads
      type: command
      description: "Tool starts successfully with new config"
```

## Pattern Matching Algorithm

Matches error output against known failure patterns.

### Algorithm

```
Input: error_output (string)
Output: matched_pattern, confidence, strategy

function matchFailurePattern(error_output):
    # Normalize input
    normalized = error_output.toLowerCase()
    tokens = tokenize(normalized)

    # Score each pattern
    scores = []
    for pattern in load("configurations/failure-patterns.yml").patterns:
        match_count = 0
        for signal in pattern.signals:
            # Signal can be literal string or regex
            if isRegex(signal):
                if regex_match(signal, error_output):
                    match_count += 1
            else:
                if signal.toLowerCase() in normalized:
                    match_count += 1

        confidence = match_count / len(pattern.signals)
        if confidence >= 0.3:  # Minimum threshold
            scores.append({
                pattern: pattern,
                confidence: confidence,
                match_count: match_count
            })

    # Select best match
    if len(scores) == 0:
        return {
            matched_pattern: null,
            confidence: 0,
            strategy: "analyze_then_fix"  # Default fallback
        }

    best = max(scores, key=lambda x: x.confidence)
    return {
        matched_pattern: best.pattern.id,
        confidence: best.confidence,
        strategy: best.pattern.strategy
    }
```

### Pattern Matching Examples

```yaml
# Example 1: Lint error
error_output: "ESLint: 'foo' is defined but never used (no-unused-vars)"
matched_pattern: lint-error
confidence: 0.33 (1/3 signals matched: "ESLint")
strategy: auto_fix

# Example 2: Type error
error_output: |
  error TS2322: Type 'string' is not assignable to type 'number'.
  src/utils.ts:15:3
matched_pattern: type-error
confidence: 0.6 (3/5 signals: "TypeScript", "type error", "is not assignable")
strategy: context_expand

# Example 3: Module not found
error_output: "Cannot find module 'lodash' or its corresponding type declarations"
matched_pattern: import-not-found
confidence: 0.5 (2/4 signals: "Cannot find module", "Module not found")
strategy: dependency_check

# Example 4: Permission denied
error_output: "EACCES: permission denied, open '/etc/hosts'"
matched_pattern: permission-error
confidence: 0.5 (2/4 signals: "EACCES", "permission denied")
strategy: escalate
```

### Confidence Thresholds

| Confidence | Interpretation | Action |
|------------|---------------|--------|
| >= 0.7 | High confidence match | Use pattern's strategy directly |
| 0.5 - 0.69 | Medium confidence | Use pattern's strategy, log for review |
| 0.3 - 0.49 | Low confidence | Use pattern's strategy, consider escalation |
| < 0.3 | No match | Use generic analyze_then_fix |

## Attempt Tracking

Each attempt is recorded for pattern detection and debugging.

### Attempt Record Format

```yaml
attempts:
  - attempt: 1
    timestamp: "2026-04-04T10:15:30Z"
    action: "Modified src/auth.ts to add null check on line 42"
    result: "Type error: Property 'user' does not exist on type 'Session'"
    error: "TS2339: Property 'user' does not exist on type 'Session'"
    pattern_matched: "type-error"
    strategy_used: "context_expand"
    duration_ms: 2341
    files_modified: ["src/auth.ts"]

  - attempt: 2
    timestamp: "2026-04-04T10:16:45Z"
    action: "Expanded context with Session type definition, added type assertion"
    result: "Lint error: Unexpected any type (@typescript-eslint/no-explicit-any)"
    error: "ESLint error on line 43"
    pattern_matched: "lint-error"
    strategy_used: "auto_fix"
    duration_ms: 1823
    files_modified: ["src/auth.ts"]

  - attempt: 3
    timestamp: "2026-04-04T10:17:20Z"
    action: "Ran eslint --fix, refined type assertion to Session & { user: User }"
    result: "All checks passed"
    error: null
    pattern_matched: null
    strategy_used: null
    duration_ms: 3102
    files_modified: ["src/auth.ts"]
```

### Attempt Storage Location

```
session.current/attempts-{task_id}.md

---
entity_name: session.current.attempts.{task_id}
namespace: session.current
category: attempts
task_id: task-a1b2c3-fix-auth
total_attempts: 3
final_status: success
created_at: 2026-04-04T10:15:30Z
updated_at: 2026-04-04T10:17:20Z
tags: [attempts, closed-loop]
---

## Attempt History

{YAML formatted attempts array}
```

## Dead Letter Format

Failed tasks that exhaust retries are written to dead letter storage.

### Dead Letter Entry

```markdown
---
entity_name: session.current.dead-letter.{task_id}
namespace: session.current
category: dead-letter
task_id: task-x7y8z9-failing-task
original_task: "Add user preferences feature"
total_attempts: 3
final_pattern: type-error
strategies_exhausted: [context_expand, analyze_then_fix]
blocked_at: 2026-04-04T11:30:00Z
blocked_reason: retry_budget_exhausted
tags: [dead-letter, blocked]
similar_failures: 2
error_signature: "type-error:ts:circular_reference"
---

## Task Description

Add user preferences feature with persistence to localStorage.

## Error Chain

### Attempt 1 (10:15:30)
- **Action:** Created preferences.ts with initial implementation
- **Error:** Type 'undefined' is not assignable to type 'Preferences'
- **Pattern:** type-error
- **Strategy:** context_expand

### Attempt 2 (10:18:45)
- **Action:** Added default values and type guards
- **Error:** Property 'theme' does not exist on type 'Partial<Preferences>'
- **Pattern:** type-error (same)
- **Strategy:** analyze_then_fix (alternate)

### Attempt 3 (10:22:10)
- **Action:** Rewrote with explicit typing
- **Error:** Circular type reference in Preferences
- **Pattern:** type-error (same)
- **Strategy:** exhausted

## Files Modified

- src/preferences.ts (created)
- src/types/preferences.d.ts (created)
- src/hooks/usePreferences.ts (modified)

## Smart Suggestions

Based on 2 similar failures:

1. **Most likely root cause:** Circular type references in TypeScript definitions
2. **Specific area to investigate:** `src/types/preferences.d.ts` — check for self-referencing types
3. **Alternative approach:** Use type aliasing instead of interface extension to break the cycle

### Similar Failures

- task-a1b2c3-add-settings: Circular reference in Settings type (2026-04-02)
- task-d4e5f6-user-profile: Self-referencing Profile type (2026-04-01)

### Common Thread

All failures involve TypeScript type definitions with nested optional properties that create circular dependencies. The pattern occurs when types reference each other or themselves through optional properties.

## Suggested Manual Steps

1. Review the Preferences type definition in `src/types/preferences.d.ts`
2. Check for circular references between Preferences and UserSettings
3. Consider simplifying the type hierarchy
4. Run `tsc --noEmit` to see full error context

## Context for Retry

When retrying, consider:
- The type system is rejecting nested optional properties
- Previous attempts tried adding defaults and guards
- Root cause may be in the type definition itself, not usage
```

## Dead Letter Aggregation Protocol

Aggregate similar dead letters to surface systemic issues and provide smarter suggestions.

### On Dead Letter Creation

```
1. Extract error signature:
   signature = {
     error_type: first line of final error message (normalized)
     file_extension: extension of primary failing file
     pattern_id: final_pattern matched
   }
   
   Format: "{pattern_id}:{extension}:{error_type_hash}"
   Example: "type-error:ts:circular_reference"

2. Search for similar dead letters:
   Search session.current/dead-letter-*.md for:
   - Same pattern_id
   - Same file_extension
   - Similar error_type (first 50 chars match OR same error code)
   
   Store matches as similar_dead_letters[]

3. If similar_dead_letters.count >= 1:
   Generate smart suggestions based on common thread

4. Add to dead letter entry:
   - similar_failures: count
   - error_signature: formatted signature
   - Smart Suggestions section with:
     - Most likely root cause (inferred from common patterns)
     - Specific area to investigate (files/patterns that recur)
     - Alternative approach (based on what hasn't been tried)
   - Similar Failures section with task IDs and brief descriptions
   - Common Thread section explaining what all failures share
```

### Smart Suggestion Generation

```
Input: current_error, similar_dead_letters[]
Output: smart_suggestions

1. Identify common thread:
   - What patterns appear in all failures?
   - What file types are consistently involved?
   - What strategies have been exhausted across all?

2. Generate root cause hypothesis:
   Based on common thread, suggest most likely root cause:
   - If all type-error + .ts: "Type system constraints"
   - If all import-not-found + .py: "Python path/module resolution"
   - If all test-failure + same test file: "Test environment or fixture issue"

3. Identify investigation target:
   - Most frequently mentioned file across failures
   - Most frequently mentioned line number range
   - Most frequently mentioned function/class

4. Suggest alternative approach:
   - What strategies were NOT tried?
   - What patterns in successful similar tasks could apply?
   - Is there a simpler approach that avoids the problematic area?

5. Format suggestions concisely (max 200 tokens):
   ## Smart Suggestions
   
   Based on {n} similar failures:
   
   1. **Most likely root cause:** {root_cause_hypothesis}
   2. **Specific area to investigate:** {investigation_target}
   3. **Alternative approach:** {alternative_suggestion}
```

### Aggregation for Pattern Learning

When similar_failures >= 3 and no pattern matched with confidence >= 0.5:

```
1. Trigger pattern learning discovery (see pattern_learning in failure-patterns.yml)

2. Include in dead letter entry:
   ## Pattern Learning Candidate
   
   This failure matches {n} others with no confident pattern match.
   A candidate pattern has been proposed for review.
   
   See: session.current/candidate-pattern-{hash}.md
```

## Integration with Pipeline Executor

This skill is invoked by pipeline stages with `skill: closed-loop-execution`.

### Invocation Flow

```
pipeline-executor                    closed-loop-execution
      │                                      │
      │  stage.skill = "closed-loop-execution"
      │─────────────────────────────────────►│
      │                                      │
      │  invoke with:                        │
      │    task_id                           │
      │    action (from stage description)  │
      │    success_criteria (from pipeline) │
      │                                      │
      │                                      │  ┌─────────────┐
      │                                      │  │ EXECUTE LOOP│
      │                                      │  └──────┬──────┘
      │                                      │         │
      │                                      │  generate → execute
      │                                      │  evaluate → analyze
      │                                      │  fix → repeat
      │                                      │         │
      │                                      │  ┌──────▼──────┐
      │                                      │  │ LOOP EXITS  │
      │                                      │  └──────┬──────┘
      │                                      │         │
      │  return:                             │◄────────┘
      │    status: success | failed | escalated
      │    attempts: number
      │    result: {...} (if success)
      │    failure_pattern: string (if failed)
      │    escalation_reason: string (if escalated)
      │                                      │
      │  pipeline continues or halts         │
      ▼                                      ▼
```

### Pipeline Stage Configuration

```yaml
stages:
  - id: implement
    agent: tech-lead
    mode: agent
    description: "Implement the feature with automatic recovery"
    inputs: [plan, context]
    outputs: [code_changes]
    skill: closed-loop-execution
    timeout_minutes: 30
    retry:
      max_attempts: 5
      backoff: exponential
      initial_delay_seconds: 5
```

### Interaction with Stage Retry

The closed-loop skill manages its own internal retry loop:

```
Stage retry (pipeline-executor):
  - Retries the entire stage if it returns failed
  - Uses backoff config from stage definition
  - Limited by stage.retry.max_attempts

Closed-loop retry (this skill):
  - Internal retries within a single stage execution
  - Uses pattern-specific max_auto_retries
  - Applies failure-specific strategies

Relationship:
  - Closed-loop exhausts internal retries first
  - Only returns "failed" when strategies exhausted
  - Pipeline-executor may then retry the whole stage
  - Total attempts = stage_retries × internal_retries (worst case)
```

## Usage Examples

### Example 1: Lint Error Auto-Fix

```yaml
Input:
  task_id: task-a1b2c3-add-button
  action:
    type: code_change
    files: [src/components/Button.tsx]
    description: "Add onClick handler"

Execution:
  GENERATE: Create Button.tsx with onClick handler
  EXECUTE: Write file
  EVALUATE: Run npm run lint → FAIL (missing semicolon)
  ANALYZE: Match "lint-error", confidence 0.5, strategy "auto_fix"
  FIX: Run npm run lint:fix
  GENERATE: (no change needed, file auto-fixed)
  EVALUATE: Run npm run lint → PASS
  
Output:
  status: success
  attempts: 2
  result: {files_modified: ["src/components/Button.tsx"]}
```

### Example 2: Type Error with Context Expansion

```yaml
Input:
  task_id: task-d4e5f6-fix-types
  action:
    type: code_change
    files: [src/api/client.ts]
    description: "Fix type error in API client"

Execution:
  GENERATE: Attempt type fix
  EXECUTE: Apply change
  EVALUATE: Run tsc --noEmit → FAIL
  ANALYZE: Match "type-error", strategy "context_expand"
  FIX: Read type definitions from src/types/api.d.ts
  GENERATE: Fix with expanded context
  EVALUATE: Run tsc --noEmit → PASS

Output:
  status: success
  attempts: 2
```

### Example 3: Escalation After Retries

```yaml
Input:
  task_id: task-g7h8i9-fix-build
  action:
    type: code_change
    files: [webpack.config.js]
  max_retries: 2

Execution:
  Attempt 1: "build-error" → "analyze_then_fix" → still fails
  Attempt 2: "build-error" (same) → alternate strategy unavailable
  
  Same pattern fired twice with same strategy → MUST escalate

Output:
  status: escalated
  attempts: 2
  escalation_reason: "Same build-error pattern with analyze_then_fix strategy failed twice. No alternate strategies available."
```

### Example 4: Dead Letter After Budget Exhaustion

```yaml
Input:
  task_id: task-j0k1l2-complex-refactor
  max_retries: 3

Execution:
  Attempt 1: "type-error" → "context_expand" → fails
  Attempt 2: "type-error" → "analyze_then_fix" → fails
  Attempt 3: "type-error" → strategies exhausted
  
  Retry budget exhausted → DEAD LETTER

Output:
  status: failed
  attempts: 3
  failure_pattern: "type-error"
  
Side effect:
  Dead letter written to session.current/dead-letter-task-j0k1l2-complex-refactor.md
```

## Error Handling

### Graceful Degradation

```yaml
scenarios:
  pattern_file_missing:
    detection: configurations/failure-patterns.yml not found
    fallback: Use hardcoded default patterns
    log: "Warning: failure-patterns.yml not found, using defaults"

  no_pattern_match:
    detection: No pattern matches with confidence >= 0.3
    fallback: Use "analyze_then_fix" strategy
    log: "No pattern matched for error, using generic analysis"

  strategy_execution_fails:
    detection: Strategy step throws error
    fallback: Skip to next strategy or escalate
    log: "Strategy {name} failed: {error}, trying alternate"

  memory_write_fails:
    detection: Cannot write to session.current/
    fallback: Continue execution, log warning
    log: "Warning: Could not persist attempt state"
```

### Non-Retryable Errors

Some errors should never trigger automatic retry:

```yaml
non_retryable:
  - pattern: permission-error
    reason: "Requires elevated privileges or file ownership change"
  
  - pattern: merge-conflict
    reason: "Requires human decision on conflict resolution"
  
  - pattern: git-error
    reason: "Git state issues can cause data loss if mishandled"
  
  - condition: "user explicitly aborted"
    reason: "Respect user's decision to halt"
  
  - condition: "security violation detected"
    reason: "Security issues require human review"
```

## Metrics and Observability

### Metrics Captured

```yaml
per_execution:
  - total_attempts
  - time_to_success_ms
  - patterns_encountered: string[]
  - strategies_used: string[]
  - files_modified: string[]
  - final_status: success | failed | escalated
  # VALIDATE phase metrics (new)
  - pre_validation_runs: number
  - pre_validation_pass_rate: number
  - pre_validation_catches: string[]  # Types of errors caught pre-write
  # Regression detection metrics (new)
  - regression_checks_run: number
  - regression_checks_skipped: number  # Skipped due to low complexity
  - regressions_detected: number
  - regressions_auto_fixed: number

per_attempt:
  - attempt_number
  - duration_ms
  - pattern_matched
  - strategy_used
  - success: boolean
  # VALIDATE phase details (new)
  - validation_passed: boolean
  - validation_gates_run: number
  - validation_violations: number

aggregated:
  - success_rate_by_pattern
  - avg_attempts_by_pattern
  - escalation_rate
  - dead_letter_rate
  # VALIDATE phase aggregates (new)
  - pre_validation_catch_rate: number  # % of errors caught before write
  - most_common_pre_validation_catches: string[]
```

### Logging Format

```
[closed-loop] task={task_id} attempt={n} pattern={pattern} strategy={strategy} result={success|failed}
[closed-loop] task={task_id} status={success|failed|escalated} total_attempts={n} duration_ms={ms}
[closed-loop] task={task_id} dead_letter reason={reason}
[closed-loop] task={task_id} validation={passed|failed} gates={count} violations={count}
[closed-loop] task={task_id} regression_check={passed|failed|skipped} complexity={level}
```
