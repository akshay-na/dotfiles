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
| `log_subagent_audit` | Record subagent lifecycle audit entry (dispatch/run/complete/fail) |
| `generate_report` | Generate session, weekly, or agent performance report |
| `query_metrics` | Query metrics with filters |

## Subagent Audit Entry Schema (Swarm)

Use this schema for robust end-to-end swarm auditing:

```yaml
---
entity_name: org.global.orchestration.audit.{trace_id}.{dispatch_id}
namespace: org.global.orchestration
category: audit
status: accepted
tags: [observability, swarm, subagent-audit, {parent_agent}, {target_agent}]
created_at: ISO-8601
trace_id: string
task_id: string
parent_task_id: string | null
dispatch_id: string
agent_run_id: string
parent_agent: string
target_agent: string
dispatch_level: L1 | L2 | L3 | L4
pipeline: string
stage_id: string
workspace_root: string
event_type: dispatch | started | heartbeat | completed | failed | timeout | retry | fallback | protocol_malformed | protocol_secret_redaction
event_outcome: success | failed | blocked | degraded
attempt: number
duration_ms: number | null
token_estimate:
  input: number
  output: number
parallelism_decision: parallel | serial+blocker:<reason>
error_code: string | null
error_summary: string | null
artifact_ref: string | null
---

Compact lifecycle event payload for swarm/subagent auditing.
```

### Required fields (fail-closed for entrypoint orchestrators)

For `cto`, `tech-lead`, and `code-reviewer`, the following fields are mandatory on every `log_subagent_audit` entry:

- `trace_id`, `task_id`, `dispatch_id`, `agent_run_id`
- `parent_agent`, `target_agent`, `dispatch_level`
- `pipeline`, `stage_id`, `workspace_root`
- `event_type`, `event_outcome`, `attempt`

## Delegation and sub-agent floor observability

Policy source: `mandatory-delegation` rule + `agent-orchestration` / `parallel-dispatch`. These signals are **convention and runtime audit** — **not** enforced by git pre-commit (hooks cannot see `Task` dispatches or agent tool graphs).

### Coordinator-turn metrics (emit per coordinator invocation)

| Field | Type | Meaning |
|-------|------|--------|
| `delegation_count` | number | Direct `Task` dispatches from this coordinator in this turn (policy floor typically ≥ 6 unless justified; half-floor / overrides per mandatory-delegation). |
| `delegation_floor_met` | boolean | `true` when `delegation_count` (and any declared recursive / override rule) satisfies the active floor; `false` requires a valid `below_floor_justification`. |
| `below_floor_justification` | object \| null | Structured block when below floor: reason codes (e.g. `atomic_task`, `platform_cap_hit`), scope, timestamp. Omit or `null` when `delegation_floor_met` is `true`. |
| `inline_work_detected` | boolean | `true` if substantive work ran inline in coordinator chat instead of delegated `Task` (policy violation). |
| `brain_writes_count` | number | Count of durable `~/ai-brain/` touch-writes attributed to this turn when KB duty applies. **Convention-only:** no repo hook counts brain FS writes (cro-017); agents self-report or ledger manually. Not runtime-enforced. |
| `parallel_vs_serial_ratio` | number | Ratio of parallel sibling dispatches to serial-forced dispatches in the session slice (0..1 or parallel ÷ (parallel+serial); document which convention you use in the audit row). |
| `effective_delegation_tree_size` | number | Total agents in the recursive tree for this episode (coordinator + descendants through completed `Task`s), used to validate recursive-delegation patterns. |

### Runtime audit (where to record)

1. **Dispatch audit (append-only rows)** — `~/ai-brain/org/global/orchestration/dispatch-audit.md`  
   Each coordinator turn SHOULD add or join a row carrying at least `task_id`, `trace_id` / `dispatch_id` (when known), `delegation_count`, `delegation_floor_met` (synonym in rows: `floor_met` is acceptable if already used elsewhere), `parallel_vs_serial_ratio`, `effective_delegation_tree_size`, `inline_work_detected`, and `brain_writes_count` when entrypoint KB duty applies.

2. **Floor violations (incidents)** — `~/ai-brain/org/global/orchestration/floor-violations.md`  
   Hard violation: `delegation_count` below floor **and** missing or invalid `below_floor_justification`, or `inline_work_detected: true` for substantive scope. Append-only incident lines; do not rewrite history.

3. **Weekly / on-demand floor compliance report** — `~/ai-brain/org/global/orchestration/floor-compliance-weekly.md`  
   Generated **on demand** when the user or an entrypoint requests a delegation report (e.g. “generate delegation report”). Aggregate from `dispatch-audit.md` + `floor-violations.md` + optional `subagent-audit-log.jsonl` join keys (`trace_id`, `task_id`, `dispatch_id`). **Not** auto-scheduled in-repo; path is runtime-only under `~/ai-brain/`.

### How this differs from git hooks

- **Git pre-commit / pre-push:** validate **repository files** (lint, secrets patterns, etc.). They do **not** see Cursor `Task` dispatches, parallel shard decisions, or `~/ai-brain/` writes.
- **Runtime delegation audit:** coordinators and observability flows log the fields above into brain orchestration paths **during** the session. Treat missing rows for entrypoint turns as a policy gap, not a CI failure.

### Optional `token_stats` / `token_estimate` (cache discipline)

- Subagent YAML envelope (`templates/subagent-response.yml.tmpl`) may include advisory **`token_stats`** when the runtime provides estimates — use for **before/after** or A/B comparisons of dispatch cost, not as billing truth.
- Swarm audit rows already allow **`token_estimate: { input, output }`**; populate when available so `~/ai-brain/org/global/orchestration/` rollups can compare sessions.
- Never log raw prompts or secrets inside these fields.

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
decision_type: routing | strategy | escalation | override | dispatch | specialist_escalation | folder_resolution | fallback | cleanup_audit | intra_role_fanout | loop_partial
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
| Subagent dispatch | `trace_id`, `dispatch_id`, `parent_agent`, `target_agent`, `event_type=dispatch` | Immediately before subagent invocation |
| Coordinator turn closes | `delegation_count`, `delegation_floor_met`, `below_floor_justification`, `inline_work_detected`, `brain_writes_count` (advisory), `parallel_vs_serial_ratio`, `effective_delegation_tree_size` + dispatch-audit row | End of coordinator turn; see **Delegation and sub-agent floor observability** |
| Subagent started/completed | `agent_run_id`, `event_type`, `event_outcome`, `duration_ms` | At lifecycle transitions |
| Subagent timeout/retry | `event_type=timeout_or_retry`, `attempt`, `error_code` | On timeout/retry handling |
| Protocol degraded path | `event_type=protocol_malformed_or_secret_redaction`, `event_outcome=degraded` | When parse contract enforcement degrades |

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
~/ai-brain/projects/{project_name}/metrics/
```

**File naming:** `metric-{task_id}-{date}.md`

**Example:** `metric-task-001-2024-01-15.md`

### Index File

Maintain an index for efficient queries:

```
~/ai-brain/projects/{project_name}/metrics/_index.md
```

## Brain audit events (`log_brain_event`)

Append structured lines to `~/ai-brain/projects/<slug>/.meta/brain-audit-log.jsonl` (or org-global sink when project slug unknown).

| Event type | When |
|------------|------|
| `kb_query` | After `brain-memory-kb` lookup (include `ladder_depth`: L0–L3) |
| `kb_promote` | After promotion |
| `kb_demote` | After demotion (or advisory intent when contract not yet live) |
| `session_flag` | `fresh_eyes`, `clear_stale_trap`, etc. |
| `stale_trap` | Coordinator triggered stale-trap recovery |

**Required join keys** (mirror `verification-gates.yml` → `swarm_orchestration.brain_audit`): `trace_id`, `task_id`, optional `dispatch_id`.

**Human-readable sinks** (append-only under `~/ai-brain/org/global/orchestration/`): `brain-efficiency-audit.md`, `brain-stale-traps.md`, `memory-demotion-audit.md`.

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

### brain-memory-kb (memory mode)

The `brain-memory-kb` skill (`mode: memory`) provides the storage backend:
- Use `write` for creating metric/decision entries
- Use `read` for querying
- Use `list` for aggregation
- Namespace: `session.current/` during execution, `projects/{name}/metrics/` for persistence

## Execution Flow

### log_metric

```
1. Validate metric_data against schema
2. Generate entity_name: session.current.metric.{task_id}
3. Write via `brain-memory-kb` (`mode: memory`) with category: metric
4. Return { status: success, entry_path: ... }
```

### log_decision

```
1. Validate decision_data against schema
2. Generate decision_id if not provided
3. Generate entity_name: session.current.decision.{task_id}.{decision_id}
4. Write via `brain-memory-kb` (`mode: memory`) with category: decision
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

## Relationship to the hook-based telemetry pipeline

This skill (and the `brain-memory-kb` storage backend) covers the **agent-tier metric layer**: per-task summaries, per-stage outcomes, decision rationales, dispatch counters. Those entries live in `session.current/` and are promoted to `projects/{name}/metrics/`.

The Cursor hook pipeline (see `docs/runbooks/telemetry-pipeline.md` in each pack) covers the **runtime substrate layer**: every tool call, shell invocation, MCP request, and subagent lifecycle event is recorded as a single JSONL line under `$CURSOR_TELEMETRY_DIR/events.jsonl` with `schema_version: 1`.

The two streams are complementary:

- The hook stream is **agent-agnostic and fail-open**. It cannot encode the agent's intent or rationale; it only captures what was dispatched, when, with what outcome, and how long it took.
- The agent-observability stream is **agent-authored and fail-closed where the orchestration rule requires it**. It encodes routing decisions, rationale, alternatives, dispatch fan-outs, escalations, fallbacks, and feedback-loop counters.

When generating a session or weekly report, agents may **augment** their metric-derived report with summaries pulled from the hook stream — for example, "Total tool calls: N, with X% failure rate" — but should not duplicate the substrate data into the brain. Always cite the hook stream by reference (`~/.cursor/logs/telemetry/events.jsonl`) rather than copying entries into memory.

Operators tail the hook stream directly with `jq` for live triage; agents consume it programmatically only when they have a specific question (e.g. "how often did `Shell` fail this session?") that the agent-tier metrics don't already answer.
