---
name: clarity-technical-communication
description: Use when writing architecture decision records, documenting trade-offs, drafting design proposals, writing postmortems, summarizing technical reasoning, or when a decision lacks documented context and clear justification.
---

# Clarity & Technical Communication

## Overview

Strengthen written engineering communication to improve decision-making and influence. Clear writing is clear thinking. If you cannot explain a decision concisely, you do not fully understand it.

## When to Use

- Writing architecture decision records (ADRs).
- Documenting trade-offs for a design choice.
- Drafting design proposals or RFCs.
- Writing postmortems after incidents.
- Summarizing technical reasoning for stakeholders.
- When a past decision lacks documented context.

## When NOT to Use

- Informal chat or quick status updates.
- Code comments that explain what, not why.

## Core Competencies

| Competency | Key Question |
|---|---|
| Decision records | Is the reasoning behind this decision documented and findable? |
| Trade-off analysis | What did we choose, what did we reject, and why? |
| Facts vs assumptions | Which statements are verified and which are beliefs? |
| Conciseness | Can this be said in fewer words without losing meaning? |
| Analytical depth | Does the explanation address root causes, not just symptoms? |

## Practice Loop

1. **Write design notes before implementation** -- one page max; scope, trade-offs, risks.
2. **Summarize trade-offs in under 10 sentences** -- force clarity by constraining length.
3. **Write postmortems after failures** -- timeline, root cause, what changed, what will prevent recurrence.
4. **Refine for brevity** -- edit ruthlessly; remove every word that does not add information.
5. **Publish structured insights** -- share learnings in a format others can reference.

## Failure Signals

Stop and rewrite if you observe:

| Signal | Root Cause |
|---|---|
| Vague reasoning | Decision rationale not articulated; "it felt right" |
| No documented context | Future readers cannot understand why a choice was made |
| Overly verbose explanations | Writer has not distilled the core argument |
| Missing trade-off analysis | Alternatives not considered or not recorded |
| Assumptions stated as facts | No distinction between what is known and what is believed |
| Postmortem with no action items | Incident analyzed but nothing changes |

## Quick Reference

```
Architecture Decision Record (ADR):

## Title
Short, descriptive name for the decision.

## Status
Proposed / Accepted / Deprecated / Superseded

## Context
What is the situation? What forces are at play?

## Decision
What did we decide? State it directly.

## Alternatives Considered
| Option | Pros | Cons | Why Rejected |
|--------|------|------|--------------|
| A      |      |      |              |
| B      |      |      |              |

## Consequences
What follows from this decision?
- Positive effects
- Negative effects or risks accepted
- What becomes easier? What becomes harder?

## Assumptions
What are we assuming that, if wrong, would change this decision?
```

```
Postmortem Template:

## Summary
One paragraph: what happened, impact, duration.

## Timeline
Chronological events from detection to resolution.

## Root Cause
The underlying cause, not the trigger.

## Contributing Factors
What made the impact worse or delayed resolution?

## What Went Well
What worked during the response?

## Action Items
| Action | Owner | Due Date | Status |
|--------|-------|----------|--------|
|        |       |          |        |

## Lessons Learned
What should change to prevent recurrence?
```

```
Trade-off Summary Format:

We chose [X] over [Y] because:
- [Fact 1 supporting X]
- [Fact 2 supporting X]

We accepted these downsides:
- [Downside 1 of X]
- [Downside 2 of X]

We would reconsider if:
- [Condition that would invalidate this choice]
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Writing the decision without the reasoning | Always document why, not just what |
| Listing only the chosen option | Record rejected alternatives and why they were rejected |
| Assumptions buried in prose | Call out assumptions in a dedicated section |
| Postmortem without action items | Every postmortem must produce specific, owned follow-ups |
| Verbose explanations masking weak reasoning | Shorten first; if the argument survives, it is strong |
| Writing for yourself instead of future readers | Assume the reader has no prior context |
