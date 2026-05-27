# Entrypoint clarification

Use when an **entrypoint** session needs requirements before delegating or mutating product repos.

## Triggers

- Vague scope, missing success criteria, or unclear in/out boundaries
- Ambiguous workspace root(s) (multi-root)
- Conflicting mode signals (plan vs execute, builder mode, broker vs interactive)
- Pre-delegate / pre-implementation phase (not mid-approved-plan execution)

## Router vs entrypoint

| Actor | Policy |
|-------|--------|
| Generic parent/router (has not completed required **`Task`** yet) | **Task-first**; **≤1** minimal question only if **zero** actionable substance |
| Active entrypoint (`cto`, `tech-lead`, …) | This skill — up to **5** rounds; batch questions |

## Batching and rounds

- Batch up to **5** numbered questions per round.
- **Max 5 rounds** per episode (`entrypoint-personalization.yml`); round 6 → proceed with **Assumptions** block + offer correction.
- **Escape:** user says "just do it" / "use defaults" / "proceed with assumptions" → one Assumptions block, no further rounds.

## Stop when clarified

All satisfied: (1) stated goal, (2) in/out of scope, (3) verification intent, (4) entrypoint must-haves below.

Set `user_clarification_state: resolved` in session ledger when met (`dev-reviewer-qa-loop.yml`). **`tech-lead`** must not `background_auto` implementers while clarification is open.

## Entrypoint must-haves

| Entrypoint | Before delegate/implement |
|------------|---------------------------|
| `cto` | Change type + affected systems + plan vs execute intent |
| `tech-lead` | Plan ref or phase id + workspace root(s) |
| `code-reviewer` | Diff/PR/branch target |
| `n8n-builder` | Mode (`as-code`/`mcp-live`), env, workflow scope |
| `remotion-builder` | Handoff path or corpus target + audio/render constraints |
| `atlassian-pm` | Interactive checklist (writes); broker `read-only-context` → no user dialogue |
| `staff-engineer` | Files/behavior + definition of done |
| `vp-onboarding` | Target repo path + bootstrap vs refresh |

## Exceptions

| Situation | Action |
|-----------|--------|
| `pipeline: {name}` override | Skip re-clarifying pipeline choice |
| Approved plan + checkpoint gate | No new clarification rounds — checkpoints only |
| `code-reviewer` + resolvable PR/repo | Proceed; at most one batched question if repo unknown |
| `atlassian-pm` `mode=read-only-context` | **`insufficient_input`** envelope only — no clarification chat |
| Security-sensitive | Ask if blast-radius unclear; else **`security-autoclarity`** |

## Assumptions block (round 6+)

```markdown
## Assumptions
- …
Correction welcome; continuing on these unless you object.
```

## Cross-links

- Registry: `configurations/entrypoint-registry.yml`
- Knobs: `configurations/entrypoint-personalization.yml`
- Router carve-out: `rules/mode-auto-selection.md`
- Background dispatch: `configurations/dev-reviewer-qa-loop.yml`
- Builder approvals: governance skills — do not re-list approval vocab here

## Subagent briefs

Distill requirements only — no personalization essay in child **`Task`** payloads.
