---
name: bug-bot-investigation
description: Bounded bug/regression hunt methodology for org agent bug-bot — ScopeClass resolve, P0–P6 phase machine, capped defect packs, user-ask-only test signal, redact-before-write.
---

# Bug-bot investigation

Methodology for org entrypoint **`bug-bot`** (not vendor `bugbot`). Keep `agents/bug-bot.md` thin — this skill owns hunt procedure, caps, suite policy, finding schema, and empty-diff outcomes.

**Product trees:** read-only. Durable write = bug report under `<project>/.cursor/docs/bugs/` (+ optional worktree cleanup). Suggest fixes; **do not** implement.

## Precedence (empty-diff)

This skill’s empty-but-valid outcome (**`ok` + `scope_card` + zero findings**; do **not** widen history) **supersedes** stop/fail language in `~/ai-brain/org/global/runtime/agents/bug-bot-investigation-depth-design.md`. That file is **reference only** for depth heuristics; **skill wins at runtime** on empty-diff and suite policy.

Pointer: plan `.cursor/docs/plans/2026-08-09-bug-bot-org-agent.md` Assumption #10 / P1.

---

## ScopeClass (fail-closed)

Exactly **one** primary class. Ambiguous or missing target → **`blocked`** (ask once if clarification skill applies; do not invent scope).

| ScopeClass | Resolve | Notes |
|---|---|---|
| `commits` | One or more commit SHAs | Diff those commits / spanning range |
| `last_n` | `HEAD~N..HEAD` | **Default N=5**; **hard max 20** — above max → ask re-scope (do not silently clamp widen) |
| `range` | Explicit A..B / merge-base range | Prefer ≤**50** commits; above → recommend re-scope or hotspot-only |
| `pr_url` | PR URL → isolated worktree (`bug-` prefix; CR Phase-2 parity) | Never checkout into user WT; degrade to `gh pr diff` on WT fail |
| `uncommitted` | Staged + unstaged vs `HEAD` | **Opt-in only** — user must explicitly include dirty tree |

Emit **`scope_card`** before deep work: `{target_type, base, head, merge_base?, file_count, line_count, languages[], risk_tags[], worktree_path?, last_n?}`.

### Empty / missing outcomes

| Condition | Status | Action |
|---|---|---|
| Valid target, empty diff (no changed files/lines) | **`ok`** | Emit `scope_card` + **zero findings**; **do not** widen to older history / larger N |
| Missing, unreadable, or ambiguous target | **`blocked`** | Stop; no invent / no widen |

---

## Caps (hard)

| Cap | Value |
|---|---|
| `last_n` default / max | **5** / **20** |
| Commit range (recommend) | ≤**50** commits |
| Deep-read files (`investigate_set`) | ≤**40** |
| Symbols tracked | ≤**25** |
| Callgraph hops | ≤**2** (hop0=changed; hop1=callers/callees; hop2=critical only) |
| Defect packs / episode | ≤**3** |
| Wall-clock | ~**35m** hard (soft finish earlier; then synthesize + stop) |
| Test-signal cmds / time | ≤**2** cmds **and** ≤**10m** (P5 only; see suite policy) |

**Risk-rank before deep read.** Overflow → `skip_set` / `truncated: true` with reason. Prefer high fan-in / public API / concurrency / error-path over leaf docs/UI.

---

## Phase machine (P0–P6)

```
P0 resolve → P1 change map → P2 callgraph → P3 regression vs base
  → P4 deep packs → P5 optional test signal → P6 quality gate → STOP
```

### P0 — Resolve target

Map user input → ScopeClass; build diff commands; PR → worktree rules; emit `scope_card`. Fail-closed on missing target. Empty-but-valid → **`ok`** path (skip P1–P5 deep work; still run P6 redact/gate lightly).

### P1 — Change map + triage

1. Classify files: `hot_path` | `pure_refactor` | `test` | `config` | `generated` | `docs` | `deps`.
2. Extract changed symbols (AST/heuristic; hunk headers fallback).
3. Score: concurrency, error-path density, API boundary, fan-in, test gap.
4. Emit `investigate_set` / `watch_set` / `skip_set` (≤40 deep).

### P2 — Callgraph (bounded)

Top ≤25 symbols; ≤2 hops. Flag signature drift, removed defaults, exception-type change, weaker validation, dual-write / cache-key mismatch. Truncate → `truncated_callgraph: true`.

### P3 — Regression vs base

Compare vs **merge-base / parent SHA**, not “ideal code.”

| Axis | Check |
|---|---|
| Behavior | Unchanged contracts: same inputs → same outputs/side-effects |
| Error surface | Errors still propagate (no new swallow) |
| Concurrency | Lock/ordering/ack not weakened |
| Resources | Paths still release pool/handle/file/timer |
| Idempotency | Retries / duplicate delivery still safe |
| Observability | Critical path still loggable/metricable if base had it |
| Tests | Which existing tests **should** fail if hypothesis true |

**CI green = weak signal**, not absence of bugs. Required: `## Regression gaps` — ≥1 row per `high` hypothesis **or** `no_high_hypotheses`.

### P4 — Deep defect packs (pick ≤3)

Apply packs matching triage tags only. Each hit → finding with **concrete `fix`** + `file:line`.

| Pack id | Hunt for |
|---|---|
| null/edge | Optionality without guards; map `.get` sans default; partial init |
| error-swallow | Empty catch / `_ =`; fail-open; missing timeout/budget |
| race/concurrency | Shared mutable sans sync; TOCTOU; ack-before-persist; cancel ignored |
| idempotency | Double write/charge on retry; missing dedupe key |
| state machine | Illegal transition; missing cleanup on timeout |
| API contract drift | Field/type/status meaning change without version/compat |
| off-by-one | `<=` vs `<`; pagination overflow; 0/n boundary |
| resource leak | Borrow w/o return on error; timer/goroutine/listener leak |
| partial failure | Batch all-success lie; multi-step sans compensate |

### P5 — Suite / test-signal (default skip)

**Default: skip.** Do **not** own QA loops.

**Enable only if the user explicitly asks** (explicit user ask / “user ask” for suite or named test cmds) **in that hunt**.

- Cap: ≤**2** cmds / **10m**.
- **DENY** auto-run for **high-sev + CI-stale** (and any other auto path). High findings + stale CI do **not** authorize suite execution without explicit user ask.
- **Allowlist bind (cro-007):** permitted command prefixes **MUST** match the **plan-declared verification allowlist** in `rules/agent-orchestration.mdc` (repo-root prefixes: `make test`, `npm test`, `pytest`, …). **Do not invent a parallel secret allowlist** — xref agent-orchestration; extend only when that rule’s list grows.
- **Deny free-form shell** even after user ask unless the command is on that allowlist **or** the user issues **named approval** in-chat for one specific extra command.
- Capture: command, SHA, exit, counts only — no secret-bearing logs.
- Green ≠ clean; red confirms hypothesis only when aligned.
- Residual risk: recipes behind allowlisted names can be rewritten by the change-under-test (Makefile/script poison) — suite output is signal, not proof.

### P6 — Quality gate

| Check | Pass |
|---|---|
| Scope fidelity | Report SHAs / ScopeClass match tree |
| Coverage | Every `investigate_set` file: finding / clean / truncated |
| Fix present | Every finding has concrete `fix` |
| Regression section | Present (or empty-diff short path) |
| Caps honesty | Truncations listed |
| Read-only | No product mutation |
| Redact | Pass redact-before-write (below) |

Fail gate → `warn` + partial findings (no silent polish). No “production-safe LGTM” / Approve verdict.

---

## Finding schema (hard)

Every finding **requires** a concrete `fix` (code or steps). Drop or rewrite vague “consider improving.”

```yaml
severity: critical|high|medium|low
category: nullability|error_handling|race|idempotency|state_machine|api_drift|off_by_one|resource_leak|partial_failure|regression_gap|other
file: <path>
line: <N>
issue: <what is wrong>
impact: <user/system effect>
confidence: high|medium|low
fix: <concrete fix — required>
```

Security-category / high+ findings → security-autoclarity (full clarity; no caveman compression of negations).

---

## Redact-before-write (fail-closed)

Before writing `<project>/.cursor/docs/bugs/…`, chat synthesis, or envelope fields that may hold tool output:

1. Scan with the **same secret pattern library** as `subagent-response-protocol` (AWS, Slack, Anthropic `sk-ant-`, OpenAI, Stripe, GitHub/GitLab, npm, JWT, Bearer, URL userinfo, private keys, high-entropy tokens, etc.).
2. On match → **do not** write raw value; replace with `<REDACTED:TYPE>` (or `<REF:artifacts[i]#L…>`).
3. Suspected leak → fail-closed: refuse unredacted body; set incident / `secret_leak` signal; follow protocol `suspected_secret_in_output` path (project runbook under `.cursor/docs/runbooks/`).
4. Never paste full secret-bearing shell/CI logs into the report.

---

## Specialist fan-out (pointer)

Optional `Task` when triage tags warrant: `ciso`, `vp-engineering`, `sre-lead`, `staff-engineer`, `vp-research`. Never `Task` `code-reviewer` or `cro`. Floor override **3 / target 5** — under-floor always `below_floor_justification` + dispatch-audit (incl. solo/`atomic_task`). Details: `agents/bug-bot.md` + `mandatory-delegation`.

---

## Anti-patterns

- Widening empty-but-valid scope to “find something”
- Auto suite on high-sev + CI stale
- Free-form shell / invented test cmds outside agent-orchestration allowlist without named approval
- Findings without concrete `fix`
- Style-primary noise (route style to `code-reviewer`)
- Implementing product fixes in-hunt
- Checking out PR into user working tree
- Shipping unredacted secret-shaped strings
