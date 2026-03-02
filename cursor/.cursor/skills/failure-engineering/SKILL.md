---
name: failure-engineering
description: Use when designing for graceful degradation, implementing retry or circuit breaker logic, handling partial failures, evaluating idempotency, setting up dead-letter queues, or when a system lacks resilience under dependency failure or network instability.
---

# Failure Engineering

## Overview

Design systems that assume failure and degrade gracefully. Every dependency will eventually fail, every network call will eventually time out, and every queue will eventually fill up. Build accordingly.

## When to Use

- Designing retry, fallback, or circuit breaker logic.
- Reviewing idempotency of write operations.
- Handling partial failures across distributed components.
- Implementing dead-letter queues or poison message handling.
- Preparing a system for chaos testing or production hardening.
- When cascading failures are observed or suspected.

## When NOT to Use

- Single-process, in-memory operations with no external dependencies.
- Throwaway scripts or one-off data migrations.

## Core Competencies

| Competency | Key Question |
|---|---|
| Idempotency | Can this operation be safely retried without side effects? |
| Circuit breakers | Does the system stop calling a failing dependency? |
| Dead-letter handling | What happens to messages that repeatedly fail processing? |
| Backpressure | What happens when a consumer cannot keep up with a producer? |
| Partial failure | Can the system serve degraded results instead of failing entirely? |
| Chaos readiness | Has the system been tested under realistic failure conditions? |

## Practice Loop

1. **Kill dependencies** -- terminate a downstream service mid-request. Does the caller recover?
2. **Inject latency** -- add 5-30s delay to a dependency. Does the system hang or degrade gracefully?
3. **Drop packets** -- simulate unreliable network. Do retries handle it without data corruption?
4. **Restart services** -- kill and restart a component. Does it rejoin cleanly without duplicate processing?
5. **Evaluate recovery** -- measure time to recovery, data consistency, and user-visible impact.

## Failure Signals

Stop and redesign if you observe:

| Signal | Root Cause |
|---|---|
| Cascading failures | No circuit breaker; failure propagates across call chain |
| Tight dependency coupling | Caller cannot function without callee; no fallback path |
| No retry boundaries | Unbounded retries amplify load on already-failing systems |
| Data corruption under retries | Non-idempotent writes duplicated by retry logic |
| Silent data loss | Failed messages dropped without dead-letter capture |
| Recovery requires manual intervention | No self-healing; restarts leave inconsistent state |

## Quick Reference

```
Resilience Checklist:

## Idempotency
- [ ] Write operations use idempotency keys
- [ ] Retried requests produce the same result
- [ ] Database writes use upsert or conditional insert where appropriate

## Circuit Breakers
- [ ] Failing dependencies are short-circuited after threshold
- [ ] Circuit breaker has half-open state for recovery probing
- [ ] Fallback behavior defined (cached data, default response, graceful error)

## Dead Letters
- [ ] Failed messages routed to dead-letter queue after max retries
- [ ] Dead-letter messages retain original context for debugging
- [ ] Alerting on dead-letter queue depth

## Backpressure
- [ ] Producers respect consumer capacity
- [ ] Queues have bounded size with explicit overflow policy
- [ ] Load shedding applied before system saturation

## Partial Failure
- [ ] Non-critical dependencies can fail without blocking the response
- [ ] Degraded responses are clearly marked
- [ ] Feature flags can disable failing subsystems

## Chaos Readiness
- [ ] Dependency failure tested in staging
- [ ] Latency injection tested
- [ ] Recovery time measured and documented
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Retrying non-idempotent operations | Add idempotency keys before enabling retries |
| Circuit breaker with no fallback | Define what the system returns when the circuit is open |
| Dropping failed messages silently | Route to dead-letter queue; alert on depth |
| Treating all failures as transient | Distinguish transient (retry) from permanent (dead-letter) |
| No timeout on downstream calls | Every outbound call needs an explicit, tuned timeout |
| Testing only the happy path | Inject failures in staging before declaring production-ready |
