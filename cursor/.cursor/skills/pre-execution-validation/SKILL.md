---
name: pre-execution-validation
description: Validates generated output before writing to disk. Use when implementing changes that need pre-write verification to catch errors early.
version: 1
input_schema:
  required:
    - name: generated_output
      type: object
      description: The generated output from GENERATE phase (code changes, configs, commands)
    - name: target_files
      type: string[]
      description: List of files to be modified
    - name: task_type
      type: string
      description: Task type (bug_fix, feature, refactor, security, config_change)
    - name: task_id
      type: string
      description: Task ID for tracking
  optional:
    - name: complexity
      type: string
      description: Task complexity (low, medium, high) - affects which gates run
      default: medium
    - name: skip_gates
      type: string[]
      description: Gate IDs to skip (for project-specific overrides)
output_schema:
  required:
    - name: passed
      type: boolean
      description: Whether all blocking gates passed
    - name: gates_checked
      type: object[]
      description: List of gates that were checked with results
  optional:
    - name: violations
      type: object[]
      description: List of violations found (blocking and advisory)
    - name: auto_fixed
      type: object[]
      description: List of issues that were auto-fixed
    - name: warnings
      type: string[]
      description: Non-blocking warnings to log
pre_checks:
  - description: Task ID is valid format
    validation: task_id matches pattern ^task-[a-z0-9]{6}-[a-z0-9-]+$
  - description: Task type is valid
    validation: task_type in [bug_fix, feature, refactor, security, config_change]
  - description: Target files list is not empty
    validation: target_files is not empty
post_checks:
  - description: Gates checked array is populated
    validation: gates_checked is not empty
  - description: Passed status reflects violations
    validation: if violations contains blocking then passed is false
cacheable: false
---

# Pre-Execution Validation

Validates generated output before writing to disk, catching errors early in the closed-loop execution cycle. This skill is invoked between GENERATE and EXECUTE phases.

## Overview

Pre-execution validation runs **before** any file modifications occur. It catches:

- Syntax errors that would fail immediately after write
- Import/module resolution issues
- Schema validation failures for config files
- Common code quality issues via self-review

By catching these errors before writing, we eliminate wasted GENERATE→EXECUTE→EVALUATE→ANALYZE→FIX cycles.

## Protocol

### Step 1: Load Applicable Gates

```
Input: task_type, target_files, complexity
Output: applicable_gates[]

1. Load verification-gates.yml from configurations/
   - Check for project-local overrides at .cursor/configurations/verification-gates-local.yml
   - Merge local over global (local wins on conflicts)

2. Filter gates where when == "pre_write"

3. Match gates to target_files using applies_to glob patterns:
   For each gate:
     For each target_file:
       If glob_match(gate.applies_to, target_file):
         Add gate to applicable_gates

4. Evaluate complexity conditions:
   For each gate with condition:
     If condition references complexity:
       Evaluate: e.g., "complexity in ['medium', 'high']"
       If false: remove from applicable_gates

5. Apply skip_gates filter:
   Remove any gates where gate.id in skip_gates

6. Order gates by execution priority:
   1. syntax_check (must pass for others to be meaningful)
   2. import_check
   3. schema_check
   4. self_review (runs last, reviews the full change)
```

### Step 2: Run Gates in Order

```
Input: applicable_gates[], generated_output, target_files
Output: gate_results[]

For each gate in applicable_gates:
  
  result = {
    gate_id: gate.id,
    status: pending,
    started_at: now(),
    violations: []
  }
  
  Execute gate based on type:
  
  ┌─────────────────────────────────────────────────────────────────┐
  │ syntax_check                                                    │
  ├─────────────────────────────────────────────────────────────────┤
  │ For each target_file:                                           │
  │   1. Get file extension                                         │
  │   2. Look up check_command.by_extension[extension]              │
  │   3. Apply runtime detection for {detected_command}             │
  │   4. Execute command against generated_output (not disk file)   │
  │   5. If exit_code != 0:                                         │
  │      - Parse error message for line/column                      │
  │      - Add violation: {severity: blocking, ...}                 │
  └─────────────────────────────────────────────────────────────────┘
  
  ┌─────────────────────────────────────────────────────────────────┐
  │ import_check                                                    │
  ├─────────────────────────────────────────────────────────────────┤
  │ For each target_file:                                           │
  │   1. Parse imports from generated_output                        │
  │   2. For each import:                                           │
  │      - Check if module exists in node_modules/                  │
  │      - Check if module in package.json dependencies             │
  │      - Check if relative import resolves to existing file       │
  │   3. For unresolved imports:                                    │
  │      - Add violation: {severity: blocking, ...}                 │
  │      - suggested_fix: "Install <package>" or "Create file"      │
  └─────────────────────────────────────────────────────────────────┘
  
  ┌─────────────────────────────────────────────────────────────────┐
  │ schema_check                                                    │
  ├─────────────────────────────────────────────────────────────────┤
  │ For each target_file matching config patterns:                  │
  │   1. Identify schema type from filename pattern                 │
  │   2. Parse generated_output as JSON/YAML                        │
  │   3. Validate against known schema:                             │
  │      - tsconfig: check compilerOptions, include, exclude        │
  │      - package.json: check required fields                      │
  │      - pipeline.yml: check stages structure                     │
  │   4. For schema violations:                                     │
  │      - Add violation with specific field path                   │
  └─────────────────────────────────────────────────────────────────┘
  
  ┌─────────────────────────────────────────────────────────────────┐
  │ self_review                                                     │
  ├─────────────────────────────────────────────────────────────────┤
  │ Structured self-critique of generated output:                   │
  │                                                                 │
  │ Review checklist:                                               │
  │ □ Unintended changes outside task scope                         │
  │ □ Missing error handling (empty catch, unhandled promises)      │
  │ □ Hardcoded values (credentials, URLs, magic numbers)           │
  │ □ Incomplete implementations (TODO, placeholder code)           │
  │ □ Broken imports (new imports without dependencies)             │
  │ □ Debug artifacts (console.log, debugger, test code)            │
  │ □ Security issues (exposed secrets, injection vectors)          │
  │                                                                 │
  │ For each issue found:                                           │
  │   severity = blocking if security/broken, else advisory         │
  │   Add violation with description and suggested_fix              │
  └─────────────────────────────────────────────────────────────────┘
  
  result.completed_at = now()
  result.duration_ms = completed_at - started_at
  result.status = violations.any(blocking) ? failed : passed
  
  Append result to gate_results[]
```

### Step 3: Aggregate Results

```
Input: gate_results[]
Output: validation_result

1. Collect all violations:
   all_violations = flatten(gate_results[*].violations)

2. Separate by severity:
   blocking_violations = filter(all_violations, severity == blocking)
   advisory_violations = filter(all_violations, severity == advisory)

3. Determine pass/fail:
   passed = len(blocking_violations) == 0

4. Build output:
   validation_result = {
     passed: boolean,
     gates_checked: gate_results[].{gate_id, status, duration_ms},
     violations: all_violations,
     auto_fixed: [],  # Populated if any auto-fixes were applied
     warnings: advisory_violations[].description
   }

5. Log result:
   "[pre-validation] task={task_id} passed={passed} gates={count} violations={count}"
```

## Self-Review Protocol

The `self_review` gate uses a structured prompt to catch common issues:

### Review Template

```markdown
## Self-Review Checklist

Review the following generated changes against these criteria:

### 1. Scope Check
- [ ] All modifications are within the task scope
- [ ] No unrelated files were modified
- [ ] No "drive-by" refactors or improvements

### 2. Error Handling
- [ ] No empty catch blocks
- [ ] Async operations have error handling
- [ ] Edge cases are handled (null, undefined, empty)

### 3. Hardcoded Values
- [ ] No hardcoded credentials or secrets
- [ ] No hardcoded URLs or endpoints
- [ ] Magic numbers are extracted to constants

### 4. Implementation Completeness
- [ ] No TODO comments left unaddressed
- [ ] No placeholder implementations
- [ ] All code paths are implemented

### 5. Import Integrity
- [ ] All new imports have corresponding dependencies
- [ ] No circular import patterns introduced
- [ ] Imports are from correct paths

### 6. Debug Artifacts
- [ ] No console.log/print statements (unless intentional logging)
- [ ] No debugger statements
- [ ] No commented-out code blocks

### 7. Security Quick Check
- [ ] No secrets in code
- [ ] User input is validated where used
- [ ] No obvious injection vectors

For each failed check, report:
- severity: blocking | advisory
- file: <path>
- line: <number if applicable>
- description: <what's wrong>
- suggested_fix: <how to fix>
```

### Self-Review Output Format

```yaml
self_review_result:
  issues_found: number
  blocking_count: number
  advisory_count: number
  issues:
    - severity: blocking
      category: error_handling
      file: src/api/client.ts
      line: 42
      description: "Empty catch block swallows errors silently"
      suggested_fix: "Log error and rethrow, or handle specific error types"
    - severity: advisory
      category: debug_artifacts
      file: src/utils/helper.ts
      line: 15
      description: "console.log statement left in production code"
      suggested_fix: "Remove or replace with proper logging"
```

## Violation Schema

```yaml
violation:
  gate_id: string         # Which gate caught this
  severity: blocking | advisory
  file: string            # File path
  line: number | null     # Line number if applicable
  column: number | null   # Column if applicable
  description: string     # What's wrong
  suggested_fix: string   # How to fix
  auto_fixable: boolean   # Whether auto_fix strategy exists
```

## Integration with Closed-Loop Execution

This skill is invoked as the VALIDATE phase between GENERATE and EXECUTE:

```
GENERATE → VALIDATE → EXECUTE → EVALUATE → ...
           ▲
           │
    ┌──────┴──────┐
    │ This skill  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │ If passed   │──────► Continue to EXECUTE
    └─────────────┘
           │
           │ If failed
           ▼
    ┌─────────────┐
    │ Route to    │──────► ANALYZE → FIX → GENERATE (not VALIDATE)
    │ ANALYZE     │
    └─────────────┘
```

### Invocation from closed-loop-execution

```yaml
# In VALIDATE phase:
invoke:
  skill: pre-execution-validation
  inputs:
    generated_output: $generate_output
    target_files: $action.files
    task_type: $task_context.task_type
    task_id: $task_id
    complexity: $task_context.complexity

# Handle result:
if validation_result.passed:
  proceed_to: EXECUTE
else:
  # Validation failures are treated like any other failure
  route_to: ANALYZE
  error_context:
    source: pre_validation
    violations: validation_result.violations
    gate_results: validation_result.gates_checked
```

## Runtime Detection Protocol

When check_command contains `{detected_command}`, resolve it:

```
1. Check runtime_detection.sources in order:
   - package.json scripts
   - Makefile targets
   - justfile recipes
   - pyproject.toml tools
   - CI config steps

2. For each source:
   - Read file if exists
   - Extract matching command
   - If found: return command

3. If no detection:
   - Use fallback_commands[gate_type_extension]
   - If no fallback: skip gate with warning
```

## Error Handling

```yaml
scenarios:
  gate_config_missing:
    detection: verification-gates.yml not found
    fallback: Use minimal default gates (syntax_check only)
    log: "Warning: verification-gates.yml not found, using defaults"

  command_not_available:
    detection: check_command executable not found
    fallback: Skip gate, log warning
    log: "Warning: {command} not available, skipping {gate_id}"

  timeout:
    detection: Gate execution exceeds 30 seconds
    fallback: Mark as advisory violation, continue
    log: "Warning: {gate_id} timed out, treating as advisory"

  parse_error:
    detection: Cannot parse generated_output for validation
    fallback: Fail validation with parse error
    log: "Error: Cannot parse generated output: {details}"
```

## Metrics Captured

```yaml
per_validation:
  task_id: string
  gates_run: number
  gates_passed: number
  gates_failed: number
  blocking_violations: number
  advisory_violations: number
  auto_fixed: number
  total_duration_ms: number
  passed: boolean

per_gate:
  gate_id: string
  duration_ms: number
  status: passed | failed | skipped
  violations_count: number
```

### Logging Format

```
[pre-validation] task={task_id} phase=start gates={count}
[pre-validation] task={task_id} gate={gate_id} status={status} violations={count} duration_ms={ms}
[pre-validation] task={task_id} phase=complete passed={passed} blocking={count} advisory={count}
```

## Usage Example

```yaml
Input:
  generated_output:
    type: code_change
    files:
      - path: src/api/client.ts
        content: |
          import { axios } from 'axios';
          import { Config } from './config';
          
          export async function fetchData() {
            try {
              const response = await axios.get(Config.API_URL);
              return response.data;
            } catch (e) {
              // TODO: handle error
            }
          }
  target_files: ["src/api/client.ts"]
  task_type: feature
  task_id: task-a1b2c3-add-api
  complexity: medium

Execution:
  1. Load gates: syntax_check, import_check, self_review
  2. syntax_check: PASS (valid TypeScript)
  3. import_check: PASS (axios in dependencies, ./config exists)
  4. self_review:
     - FAIL (blocking): Empty catch block (line 9)
     - FAIL (advisory): TODO comment left in code (line 10)

Output:
  passed: false
  gates_checked:
    - gate_id: syntax_check, status: passed, duration_ms: 150
    - gate_id: import_check, status: passed, duration_ms: 80
    - gate_id: self_review, status: failed, duration_ms: 200
  violations:
    - gate_id: self_review
      severity: blocking
      file: src/api/client.ts
      line: 9
      description: "Empty catch block swallows errors silently"
      suggested_fix: "Log error and rethrow, or handle specific error types"
    - gate_id: self_review
      severity: advisory
      file: src/api/client.ts
      line: 10
      description: "TODO comment indicates incomplete implementation"
      suggested_fix: "Implement error handling or remove TODO"

Next step: Route to ANALYZE with violations as error context
```
