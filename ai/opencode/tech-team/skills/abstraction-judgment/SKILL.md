---
name: abstraction-judgment
description: Use when deciding whether to extract a shared utility, create a base class, build a framework layer, or generalize a pattern -- especially when the pattern has fewer than three concrete instances or the abstraction adds cognitive overhead without clear payoff.
---

# Abstraction Judgment

## Overview

Introduce abstractions only when patterns are stable and the payoff is clear. Premature abstraction is more expensive than duplication. Prefer concrete, readable code until repetition proves a pattern is real and worth extracting.

## When to Use

- Before extracting a shared utility, helper, or base class.
- When tempted to generalize a pattern after seeing it twice.
- When reviewing code that feels over-abstracted or hard to follow.
- When onboarding friction traces back to framework or utility layers.
- When deciding whether to refactor or leave duplication in place.

## When NOT to Use

- Well-established patterns with clear, stable interfaces (e.g., standard middleware).
- Language or framework idioms that are expected by convention.

## Core Competencies

| Competency | Key Question |
|---|---|
| Stable repetition | Has this pattern appeared 3+ times with minimal variation? |
| Premature generalization | Am I guessing future use cases that may never arrive? |
| Cognitive cost | Is the abstraction easier to understand than the duplicated code? |
| Duplication tolerance | Is this duplication actually harmful, or just aesthetically uncomfortable? |
| Extraction timing | Am I extracting after validation, or before the pattern has stabilized? |

## The Rule of Three

Do not abstract until the pattern has appeared at least three times in concrete code.

| Count | Action |
|---|---|
| 1 occurrence | Write it inline. No abstraction. |
| 2 occurrences | Note the duplication. Tolerate it. |
| 3 occurrences | Evaluate: is the pattern stable? Are variations minor? Extract if yes. |

Exception: if the duplicated code is a correctness concern (e.g., security validation), extract earlier.

## Practice Loop

1. **Allow patterns to emerge** -- resist extracting after the first or second instance.
2. **Refactor after multiple uses** -- extract only when three or more instances share stable structure.
3. **Evaluate abstraction ROI** -- does the abstraction save more effort than it costs to understand?
4. **Simplify over time** -- revisit abstractions periodically; simplify or inline if usage shrank.
5. **Remove unused abstractions** -- delete utilities and base classes that serve one or zero callers.

## Failure Signals

Stop and reconsider if you observe:

| Signal | Root Cause |
|---|---|
| Over-generalized frameworks | Abstraction built for imagined future use cases |
| Hard-to-understand utility layers | Abstraction hides logic that callers need to understand |
| Complex configuration logic | Generalization replaced simple code with a configuration surface |
| High onboarding friction | New engineers cannot trace behavior through abstraction layers |
| Abstraction with one caller | Extracted too early; no reuse materialized |
| Parameters that toggle behavior | Abstraction is doing too many things; split or inline |

## Quick Reference

```
Abstraction Decision Checklist:

## Before Extracting
- [ ] Pattern has 3+ concrete instances
- [ ] Instances share stable structure with minor variation
- [ ] Abstraction is simpler to understand than the duplicated code
- [ ] Abstraction does not require configuration to handle variation
- [ ] Future callers are real, not hypothetical

## Red Flags (Do NOT Abstract)
- [ ] Only 1-2 instances exist
- [ ] Instances vary significantly in behavior
- [ ] Abstraction requires boolean flags or mode parameters
- [ ] Understanding the abstraction requires reading its source
- [ ] The abstraction is "just in case" for future use

## After Extracting
- [ ] Callers are simpler than before
- [ ] New team members can understand usage without reading internals
- [ ] No configuration explosion
- [ ] Abstraction has a clear, stable interface
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Extracting after two occurrences | Wait for three; tolerate duplication until the pattern stabilizes |
| Building for imagined future callers | Abstract for actual use cases, not speculative ones |
| Adding parameters to handle variation | If variations diverge, keep them separate; do not merge with flags |
| Never revisiting old abstractions | Schedule periodic review; inline or delete abstractions that lost their callers |
| Treating all duplication as bad | Some duplication is cheaper than the wrong abstraction |
| Abstracting for aesthetics | Abstraction should reduce cognitive load, not just line count |
