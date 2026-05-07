---
name: engineering-economics
description: Use when estimating infrastructure costs, comparing architectural approaches by cost, evaluating managed service trade-offs, reviewing cloud pricing models, or when a design decision has unclear cost implications or vendor lock-in risk.
---

# Engineering Economics

## Overview

Design systems that are economically sustainable. Every architectural decision has a cost dimension -- compute, storage, egress, operational overhead, and lock-in. Make cost a first-class design constraint, not a surprise on the monthly bill.

## When to Use

- Before choosing between architectural approaches with different cost profiles.
- When estimating infrastructure cost of a new feature or service.
- When evaluating managed services vs self-hosted alternatives.
- When cloud spending is growing without clear justification.
- When reviewing egress, storage, or compute-heavy designs.
- When vendor lock-in risk needs explicit analysis.

## When NOT to Use

- Early prototypes where speed matters more than cost optimization.
- Changes with negligible infrastructure impact.

## Core Competencies

| Competency | Key Question |
|---|---|
| Cloud pricing models | Is cost driven by compute, storage, egress, or API calls? |
| Egress & storage trade-offs | Can data locality or caching reduce transfer costs? |
| Operational complexity vs savings | Does the cheaper option require significantly more ops work? |
| Performance vs infrastructure | Is the performance gain worth the additional infrastructure cost? |
| Managed service lock-in | Can we migrate away without rewriting? What is the switching cost? |
| Cost at scale | Does cost grow linearly, superlinearly, or plateau with usage? |

## Practice Loop

1. **Estimate monthly cost** -- before building, calculate expected cost at current and projected load.
2. **Compare approaches** -- evaluate at least two architectural options by cost, complexity, and lock-in.
3. **Evaluate operational overhead** -- cheaper infrastructure that requires more engineering time may not be cheaper.
4. **Track spending trends** -- monitor actual vs estimated cost monthly; investigate divergence.
5. **Document cost assumptions** -- record what you assumed about usage patterns and pricing; revisit quarterly.

## Failure Signals

Stop and reassess if you observe:

| Signal | Root Cause |
|---|---|
| Hidden cost escalation | Egress, API calls, or log volume growing unmonitored |
| Overprovisioned infrastructure | Resources sized for peak but running idle most of the time |
| Complexity without ROI | Custom solution built to save cost but costing more in engineering time |
| Vendor lock-in without analysis | Proprietary APIs adopted without evaluating switching cost |
| Cost surprises after launch | No pre-launch cost estimate or monitoring in place |
| Linear cost with sublinear value | Spending scales with traffic but revenue or value does not |

## Quick Reference

```
Cost Analysis Template:

## Feature / Service
What is being built or changed?

## Cost Drivers
- Compute: instance type, scaling model, utilization
- Storage: volume, tier (hot/warm/cold), retention
- Egress: cross-region, cross-cloud, internet-bound
- API calls: pricing per request, batch vs individual
- Managed services: per-unit pricing, minimum commitments

## Monthly Estimate
- At current load: $___
- At 10x load: $___
- Cost growth model: linear / superlinear / capped

## Alternative Approaches
| Approach | Monthly Cost | Ops Overhead | Lock-in Risk |
|----------|-------------|--------------|--------------|
| Option A | $___        | low/med/high | low/med/high |
| Option B | $___        | low/med/high | low/med/high |

## Operational Overhead
- Does this require dedicated engineering time to operate?
- Is there on-call burden? Maintenance burden?
- What breaks if no one touches it for 6 months?

## Lock-in Assessment
- Can we migrate to another provider without rewriting?
- What is the estimated switching cost (time, engineering, risk)?
- Are we using proprietary APIs or open standards?

## Cost Assumptions
- Expected traffic pattern (steady, bursty, seasonal)
- Data retention requirements
- Growth rate projection
- Review date: ___
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Ignoring egress costs | Map data flow across regions and boundaries; estimate transfer volume |
| Sizing for peak load permanently | Use autoscaling or scheduled scaling; right-size for typical load |
| Choosing managed services without exit plan | Evaluate switching cost before adopting; prefer open standards |
| No cost monitoring after launch | Set budget alerts; review actual vs estimated monthly |
| Optimizing cost before measuring | Profile actual usage first; optimize the largest cost driver |
| Treating engineering time as free | Factor in ops burden, on-call cost, and maintenance when comparing options |
