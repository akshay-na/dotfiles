---
name: observability-as-design
description: Use when defining metrics before implementation, designing structured logging, setting SLO targets, instrumenting tracing boundaries, building health checks, or when an outage reveals missing signals and blind spots in operational visibility.
---

# Observability as Design

## Overview

Design systems that are measurable, debuggable, and operationally transparent. Observability is not an afterthought -- it is a design constraint. If you cannot measure it, you cannot trust it.

## When to Use

- Before implementing a new service or endpoint.
- When defining SLOs or alerting thresholds.
- When structured logging needs a schema.
- When tracing boundaries between services are unclear.
- When an outage reveals missing signals.
- When debugging requires guesswork instead of data.

## When NOT to Use

- Adding metrics to throwaway prototypes.
- Instrumenting code paths with no production traffic.

## Core Competencies

| Competency | Key Question |
|---|---|
| RED metrics | Are rate, error rate, and duration measured for every entry point? |
| Structured logging | Do logs carry request ID, user context, and operation outcome? |
| SLO candidates | What is the availability and latency target? How is it measured? |
| Leading indicators | What signals warn of failure before users notice? |
| Tracing boundaries | Can a request be traced across every service it touches? |
| Health checks | Do readiness and liveness probes reflect actual capability? |

## Practice Loop

1. **Define metrics before coding** -- decide what to measure as part of the design, not after deployment.
2. **Simulate failure** -- break a dependency and verify that the right signals fire.
3. **Test 2AM scenarios** -- can an on-call engineer diagnose the issue from dashboards and logs alone?
4. **Improve signal clarity** -- refine metrics and log fields that were ambiguous during debugging.
5. **Remove noise** -- eliminate redundant or low-value metrics that obscure real signals.

## Failure Signals

Stop and reassess if you observe:

| Signal | Root Cause |
|---|---|
| Guesswork debugging | Missing metrics or unstructured logs at failure points |
| Missing metrics during outage | Instrumentation added reactively, not by design |
| Logs without context | No request ID, no user context, no operation outcome |
| No early-warning indicators | Only alerting on failures, not on degradation trends |
| Alert fatigue | Too many noisy alerts; real signals drowned out |
| Health check lies | Probe returns healthy while the service cannot serve traffic |

## Quick Reference

```
Observability Design Template:

## RED Metrics (per entry point)
- Rate: requests per second
- Errors: error rate and error type breakdown
- Duration: latency at p50, p95, p99

## Structured Log Schema
- timestamp (ISO 8601)
- level (info, warn, error)
- request_id (trace correlation)
- user_id (who)
- operation (what)
- outcome (success, failure, degraded)
- duration_ms (how long)
- error_message (if failed)
- context (domain-specific fields)

## SLO Candidates
- Availability: % of successful responses over time window
- Latency: % of requests under target duration
- Error budget: remaining tolerance before SLO breach

## Health Checks
- Liveness: is the process running and not deadlocked?
- Readiness: can the service accept and process requests?
- Dependency checks: are critical downstream services reachable?

## Leading Indicators
- Queue depth trending upward
- Latency percentile drift (p99 rising while p50 is stable)
- Error rate increase on a single dependency
- Connection pool utilization approaching limit
- Memory or CPU approaching saturation
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Adding metrics after the first outage | Define metrics as part of design, before writing code |
| Logging free-form strings | Use structured logging with a consistent schema |
| Health check that only pings | Verify actual capability: database reachable, queue writable |
| Alerting on every error | Alert on error rate thresholds, not individual errors |
| No request correlation | Propagate a request ID through every service boundary |
| Measuring only averages | Averages hide tail latency; always measure p95 and p99 |
