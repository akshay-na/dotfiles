---
name: dev-reviewer-qa-loop
description: Dev–Reviewer–QA closed-loop orchestration for implementation tasks — sequence, escalation, retries, merged-diff fan-in, loop state tracking. Invoke when coordinating tech-lead or code-reviewer workflows that chain dev-, reviewer-, and qa-* agents or senior-dev fallback.
version: 1
input_schema:
  required:
    - name: task_brief
      type: string
      description: Short implementation or review task descriptor (acceptance slice, phase goal, PR scope anchor).
  optional:
    - name: merged_diff
      type: object
      description: |
        When tech-lead fans out N dev-* instances on disjoint touches, pass one merged-diff bundle for reviewer pass.
        Shape: `{ instances: [{ instance_id: string, touches: string[], diff_hash: string }], merged_diff_hash: string }`.
        Omit when a single-dev diff is inlined in orchestration context elsewhere.
output_schema:
  required:
    - name: loop_status
      type: string
      description: in_progress | passed | escalated | terminated_stagnant_fingerprint | terminated_stagnant_diff | terminated_token_budget | max_iterations_exceeded.
    - name: feedback_items
      type: object
      description: |
        Array semantics (`feedback_items[]`): unified review/QA findings; each element MUST declare originating_instance
        (`cross-instance` or a merged_diff.instance_id). Minimal shape per element `{ originating_instance, file, line_band,
        severity, normalized_concern_hash, concern, suggested_fix? }`; callers MAY materialize native JSON arrays.
    - name: iterations_used
      type: number
      description: Count of completed merged-diff loop cycles (increment once per merged review cycle, not per dev-* instance fan-out shard).
    - name: tokens_consumed_reported
      type: number
      description: Cumulative tokenizer usage attributed to loop (caller aggregates per-iteration child reports into loop state budget).
  optional:
    - name: merged_diff_hash
      type: string
      description: Echo of merged diff hash when merged_diff input supplied.
---

# Dev–Reviewer–QA closed loop protocol

Orchestration pattern lifted from vp-onboarding (Dev-Reviewer-QA closed loop section). Applies when reviewer and/or QA agents exist—or when invoking three sequenced senior-dev prompts as fallback—for each implementation-shaped task.

## Loop Flow

When the project has reviewer and/or QA agents and a dev task modifies functionality,
execute the Dev–Reviewer–QA closed loop for each implementation task. The reviewer cross-checks both `dev-*` and `qa-*` output within the same loop and may consult `sme-*` when domain expertise is required.

```
tech-lead
↓ assigns
dev-<scope>
↓ reports
reviewer-<scope> (reviews dev code; may consult sme-_)
↓ approved ↓ changes_requested
qa-<scope> tech-lead → dev-<scope> (retry)
↓ reports
reviewer-<scope> (reviews qa tests; may consult sme-_)
↓ approved ↓ changes_requested
DONE tech-lead → qa-<scope> (retry)
```

Failures from `qa-*` against the system under test (SUT) still loop back to `dev-*`.
Issues within tests themselves (coverage, correctness, gamed fixtures) loop back to `qa-*`.

## Loop Protocol

```
for each implementation_task in phase:
iteration = 0
max_iterations = 3 # configurable per project
task_token_budget = 50000 # default ceiling for whole task tokens; subdivide across parallel instances when merged_diff present

    while iteration < max_iterations:
        iteration += 1
        retry_target = "dev"  # who we re-dispatch to on failure this iteration
        tokens_consumed = record_tokens_this_cycle() # propagate into loop_state.iterations[-1]

        # Step 1: Dev implements/fixes (only if retry_target is dev)
        if iteration == 1:
            invoke dev-<scope> with task_context
        elif retry_target == "dev":
            invoke dev-<scope> with task_context + combined_feedback
        # else: dev output is unchanged from last iteration; skip

        dev_result = last_dev_result_or(await dev-<scope> completion)

        # Step 2: Reviewer cross-checks the dev code (if reviewer agents exist)
        if reviewer_agents_exist:
            invoke reviewer-<scope> with:
                - target: "dev_code"
                - dev_result (files changed, approach)
                - iteration count
                - previous feedback (if any)
                - merged_diff bundle when fan-out merged reviewers see one diff
                - may_consult_sme: true

            reviewer_dev_feedback = await reviewer-<scope> completion
            assert every finding declares originating_instance (instance id | cross-instance)

            if reviewer_dev_feedback.status == "changes_requested":
                combined_feedback = reviewer_dev_feedback
                retry_target = "dev"
                if should_escalate_or_terminate(loop_state):
                    escalate_to_user(combined_feedback)
                    await user_guidance
                continue  # back to Step 1 with reviewer feedback → dev

        # Step 3: QA creates/updates tests and runs them (if QA agents exist)
        if qa_agents_exist:
            invoke qa-<scope> with:
                - dev_result (files changed, approach)
                - reviewer_dev_feedback (if any)
                - iteration count
                - previous feedback (if any)

            qa_feedback = await qa-<scope> completion

            if qa_feedback.status == "failed":
                combined_feedback = merge(reviewer_dev_feedback, qa_feedback)
                retry_target = "dev"
                if should_escalate_or_terminate(loop_state):
                    escalate_to_user(combined_feedback)
                    await user_guidance
                continue  # back to Step 1 with qa feedback → dev

            # Step 4: Reviewer cross-checks qa output (tests, fixtures, coverage)
            if reviewer_agents_exist:
                invoke reviewer-<scope> with:
                    - target: "qa_tests"
                    - qa_result (tests created/updated, coverage)
                    - dev_result
                    - iteration count
                    - merged_diff fingerprinting for originating_instance routing
                    - may_consult_sme: true

                reviewer_qa_feedback = await reviewer-<scope> completion

                if reviewer_qa_feedback.status == "changes_requested":
                    combined_feedback = reviewer_qa_feedback
                    retry_target = "qa"
                    if should_escalate_or_terminate(loop_state):
                        escalate_to_user(combined_feedback)
                        await user_guidance
                    continue  # back to Step 3 → qa

            mark task complete
            break
        else:
            if reviewer_dev_feedback.status == "approved":
                mark task complete
                break

        if should_escalate_or_terminate(loop_state):
            escalate_to_user(combined_feedback)
            await user_guidance

    if iteration >= max_iterations and not passed:
        escalate_to_user("Max iterations reached without passing")
```

## Escalation Triggers

The orchestrator terminates retry cycles (surface to human) when **`should_escalate_or_terminate(loop_state)`** is true:

1. **`iteration >= max_iterations`** — always escalate (legacy rule retained).
2. **Repeated findings fingerprint** — `findings_fingerprint = (file, line_band, severity, normalized_concern_hash)` per finding from reviewer or qa feedback; **if iteration k repeats any fingerprint emitted in iteration k-1**, stop further automated retries → escalate (`terminated_stagnant_fingerprint`).
3. **Stagnant diff** — if **`diff_hash` is identical across two consecutive retry cycles**, stop → escalate (`terminated_stagnant_diff`). Compare after dev or qa submits a new revision.
4. **Token budget overrun** — each iteration attaches **`tokens_consumed`** into loop state (child session metrics); **`sum(tokens_consumed over loop) > task_token_budget`** OR per-iteration allotment exceeded after equal split (`task_token_budget / N` instances for merged_diff) terminates with `terminated_token_budget`. Budget propagates to downstream agents in task_context.
5. **Reviewer / blocker escalations retained** — still escalate when **`cannot_fix`** from dev or qa; **`combined_feedback.error_type` in `{framework_error, env_error, ci_mismatch}`**; **reviewer severity `critical`** on either dev-code or qa-test target; reviewer SME hook requests **`escalate_to_org`**. Replace coarse `same_file + same_concern` duplication checks with fingerprint rule (rule 2) for automated halt.

Optional human-directed early success: **reviewer explicitly approves staged outputs** paired with qa pass ends loop without escalating (not a halt condition).

## Retry Contexts

### Context passed to dev on retry

When re-invoking `dev-*` after reviewer (dev-code review) or QA flags issues on the SUT, include:

```yaml
retry_context:
  retry_target: dev
  iteration: 2
  original_task: "Implement user authentication"
  previous_attempt:
    files_changed: [src/auth.ts, src/middleware.ts]
    approach: "JWT-based auth with middleware validation"
  reviewer_dev_feedback:
    status: changes_requested
    issues:
      - file: "src/auth.ts"
        line: 45
        severity: high
        concern: "Missing input validation on token parameter"
        suggested_fix: "Add validation before processing token"
        originating_instance: "dev-backend-1"
    analysis: "Security concern - user input not sanitized"
    sme_consultation:
      sme_agent: sme-auth
      verdict: "Confirmed: our token spec requires nonce validation"
  qa_feedback:
    tests_failed:
      - test: "test_invalid_token"
        error: "expected 401, got 500"
        file: "tests/auth.test.ts:42"
    analysis: "Error handler returns 500 for all auth errors"
    suggested_fix: "Check auth.ts:78 - missing case for invalid tokens"
  instruction: |
    Address feedback from reviewer-of-dev and/or QA on the implementation.
    Focus on suggested fixes surfaced in combined feedback for your originating_instance only unless marked cross-instance.
    Do not modify tests; avoid unrelated churn.
```

### Context passed to qa on retry

When re-invoking `qa-*` after reviewer cross-check flags test issues:

```yaml
retry_context:
  retry_target: qa
  iteration: 2
  original_task: "Test user authentication"
  previous_attempt:
    files_changed: [tests/auth.test.ts]
    approach: "Unit tests for JWT validation and middleware"
    test_results: { passed: 12, failed: 0 }
  reviewer_qa_feedback:
    status: changes_requested
    issues:
      - file: "tests/auth.test.ts"
        line: 88
        severity: high
        concern: "Test asserts only on HTTP status; does not verify invalid token avoids session persistence"
        suggested_fix: "Add assertion that sessionStore.put was not called"
        category: correctness
        originating_instance: "qa-unit-1"
    analysis: "Test passes without proving security guarantee"
    sme_consultation:
      sme_agent: sme-auth
      verdict: "Session leakage check required by auth policy"
  dev_context:
    files_changed: [src/auth.ts, src/middleware.ts]
  instruction: |
    Address reviewer feedback on tests only (fixtures/mocks/assertions).
    Do not mutate production paths unless blocker noted through tech-lead.
```

## Loop State Schema

Maintain loop state in session memory for observability (path pattern `session.current/dev-reviewer-qa-loop-{task_id}.md`):

```yaml
task_id: task-a1b2c3-implement-auth
phase: 2
task: "Implement user authentication"
status: in_progress | passed | escalated
task_token_budget: 50000
tokens_consumed: 8120 # cumulative; sum of iterations for quick check
tokens_consumed_budget_note: >-
  When merged_diff.present, per-instance soft cap floor(task_token_budget / N instances)
merged_diff:
  merged_diff_hash: "sha256:…"
last_diff_hash_by_retry: ["sha-first", "sha-first"] # detect stagnancy across two retries
fingerprints_prior_iteration: [["src/auth.ts", "40-52", "high", "h7f3…"]]
iterations:
  - iteration: 1
    dev_agent: dev-backend
    reviewer_agent: reviewer-security
    qa_agent: qa-unit
    tokens_consumed: 2100
    sme_consulted: [sme-auth]
    dev_result: { files: [...], status: completed, diff_hash: "sha:dev-iter1" }
    reviewer_dev_result: { status: changes_requested, issues: 1 }
    qa_result: null
    reviewer_qa_result: null
    looped_back_from: reviewer_dev
    retry_target: dev
    duration_ms: 35000
  - iteration: 2
    dev_agent: dev-backend
    reviewer_agent: reviewer-security
    qa_agent: qa-unit
    tokens_consumed: 1900
    sme_consulted: []
    dev_result: { files: [...], status: completed, diff_hash: "sha:dev-iter2" }
    reviewer_dev_result: { status: approved }
    qa_result: { status: failed, tests_failed: 2 }
    reviewer_qa_result: null
    looped_back_from: qa
    retry_target: dev
    duration_ms: 45000
  - iteration: 3
    tokens_consumed: 2200
    dev_result: { files: [...], status: unchanged, diff_hash: "sha:dev-iter2" }
    reviewer_dev_result: { status: approved }
    qa_result: { status: passed }
    reviewer_qa_result: { status: approved }
    looped_back_from: null
    retry_target: null
final_status: passed
total_iterations: 3
total_duration_ms: 120000
```

## Callers

- **`tech-lead`** — in-plan implementation phases: per-task orchestration, prefers small diffs per iteration, frequent loop cycles with project `dev-*` / `reviewer-*` / `qa-*`.
- **`code-reviewer`** — end-of-phase or pre-PR gate: consumes full workspace diff, runs final unified review pass; still emits `feedback_items` with `originating_instance` when merged fan-out occurred upstream.

## Default Invocation

Loop is **default ON** for any implementation phase when the active workspace folder contains **both** `reviewer-*` and `qa-*` agent files under `.cursor/agents/`. Opt-out is **plan-level only** via top-level `loop_disabled: true` (hotfix escape); **do not** toggle per phase ad hoc.

Operating modes:

1. **Full team** — `dev-* → reviewer-* → qa-* → reviewer-*` on qa artifacts.
2. **Partial** — missing one role runs whatever stages exist and logs `[tech-lead] loop_partial reason=no_<role>` (concretely `no_reviewer` or `no_qa` when applicable) while continuing permitted steps.
3. **Fallback** — neither reviewer nor qa present (bare workspace + senior-dev): run **`senior-dev` implementation → senior-dev self-review → senior-dev qa-test prompt** sequentially; same agent identity, distinct prompts—**no intra-agent parallelism.**

## Merged-diff input from intra-role fan-out

When tech-lead fans out parallel `dev-*` instances:

- Structured input: **`merged_diff: { instances: [{ instance_id, touches[], diff_hash }], merged_diff_hash }`**.
- Review pass consumes **single merged reviewer invocation** keyed by `merged_diff_hash` (avoid N reviewer sessions on isolated shards unless policy says otherwise downstream).
- **Findings mandate `originating_instance`** — reviewer sets instance id tying to shard, or **`cross-instance`** when fix spans shards.
- On `changes_requested`, tech-lead **routes feedback slices** back to owning instance; **cross-instance** issues force **re-merge / coordinated follow-up across all N instances** before next merged review.
- **Loop iteration counter advances once per merged-diff cycle**, not per instance completion.
- **Token budget** — default **50k tokens per task**, split **evenly** (`floor(50000 / N)`) across instances for soft caps; orchestrator still enforces global `task_token_budget` on aggregate `tokens_consumed`.

---

**Source provenance**: extracted from vp-onboarding.md (loop ASCII, pseudocode, escalation scaffold, retry YAML, loop-state YAML); extended with R5 termination, merged-diff contract, callers, invocation defaults aligned with CTO plan Phase P1a.
