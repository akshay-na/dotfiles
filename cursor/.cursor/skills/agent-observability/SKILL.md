---
name: agent-observability
description: Track agent decisions, metrics, token costs, and generate reports. Use when logging task execution, tracking agent performance, or generating observability reports.
version: 1
input_schema:
  required:
    - name: operation
      type: string
      description: Operation type - log_metric, log_decision, generate_report, query_metrics
  optional:
    - name: task_id
      type: string
      description: Task ID for metric association
    - name: metric_data
      type: object
      description: Metric data to log (for log_metric)
    - name: decision_data
      type: object
      description: Decision data to log (for log_decision)
    - name: report_type
      type: string
      description: Report type - session, weekly, agent_performance
    - name: query_filter
      type: object
      description: Filter criteria for query_metrics
output_schema:
  required:
    - name: status
      type: string
      description: Result - success, error
  optional:
    - name: report
      type: object
      description: Generated report (for generate_report)
    - name: metrics
      type: object[]
      description: Query results (for query_metrics)
    - name: entry_path
      type: string
      description: Path to created metric/decision entry
---

# Agent Observability

Instruments agent operations with per-task metrics, decision audit trails, token cost attribution, and reporting.

## Operations

| Operation | Description |
|-----------|-------------|
| `log_metric` | Record a task metric entry |
| `log_decision` | Record a decision audit entry |
| `generate_report` | Generate session, weekly, or agent performance report |
| `query_metrics` | Query metrics with filters |

## Per-Task Metric Entry Schema

Store task execution metrics using this schema:

```yaml
---
entity_name: session.current.metric.{task_id}
namespace: session.current
category: metric
status: accepted
tags: [observability, task-tracking, {task_type}]
created_at: ISO-8601
updated_at: ISO-8601
task_id: string
task_type: string
pipeline: string
target_repo: string
stages_executed:
  - stage_id: string
    agent: string
    started_at: ISO-8601
    completed_at: ISO-8601
    duration_ms: number
    outcome: success | failed | skipped
    retry_count: number
    token_estimate:
      input: number
      output: number
total_duration_ms: number
total_retries: number
final_outcome: success | failed | dead_letter | cancelled
decision_trail: []  # References to decision entries
---

Summary of task execution. Key decisions and outcomes.
```

**Field descriptions:**

| Field | Type | Description |
|-------|------|-------------|
| `task_id` | string | Unique identifier for the task |
| `task_type` | string | Classification (feature, bug-fix, refactor, etc.) |
| `pipeline` | string | Pipeline used (full-feature, bug-fix, etc.) |
| `target_repo` | string | Repository being modified |
| `stages_executed` | array | Per-stage execution records |
| `total_duration_ms` | number | Total task duration in milliseconds |
| `total_retries` | number | Sum of all retries across stages |
| `final_outcome` | enum | Final task status |
| `decision_trail` | array | References to decision entries for this task |

## Decision Audit Entry Schema

Record decisions for traceability:

```yaml
---
entity_name: session.current.decision.{task_id}.{decision_id}
namespace: session.current
category: decision
status: accepted
tags: [observability, decision-audit, {agent}]
created_at: ISO-8601
task_id: string
decision_id: string
agent: string
decision_type: routing | strategy | escalation | override | dispatch | specialist_escalation | folder_resolution | fallback | cleanup_audit | intra_role_fanout | loop_disabled | loop_partial
decision: string
rationale: string
alternatives_considered: string[]
context_summary: string
---

Full decision description and reasoning.
```

**Decision types:**

| Type | When Used |
|------|-----------|
| `routing` | Task classification and pipeline selection |
| `strategy` | Retry or recovery strategy selection |
| `escalation` | Escalation to human or senior agent |
| `override` | Deviation from routing table recommendation |
| `dispatch` | L1 → L2 phase fan-out (which agents run per phase) |
| `specialist_escalation` | L2 → L3 auto-escalation when specialist thresholds hit |
| `folder_resolution` | Multi-folder workspace split (which folders / subtasks) |
| `fallback` | No project team matched → fallback executor (e.g. senior-dev) |
| `cleanup_audit` | vp-onboarding legacy-delete / cleanup outcome |
| `intra_role_fanout` | L3 → L4 N-instance horizontal fan-out within one role |
| `loop_disabled` | Plan-level opt-out of default implementation review loop |
| `loop_partial` | Implementation loop degraded: missing `reviewer-*` or `qa-*` |

The eight orchestration-extended types (`dispatch` … `loop_partial`) MUST include **`rationale`** and **`alternatives_considered`** on every logged entry. **`intra_role_fanout`** entries SHOULD also carry `instance_count`, `partition_basis`, and `disjoint_groups` where applicable.

**Brief examples (orchestration types):**

```yaml
# dispatch — rationale + alternatives_considered required
decision_type: dispatch
decision: "Fan out implementation phase to dev-backend + dev-frontend"
rationale: "Isolated backends and SPA; pipelines allow parallel tracks"
alternatives_considered: ["single senior-dev sequential", "phased serial by area"]

# specialist_escalation
decision_type: specialist_escalation
decision: "Escalate to vp-architecture after L2 complexity threshold"
rationale: "Cross-service boundary change detected in diff scope"
alternatives_considered: ["staff-engineer", "narrow scope and continue with tech-lead"]

# folder_resolution
decision_type: folder_resolution
decision: "Split workspace into two folder-root subtasks after discover/classify"
rationale: "Paths map cleanly to disjoint repo roots without overlap"
alternatives_considered: ["single task serial", "ask_user for ambiguity"]

# fallback
decision_type: fallback
decision: "Route to senior-dev; no dev-*/reviewer-*/qa-*/sme-*/devops in target repo"
rationale: "Task requires execution; project team absent"
alternatives_considered: ["vp-onboarding bootstrap", "block task until team exists"]

# cleanup_audit
decision_type: cleanup_audit
decision: "vp-onboarding cleanup removed legacy stubs; audited paths"
rationale: "Post-migration orphan agent files conflicting with routing"
alternatives_considered: ["manual delete list", "deferred cleanup"]

# intra_role_fanout (+ instance fields)
decision_type: intra_role_fanout
decision: "Spawn dev-frontend#1/#2/#3 via path-prefix partitions"
rationale: "Parallel UI work with disjoint path ownership"
alternatives_considered: ["single dev-frontend", "serial by folder"]
instance_count: 3
partition_basis: path-prefix
disjoint_groups: ["src/views/a/**", "src/views/b/**", "src/views/c/**"]

# loop_disabled — plan-level opt-out; rationale repeats plan visibility
decision_type: loop_disabled
decision: "Default dev-reviewer-qa-loop not applied for this plan"
rationale: "Hotfix; user-approved single-pass implementation"
alternatives_considered: ["loop ON with minimal reviewer"]

# loop_partial
decision_type: loop_partial
decision: "Loop entered with qa-* missing"
rationale: "reviewer-backend present; no qa-unit in repo"
alternatives_considered: ["invoke vp-onboarding for qa-unit", "proceed with reviewer-only"]
```

## Capture Points

Agents must write metrics at these events:

| Event | What to Capture | When |
|-------|-----------------|------|
| Task classified | task_type, signals matched, confidence | After orchestrator classifies |
| Agent selected | agent name, reason (routing table vs override) | After routing decision |
| Stage started | stage_id, agent, timestamp | Before stage execution |
| Stage completed | duration, outcome, retry_count, tokens | After stage finishes |
| Retry triggered | failure pattern, strategy selected, retry number | When retry loop fires |
| Dead letter | full error context, strategies attempted | When retries exhausted |
| Pipeline complete | total duration, total retries, final outcome | After all stages done |
| Override made | what was overridden, why, alternatives | When agent overrides routing |
| Specialist escalated | `parent_agent`, `escalation_trigger`, `dispatch_level=L3` | After auto-escalation fires |
| Intra-role fan-out spawned | `parent_agent`, `instance_id`, `partition_basis`, `dispatch_level=L4` | Per-instance dispatch |
| Serial dispatch | `target_agent`, `parallelism_decision=serial+blocker:<reason>` | When parallelize-by-default is overridden |

### Orchestration structured log line

Emit one structured log entry (KV/JSON-equivalent or single-line parser-friendly form) whenever orchestration dispatches work. Minimum fields:

```
task_id=<id> parent_agent=<agent> dispatch_level=<L1|L2|L3|L4> folder_root=<path|-> target_agent=<agent> instance_id=<role#n|-> partition_basis=<path-prefix|module|service|single|-> iteration_n=<n|-> retry_target=<agent|-> escalation_trigger=<text|-> parallelism_decision=<parallel|serial+blocker:<reason>>
```

- **`dispatch_level`:** `L1` orchestrator/root → `L2` phase agents → `L3` specialists → **`L4` intra-role instance** (one row per instance when fanning horizontally within a role).
- **`partition_basis`** records how instances were partitioned (`path-prefix`, `module`, `service`, `single`).
- **`parallelism_decision`** captures whether sibling dispatches ran in parallel or were forced serial with a blocker reason.

### Capture Point Examples

**Task classified:**
```yaml
decision_type: routing
decision: "Classified as 'feature'"
rationale: "Signals matched: implement, create, new functionality"
alternatives_considered: ["bug-fix", "refactor"]
```

**Stage completed:**
```yaml
stages_executed:
  - stage_id: implementation
    agent: senior-dev
    started_at: "2024-01-15T10:30:00Z"
    completed_at: "2024-01-15T10:45:00Z"
    duration_ms: 900000
    outcome: success
    retry_count: 1
    token_estimate:
      input: 2500
      output: 1800
```

**Override made:**
```yaml
decision_type: override
decision: "Used vp-architecture instead of senior-dev"
rationale: "Complex distributed system design requires architecture expertise"
alternatives_considered: ["senior-dev", "staff-engineer"]
context_summary: "Task involves new microservice with cross-service data flow"
```

## Token Estimation Heuristic

Since exact token counts aren't available to agents, use this estimation:

```
Input tokens:  count_words(input_text) × 1.3
Output tokens: count_words(output_text) × 1.3
```

**Guidelines:**
- These are rough estimates for relative comparison, not absolute accuracy
- Count words in prompts, context, and file contents for input
- Count words in responses and generated code for output
- The 1.3 multiplier accounts for tokenization overhead

**Example calculation:**
```
Input: 500 words prompt + 2000 words context = 2500 words
Estimated input tokens: 2500 × 1.3 = 3250

Output: 800 words response + 1500 words code = 2300 words  
Estimated output tokens: 2300 × 1.3 = 2990
```

## Metric Promotion Protocol

Session metrics live in `session.current/` during execution. Promote to project-scoped storage for persistence.

### Promotion Triggers

| Trigger | Action |
|---------|--------|
| Pipeline completes (any outcome) | Promote task metrics |
| User requests report | Promote and aggregate |
| Session ends | Flush all pending metrics |

### Promoted Location

```
~/.cursor/memory/projects/{project_name}/metrics/
```

**File naming:** `metric-{task_id}-{date}.md`

**Example:** `metric-task-001-2024-01-15.md`

### Index File

Maintain an index for efficient queries:

```
~/.cursor/memory/projects/{project_name}/metrics/_index.md
```

**Index format:**
```yaml
---
entity_name: projects.{name}.metrics._index
namespace: projects.{name}.metrics
category: index
updated_at: ISO-8601
metrics:
  - task_id: task-001
    date: "2024-01-15"
    outcome: success
    pipeline: full-feature
  - task_id: task-002
    date: "2024-01-15"
    outcome: failed
    pipeline: bug-fix
---
```

## Session Report Template

Generate session reports using this template:

```markdown
## Session Report: {date}

### Summary
- Tasks completed: X
- Success rate: Y%
- Total duration: Zmin
- Total token estimate: Nk

### Tasks
| Task ID | Type | Pipeline | Duration | Retries | Outcome |
|---------|------|----------|----------|---------|---------|
| task-001 | feature | full-feature | 45min | 1 | success |

### Agent Usage
| Agent | Invocations | Avg Duration | Token Est. | Failure Rate |
|-------|-------------|--------------|------------|--------------|
| tech-lead | 4 | 15min | ~15k | 25% |
| cto | 2 | 10min | ~8k | 0% |

### Failure Analysis
| Pattern | Count | Auto-resolved | Escalated |
|---------|-------|---------------|-----------|
| lint-error | 3 | 3 | 0 |
| test-failure | 1 | 0 | 1 |

### Decision Audit
- task-001: Classified as 'feature' (signals: implement, create). 
  Routing table selected full-feature pipeline.
  Architecture review skipped (complexity: medium).
```

### Weekly Report Template

Aggregate across sessions for trend analysis:

```markdown
## Weekly Report: {week_start} to {week_end}

### Summary
- Total tasks: X
- Success rate: Y%
- Total estimated tokens: Nk
- Avg task duration: Zmin

### Trends
- Most common task type: {type} ({count})
- Most used pipeline: {pipeline} ({count})
- Most active agent: {agent} ({invocations})

### Orchestrator Health
- Dispatches (L1→L2/L3/L4 counted): X
- Fallbacks (no team → senior-dev or equivalent): Y
- `fallback_rate`: Z%
- `cascades_detected` ( unintended re-dispatch chains ): N
- `multi_folder_tasks`: M
- `cleanups_total` / `cleanups_failed` (vp-onboarding audits): CT / CF

#### SLO compliance

| SLO | Target | Actual | Met? |
|-----|--------|--------|------|
| Example: dispatch success rate | ≥ 98% | {actual} | ✓ / ✗ |
| Example: rollback rate after fan-out merge | ≤ 5% | {actual} | ✓ / ✗ |
| _(add org-defined SLO rows)_ | | | |

#### Onboarding Gaps
- Folders / repos where `fallback_rate > 30%`: {list} — suggests **`vp-onboarding`** refresh for project agents under `<repo>/.cursor/agents/`.

#### Parallelism Efficiency
- Avg instances per impl phase (L4-inclusive): X
- Fan-out hit-rate: % phases that attempted fan-out → % fan-outs succeeding post-merge → % rolled back due to overlap
- Top-3 serial blockers by frequency (from `parallelism_decision=serial+blocker:*`): {ranked list}
- % impl phases using default **ON** Dev-Reviewer-QA loop: P%
- `loop_disabled` count: N; top rationales: {bullet list}

### Failure Patterns
| Pattern | This Week | Last Week | Trend |
|---------|-----------|-----------|-------|
| lint-error | 5 | 3 | ↑ |
| test-failure | 2 | 4 | ↓ |

### Recommendations
- Consider improving {area} based on failure patterns
- Agent {name} has high retry rate — review prompts
```

## Query Protocol

Query metrics using these operations:

### Query Operations

| Operation | Parameters | Returns |
|-----------|------------|---------|
| `query_by_date_range` | start, end | metrics[] |
| `query_by_task_type` | type | metrics[] |
| `query_by_agent` | agent | metrics[] |
| `query_by_outcome` | outcome | metrics[] |
| `aggregate_by_agent` | - | { agent: stats } |
| `aggregate_by_pattern` | - | { pattern: counts } |

### Query Examples

**Query by date range:**
```yaml
query_filter:
  operation: query_by_date_range
  start: "2024-01-01"
  end: "2024-01-15"
```

**Aggregate by agent:**
```yaml
query_filter:
  operation: aggregate_by_agent
```

Returns:
```yaml
metrics:
  tech-lead:
    invocations: 12
    total_duration_ms: 3600000
    avg_duration_ms: 300000
    token_estimate: 45000
    failure_rate: 0.08
  senior-dev:
    invocations: 25
    total_duration_ms: 7200000
    avg_duration_ms: 288000
    token_estimate: 95000
    failure_rate: 0.04
```

## Integration with Other Skills

### task-orchestration

The `task-orchestration` skill should log:
- Task classification decisions (task_type, signals, confidence)
- Pipeline selection (which pipeline, why)
- Agent routing decisions

**Integration point:**
```yaml
# After task classification
log_decision:
  task_id: {task_id}
  decision_type: routing
  decision: "Selected {pipeline} pipeline"
  rationale: "Task classified as {task_type} with signals: {signals}"
```

### pipeline-executor

The `pipeline-executor` skill should log:
- Stage start/completion
- Stage metrics (duration, outcome, retries)
- Pipeline completion

**Integration point:**
```yaml
# After each stage
log_metric:
  task_id: {task_id}
  stage:
    stage_id: {stage}
    agent: {agent}
    duration_ms: {duration}
    outcome: {outcome}
    token_estimate: {estimate}
```

### closed-loop-execution

The `closed-loop-execution` skill should log:
- Retry attempts and patterns matched
- Strategy selection for recovery
- Dead letter entries

**Integration point:**
```yaml
# On retry
log_decision:
  task_id: {task_id}
  decision_type: strategy
  decision: "Retry with {strategy}"
  rationale: "Pattern matched: {pattern}"
```

### context-memory

The `context-memory` skill provides the storage backend:
- Use `write` for creating metric/decision entries
- Use `read` for querying
- Use `list` for aggregation
- Namespace: `session.current/` during execution, `projects/{name}/metrics/` for persistence

## Execution Flow

### log_metric

```
1. Validate metric_data against schema
2. Generate entity_name: session.current.metric.{task_id}
3. Write to context-memory with category: metric
4. Return { status: success, entry_path: ... }
```

### log_decision

```
1. Validate decision_data against schema
2. Generate decision_id if not provided
3. Generate entity_name: session.current.decision.{task_id}.{decision_id}
4. Write to context-memory with category: decision
5. Append decision_id to task metric's decision_trail
6. Return { status: success, entry_path: ... }
```

### generate_report

```
1. Determine report_type (session, weekly, agent_performance)
2. Query metrics from session.current/ or projects/{name}/metrics/
3. Query decisions for decision audit section
4. Aggregate statistics
5. Format using appropriate template
6. Return { status: success, report: { ... } }
```

### query_metrics

```
1. Parse query_filter
2. Execute appropriate query operation
3. For aggregations, compute statistics
4. Return { status: success, metrics: [...] }
```

## Feedback Loop Metrics

Track the effectiveness of feedback loops introduced by the feedback loop improvements.

### Metric Fields

```yaml
feedback_loop_metrics:
  # Pre-execution validation metrics
  pre_validation_runs: number
  pre_validation_pass_rate: number  # % of validations that pass
  pre_validation_catches: string[]  # Types of errors caught pre-write
  
  # Self-critique metrics
  self_critique_runs: number
  self_critique_catch_rate: number  # % of self-reviews that find issues
  self_critique_categories: string[]  # Categories of issues found
  
  # Cross-stage feedback metrics
  cross_stage_feedback_iterations: number
  cross_stage_feedback_resolutions: number  # Fixed without user intervention
  cross_stage_escalations: number
  
  # Regression detection metrics
  regression_checks_run: number
  regression_checks_skipped: number  # Skipped due to low complexity
  regressions_detected: number
  regressions_auto_fixed: number
  
  # Strategy effectiveness (from failure-patterns.yml tracking)
  strategy_effectiveness:
    per_strategy:
      - strategy: string
        uses: number
        success_rate: number
        avg_attempts: number
```

### Capture Points

| Event | What to Capture | When |
|-------|-----------------|------|
| Pre-validation complete | gates_run, passed, catches | After VALIDATE phase in closed-loop |
| Self-critique finding | category, severity, file | During pre-execution-validation self_review |
| Cross-stage feedback | source_stage, target_stage, items, action | During pipeline feedback loop |
| Regression check | complexity, skipped, detected, resolved | During regression check in closed-loop |
| Strategy execution | pattern_id, strategy, succeeded, attempts | After each strategy in closed-loop |

### Strategy Effectiveness Report Template

Include in session and weekly reports:

```markdown
### Strategy Effectiveness

| Strategy | Uses | Success Rate | Avg Attempts | Trend |
|----------|------|-------------|-------------|-------|
| auto_fix | {n} | {rate}% | {avg} | {trend} |
| context_expand | {n} | {rate}% | {avg} | {trend} |
| analyze_then_fix | {n} | {rate}% | {avg} | {trend} |
| dependency_check | {n} | {rate}% | {avg} | {trend} |
| retry_with_backoff | {n} | {rate}% | {avg} | {trend} |

#### Strategy Insights
- Most effective: {strategy} ({rate}% success)
- Needs review: {strategy} (below 30% success after 10+ uses)
- Common failure chains: {strategy_a} → {strategy_b}
```

### Feedback Loop Summary Report Template

Include in session reports:

```markdown
### Feedback Loop Summary

#### Pre-Execution Validation
- Runs: {n}
- Pass rate: {rate}%
- Top catches: {categories}
- Estimated cycles saved: {n} (errors caught before write)

#### Cross-Stage Feedback
- Feedback loops: {n}
- Resolution rate: {rate}% (without escalation)
- Avg iterations: {avg}
- Most active source: {stage}

#### Regression Detection
- Checks run: {n}
- Skipped (low complexity): {n}
- Regressions detected: {n}
- Auto-resolved: {n}
```

### Integration with Existing Capture Points

Update existing capture points to include feedback loop data:

```yaml
# After each stage completes
log_metric:
  task_id: {task_id}
  stage:
    stage_id: {stage}
    agent: {agent}
    duration_ms: {duration}
    outcome: {outcome}
    token_estimate: {estimate}
    # NEW: Feedback loop data
    validation_passed: boolean | null
    validation_catches: string[] | null
    feedback_items_produced: number | null
    feedback_loop_triggered: boolean | null

# On pipeline completion
log_metric:
  task_id: {task_id}
  final_outcome: {outcome}
  # NEW: Feedback loop aggregates
  feedback_loops:
    pre_validation_runs: number
    pre_validation_catches: number
    cross_stage_iterations: number
    regression_checks: number
    regressions_found: number
```

## Best Practices

1. **Log early, log often** — Capture decisions at the moment they're made, not retroactively
2. **Include rationale** — Every decision should have a clear "why"
3. **Reference task IDs** — All entries should link back to the originating task
4. **Keep estimates rough** — Token estimates are for relative comparison, don't over-engineer
5. **Promote on completion** — Don't let session metrics pile up; promote when pipelines complete
6. **Review reports** — Use weekly reports to identify patterns and improve agent prompts
7. **Track feedback loops** — Monitor pre-validation catch rates and cross-stage resolution rates to measure feedback loop effectiveness
8. **Review strategy effectiveness** — Identify underperforming strategies for improvement or replacement
