---
name: systems-design-depth
description: Use when designing scalable systems, evaluating consistency models, planning state management, making architectural decisions, or when trade-offs around coupling, failure isolation, and reversibility need explicit reasoning before implementation.
---

# Systems Design Depth

## Overview

Design scalable, evolvable systems with explicit reasoning about state, consistency, and failure. Every architectural decision should be deliberate, documented, and reversible where possible.

## When to Use

- Before implementing a new service or system boundary.
- When choosing between strong and eventual consistency.
- When evaluating how state flows across components.
- When scaling concerns arise before or during implementation.
- When coupling between modules feels implicit or unclear.

## When NOT to Use

- Trivial CRUD with no scaling or consistency concerns.
- Prototypes explicitly meant to be thrown away.

## Core Competencies

| Competency | Key Question |
|---|---|
| State transitions | Where does state live and how does it change? |
| Consistency trade-offs | Do we need strong or eventual? What breaks if stale? |
| Reversibility | Can this decision be undone without rewriting? |
| Coupling | What changes if this component changes? |
| Scaling boundaries | What breaks first at 10x load? |
| Distributed simplicity | Can a simpler model achieve the same goal? |

## Practice Loop

Before implementing any significant system change:

1. **Write a design note** -- one page max covering scope, state, and boundaries.
2. **Identify failure modes** -- what breaks, what degrades, what is unrecoverable.
3. **Evaluate scaling limits** -- where does the design hit a wall.
4. **Document trade-offs** -- what you chose, what you rejected, and why.
5. **Revisit post-implementation** -- compare assumptions against observed reality.

## Failure Signals

Stop and reassess if you observe:

- Microservices introduced without clear domain boundaries.
- Shared mutable state hidden behind service interfaces.
- Architectural decisions that cannot be reversed without rewrite.
- Failure in one component cascading across unrelated components.
- Consistency model chosen by default rather than by requirement.

## Quick Reference

```
Design Note Template:

## Context
What problem are we solving? Why now?

## State
Where does state live? Who owns writes? Who reads?

## Consistency
Strong or eventual? What is the staleness tolerance?

## Failure Modes
What fails? What degrades gracefully? What is unrecoverable?

## Scaling Limits
What breaks at 10x? At 100x? What is the first bottleneck?

## Trade-offs
What did we choose? What did we reject? Why?

## Reversibility
Can we undo this? What is the cost of changing course?
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Choosing microservices by default | Start monolithic, extract when boundaries stabilize |
| Ignoring consistency requirements | Ask "what happens if data is stale?" for every read path |
| Coupling through shared databases | Define ownership boundaries; use APIs at service edges |
| No failure mode analysis | List what breaks before writing code |
| Premature scaling optimization | Measure first, scale what is actually bottlenecked |
