---
name: ai-orchestration-prompt-engineering
description: Use when delegating tasks to AI agents, designing prompts for structured output, validating AI-generated code or reasoning, detecting hallucination, or when AI output needs constraint checking and human oversight before integration.
---

# AI Orchestration & Prompt Engineering

## Overview

Use AI systems as structured collaborators, not autocomplete tools. Every AI interaction should have clear boundaries, verifiable output, and human oversight. Trust nothing by default. Validate everything.

## When to Use

- Delegating a task to a specialized AI agent or subagent.
- Designing prompts that require structured, reproducible output.
- Reviewing AI-generated code, architecture, or reasoning.
- When AI output seems plausible but unverified.
- When prompt iterations are not converging on useful results.
- When deciding what to delegate vs what to do manually.

## When NOT to Use

- Simple completions where the output is trivially verifiable.
- Tasks where AI adds no leverage over direct implementation.

## Core Competencies

| Competency | Key Question |
|---|---|
| Task delegation | Is the task well-scoped with clear success criteria? |
| Structured output | Does the prompt enforce format, constraints, and boundaries? |
| Reasoning validation | Can the AI's reasoning be independently verified? |
| Hallucination detection | Are claims checked against source material or constraints? |
| Prompt iteration | Is each refinement narrowing toward precision, not adding noise? |
| Human oversight | Is there a review step before AI output is integrated? |

## Practice Loop

1. **Define task boundaries** -- specify exactly what the AI should do, what it should not do, and what success looks like.
2. **Require structured output** -- enforce format (JSON, templates, checklists) to make output parseable and verifiable.
3. **Cross-check assumptions** -- verify factual claims, API references, and reasoning against primary sources.
4. **Audit critically** -- treat AI output as a draft from a junior engineer; review before merging.
5. **Refine prompt structure** -- tighten constraints, add examples, remove ambiguity with each iteration.

## Failure Signals

Stop and reassess if you observe:

| Signal | Root Cause |
|---|---|
| Blind trust in AI output | No verification step; output accepted without review |
| Unstructured responses | Prompt lacks format constraints; output is free-form prose |
| AI-driven complexity | AI suggested abstractions or patterns that add no real value |
| Poor reproducibility | Same prompt yields inconsistent results; lacks specificity |
| Hallucinated references | AI cites APIs, libraries, or patterns that do not exist |
| Delegation without criteria | Task given to AI with no definition of done or success metric |

## Quick Reference

```
Prompt Design Checklist:

## Role & Context
- [ ] Agent role is explicit (e.g., "You are a security reviewer")
- [ ] Relevant context provided (codebase, constraints, domain)
- [ ] Scope is bounded (what to review, what to ignore)

## Task Specification
- [ ] Task is a single, clear instruction
- [ ] Success criteria defined
- [ ] Output format specified (template, schema, structure)
- [ ] Constraints stated (do NOT do X)

## Verification
- [ ] Output is independently verifiable
- [ ] Factual claims can be checked against sources
- [ ] Code suggestions can be tested
- [ ] Reasoning chain is traceable

## Iteration
- [ ] First result reviewed before accepting
- [ ] Ambiguous output triggers prompt refinement, not guessing
- [ ] Each iteration adds precision, not complexity
```

```
Delegation Decision Framework:

Delegate to AI when:
- Task is well-defined and output is verifiable
- Task benefits from broad pattern matching (search, review, comparison)
- Manual execution is tedious but verification is fast
- Output format can be constrained

Do NOT delegate when:
- Task requires judgment that cannot be verified from output alone
- Incorrect output has high cost and low detectability
- Domain knowledge is too specialized for the model
- Verification would take longer than doing it manually
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Accepting AI output without review | Treat every output as a draft; verify before integrating |
| Vague prompts expecting precise results | Add constraints, format requirements, and examples |
| Using AI to generate code you cannot review | Only delegate code you can read, test, and understand |
| Iterating prompts without tightening scope | Each iteration should reduce ambiguity, not add instructions |
| No fallback when AI fails | Define what to do when output is unusable; have a manual path |
| Trusting AI-cited references | Verify every API, library, or pattern reference against docs |
