---
name: rule-enforcement
description: Programmatic rule enforcement with glob patterns, priority resolution, and pre/post validation. Use when checking compliance before or after agent actions.
version: 1
input_schema:
  required:
    - name: target_files
      type: string[]
      description: Files being modified or checked
    - name: phase
      type: string
      description: Validation phase - pre_action or post_action
  optional:
    - name: override_rules
      type: string[]
      description: Rules to skip (must be authorized by override_by relationship)
output_schema:
  required:
    - name: status
      type: string
      description: Result - passed, violations_found, or error
  optional:
    - name: violations
      type: object[]
      description: List of rule violations with details
    - name: rules_checked
      type: string[]
      description: Rules that were evaluated
pre_checks:
  - description: Phase is valid
    validation: phase in [pre_action, post_action]
  - description: Target files are provided
    validation: target_files is not empty
  - description: Override rules are authorized
    validation: each override_rule has valid override_by relationship
post_checks:
  - description: Status is always returned
    validation: status is not empty
  - description: Violations include required fields
    validation: if violations then each has rule, file, severity, message
---

# Rule Enforcement Protocol

## Overview

This skill defines how agents programmatically discover, evaluate, and enforce rules. It provides a consistent mechanism for pre-action validation (before writes) and post-action validation (after writes), with priority resolution when rules conflict.

## Enhanced Rule Frontmatter Schema

Rules use YAML frontmatter with these fields:

```yaml
---
description: string # Required. What the rule does.
globs: string # File patterns (e.g., "**/*.sh", "**/*.ts,**/*.tsx")
alwaysApply: boolean # If true, applies regardless of globs (default false)
priority: number # 0-1000, higher wins on conflict (default 500)
enforcement: strict | advisory | informational # Default advisory
pre_action: boolean # Validate before agent writes (default false)
post_action: boolean # Validate after agent writes (default true)
override_by: string[] # Rules that can override this one
tags: string[] # For categorization and filtering
---
```

### Field Details

| Field         | Required | Default    | Description                                              |
| ------------- | -------- | ---------- | -------------------------------------------------------- |
| `description` | yes      | —          | Clear explanation of rule purpose                        |
| `globs`       | no       | —          | Comma-separated glob patterns for file matching          |
| `alwaysApply` | no       | `false`    | If `true`, rule applies to all files regardless of globs |
| `priority`    | no       | `500`      | Conflict resolution priority (0-1000)                    |
| `enforcement` | no       | `advisory` | How strictly to enforce violations                       |
| `pre_action`  | no       | `false`    | Run validation before file modifications                 |
| `post_action` | no       | `true`     | Run validation after file modifications                  |
| `override_by` | no       | `[]`       | List of rule names that can override this rule           |
| `tags`        | no       | `[]`       | Tags for filtering and categorization                    |

## Rule Discovery Protocol

### 1. Locate Rule Sources

Rules are loaded from two locations, in order:

1. **Org-level**: `~/.cursor/rules/*.mdc` (global defaults)
2. **Project-level**: `.cursor/rules/*.mdc` (project overrides)

### 2. Parse and Index Rules

```
For each .mdc file in rule directories:
  1. Extract YAML frontmatter
  2. Parse: description, globs, alwaysApply, priority, enforcement, pre_action, post_action, override_by, tags
  3. Apply defaults from configurations/rule-priorities.yml where fields are missing
  4. Add to rule index with source (org or project)
```

### 3. Match Rules to Target Files

For each target file being modified or checked:

```
applicable_rules = []
for rule in all_rules:
  if rule.alwaysApply:
    applicable_rules.append(rule)
  elif rule.globs:
    for glob_pattern in rule.globs.split(','):
      if file matches glob_pattern.trim():
        applicable_rules.append(rule)
        break
return applicable_rules
```

### 4. Merge Org and Project Rules

When the same rule name exists at both levels:

- **Project-level wins** for all fields it defines
- Org-level provides defaults for undefined fields
- Priority can be overridden at project level

## Priority Resolution Protocol

### Priority Bands

| Band              | Range    | Description                                       |
| ----------------- | -------- | ------------------------------------------------- |
| **Critical**      | 900-1000 | Security, error handling — must never be violated |
| **Standard**      | 400-600  | Conventions, style — should be followed           |
| **Informational** | 0-200    | Suggestions, best practices — nice to have        |

### Conflict Resolution

When two rules conflict on the same aspect:

1. **Higher priority wins**: Rule with higher `priority` value takes precedence
2. **Explicit override**: If rule A lists rule B in `override_by`, rule A can override rule B regardless of priority
3. **Same priority**: Project-level rules win over org-level rules
4. **Strict wins**: If priorities are equal, `strict` enforcement wins over `advisory`

### Override Relationships

The `override_by` field creates explicit override permissions:

```yaml
# In shell-conventions.mdc
override_by: [local-overrides]

# This means local-overrides can override shell-conventions
# even if shell-conventions has higher priority
```

## Enforcement Levels

### strict

- **Behavior**: Blocks action, agent MUST fix before proceeding
- **Agent response**: Stop, report violation, attempt fix, re-validate
- **Use case**: Security rules, error handling, critical conventions
- **Example**: Missing error handling, hardcoded secrets

### advisory

- **Behavior**: Warns but allows agent to proceed with justification
- **Agent response**: Log warning, continue if justified, document reason
- **Use case**: Style conventions, documentation standards
- **Example**: Missing function documentation, non-standard naming

### informational

- **Behavior**: Logged only, no blocking
- **Agent response**: Note for reference, continue without delay
- **Use case**: Best practices, suggestions, optimization hints
- **Example**: Potential performance improvements, alternative approaches

## Pre-Action Validation Protocol

Run before any file modifications:

```
1. Identify all files that will be modified
2. Load all rules with pre_action: true
3. Match rules to target files by glob patterns
4. For each matched rule with enforcement: strict:
   a. Evaluate rule against planned changes
   b. If violation detected:
      - Report violation with details
      - STOP — do not proceed with writes
      - Suggest fix or ask for guidance
5. For advisory/informational rules:
   - Log potential violations
   - Continue with writes
6. Return validation result
```

### Pre-Action Output

```yaml
pre_action_result:
  status: passed | violations_found | error
  violations:
    - rule: rule-name
      files_affected: [file1.ts, file2.ts]
      severity: strict
      message: What would violate the rule
      suggested_fix: How to modify the planned change
  proceed: boolean # false if any strict violations
```

## Post-Action Validation Protocol

Run after file modifications:

```
1. Identify all files that were modified
2. Load all rules with post_action: true (default)
3. Match rules to modified files by glob patterns
4. For each matched rule:
   a. Evaluate rule against file contents
   b. Record any violations with severity
5. For strict violations:
   - Attempt auto-fix if auto_fixable
   - If not auto-fixable, report and request human intervention
6. For advisory violations:
   - Log warning with context
   - Document in response to user
7. Return validation result
```

### Post-Action Output

```yaml
post_action_result:
  status: passed | violations_found | error
  violations:
    - rule: rule-name
      file: path/to/file
      line: 42
      severity: strict | advisory | informational
      message: What violated the rule
      suggested_fix: How to fix it
      auto_fixable: boolean
      fixed: boolean # true if auto-fixed
  rules_checked: [rule1, rule2, rule3]
  files_validated: [file1.ts, file2.ts]
```

## Violation Report Format

Each violation includes:

```yaml
violations:
  - rule: rule-name # Name of the violated rule
    file: path/to/file # Full path to the file
    line: number # Line number if applicable, null otherwise
    severity: strict # strict | advisory | informational
    message: "what violated" # Clear description of the violation
    suggested_fix: "how to fix" # Actionable fix instruction
    auto_fixable: boolean # true if agent can fix automatically
    code_context: | # Optional: surrounding code for context
      relevant code snippet
```

### Violation Examples

```yaml
# Strict violation - security
- rule: error-handling-and-security
  file: src/api/auth.ts
  line: 45
  severity: strict
  message: Hardcoded secret detected in source code
  suggested_fix: Move secret to environment variable and reference via process.env
  auto_fixable: false

# Advisory violation - convention
- rule: shell-conventions
  file: scripts/deploy.sh
  line: 1
  severity: advisory
  message: Missing file header documentation block
  suggested_fix: Add header block with Purpose and Usage sections
  auto_fixable: true

# Informational violation - suggestion
- rule: stow-structure
  file: newpkg/.config/tool/config.toml
  line: null
  severity: informational
  message: Consider adding package to Makefile stow target list
  suggested_fix: Update Makefile CONFIGS variable to include newpkg
  auto_fixable: false
```

## Auto-Fix Protocol

For violations marked `auto_fixable: true`:

### 1. Determine Fix Type

| Fix Type              | Description                   | Example                  |
| --------------------- | ----------------------------- | ------------------------ |
| `format`              | Code formatting               | Indentation, line length |
| `import_order`        | Import statement ordering     | Alphabetize imports      |
| `header`              | Add/update header comments    | Shell file headers       |
| `trailing_whitespace` | Remove trailing whitespace    | Line cleanup             |
| `newline_eof`         | Ensure newline at end of file | File endings             |

### 2. Apply Fix

```
1. Read current file content
2. Determine fix type and location
3. Apply transformation:
   - format: Run formatter if available, else skip
   - import_order: Sort import blocks
   - header: Insert standard header template
   - trailing_whitespace: Strip trailing spaces
   - newline_eof: Append newline if missing
4. Write updated content
5. Re-validate to confirm fix
6. Update violation record: fixed: true
```

### 3. Fix Templates

**Shell Header Template:**

```bash
# ---------------------------------------------------------------
# [File Name]
# ---------------------------------------------------------------
# Purpose:
#   - [Description]
#
# Usage:
#   - [How to use]
# ---------------------------------------------------------------
```

**Common Auto-Fixes:**

- **Shell conventions**: Add header, fix shebang, add `set -e`
- **TOML configs**: Format sections, alphabetize keys
- **Git conventions**: Format commit message structure

## Integration with Agent Workflow

### Before Writing Files

```
agent.validate_pre_action(target_files) ->
  if violations.any?(strict):
    report_violations()
    fix_or_abort()
  else:
    proceed_with_writes()
```

### After Writing Files

```
agent.validate_post_action(modified_files) ->
  for violation in violations:
    if violation.auto_fixable:
      apply_auto_fix(violation)
    elif violation.severity == 'strict':
      request_human_intervention(violation)
    else:
      log_violation(violation)
```

### Override Justification

When proceeding despite advisory violations:

```yaml
justification:
  rule: shell-conventions
  reason: "Legacy script maintained for compatibility; header format intentionally omitted"
  approved_by: user | tech-lead | explicit-override
  timestamp: 2026-04-04T10:00:00Z
```

## Configuration Loading

Rules load configuration defaults from `~/.cursor/configurations/rule-priorities.yml`:

```
1. Load configurations/rule-priorities.yml
2. Apply defaults.* to rules missing those fields
3. Apply rule_defaults.<rule-name>.* to specific rules
4. Apply overrides.* for explicit priority/enforcement changes
```

## Best Practices

1. **Set pre_action: true** for security and structure rules to catch issues early
2. **Use glob patterns** to scope rules to relevant file types only
3. **Keep strict rules minimal** — only for critical issues that must block
4. **Document override_by relationships** so agents understand flexibility
5. **Tag rules** for filtering in reports (e.g., `tags: [security, auth]`)
6. **Review violations** at session end to identify rule tuning needs
