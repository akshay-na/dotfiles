---
name: performance-runtime-literacy
description: Use when debugging latency issues, evaluating concurrency models, reviewing connection pooling, investigating memory growth, analyzing queue backpressure, or when services degrade under load and the root cause is unclear.
---

# Performance & Runtime Literacy

## Overview

Understand runtime behavior, concurrency, and resource management deeply enough to design services that remain stable under stress. Measure before optimizing. Explain why bottlenecks occur, not just where.

## When to Use

- Debugging latency spikes or throughput collapse.
- Reviewing connection pool sizing or timeout configuration.
- Investigating unbounded memory or thread growth.
- Evaluating retry and backoff strategies.
- Analyzing queue saturation or backpressure failures.
- Preparing a service for production load.

## When NOT to Use

- Micro-optimizing code that is not on a hot path.
- Premature performance tuning before profiling.

## Core Competencies

| Area | Key Questions |
|---|---|
| TCP & connections | Pool size vs concurrency? Idle timeout? Connection churn? |
| Blocking operations | Is the hot path blocked by I/O, locks, or synchronous calls? |
| Queue behavior | What happens when the queue is full? Is there backpressure? |
| Memory & GC | Is allocation rate sustainable? Are objects retained unnecessarily? |
| Concurrency limits | Thread pool size? Kernel limits? File descriptor exhaustion? |
| Retry & backoff | Exponential backoff with jitter? Circuit breaker? Retry budget? |

## Practice Loop

1. **Load test** -- start with a small service under controlled concurrency.
2. **Observe** -- measure memory, CPU, latency percentiles (p50, p95, p99).
3. **Inject failure** -- add artificial latency, packet loss, or dependency unavailability.
4. **Identify bottlenecks** -- explain the mechanism, not just the symptom.
5. **Measure improvement** -- compare before and after with the same workload.

## Failure Signals

Stop and investigate if you observe:

| Signal | Likely Cause |
|---|---|
| Unbounded memory growth | Leaked references, unbounded buffers, missing eviction |
| Missing timeouts | Calls that hang forever under degraded dependencies |
| Retry storms | No backoff, no jitter, no circuit breaker |
| Throughput collapse | Thread pool exhaustion, head-of-line blocking, lock contention |
| Latency spikes at percentiles | GC pauses, connection pool starvation, queue head-of-line |
| Connection churn | Pool too small, idle timeout too aggressive, no keep-alive |

## Quick Reference

```
Diagnostic Checklist:

## Timeouts
- [ ] Every outbound call has an explicit timeout
- [ ] Timeouts are tuned per dependency, not a global default
- [ ] Timeout < caller's timeout (avoid cascading waits)

## Retries
- [ ] Exponential backoff with jitter
- [ ] Retry budget (max retries per time window)
- [ ] Circuit breaker on repeated failures
- [ ] Idempotency verified before enabling retries

## Connection Pools
- [ ] Pool size matches expected concurrency
- [ ] Idle connections are reaped
- [ ] Connection health checks enabled
- [ ] Pool exhaustion surfaces as a clear error, not a hang

## Memory
- [ ] Buffers are bounded
- [ ] Caches have eviction policies
- [ ] Streaming preferred over full materialization for large payloads

## Concurrency
- [ ] Thread/goroutine/task pool is bounded
- [ ] Work queue has backpressure (reject or shed load)
- [ ] No unbounded fan-out
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Global timeout for all dependencies | Tune per dependency based on observed latency |
| Retrying without backoff | Exponential backoff with jitter; cap max retries |
| Unbounded in-memory queue | Set a max size; apply backpressure or shed load |
| Ignoring tail latency | Measure p99, not just averages; averages hide problems |
| Synchronous calls on hot paths | Move to async or background processing where possible |
| No connection pool metrics | Instrument pool size, wait time, and exhaustion events |
