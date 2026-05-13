---
name: context-budget-guard
description: Heuristic context budget checks using file-size and count proxies — integrates with context-cache-discipline; no tokenizer introspection claims.
version: 1
---

# Context budget guard

Use this skill **before major reads, large merges, or multi-tool bursts** when you need a **cheap, model-agnostic** signal that the session is approaching an unsafe context load.

## Non-claims (read first)

- Agents **do not** have reliable access to **true remaining context window** or **exact tokenizer token counts** from the runtime.
- This skill uses **proxies only** (bytes, line counts, call counts). Treat outputs as **rough estimates** with **up to ~2× error** acceptable; thresholds include margin by design.

## Integration

- **Prefix stability, lean rules, Task payload shape:** load and follow **[`context-cache-discipline`](./context-cache-discipline/SKILL.md)** first. This skill **does not** duplicate that material.
- **Delegation policy:** when proxies say you are hot, **mandatory-delegation** (`mandatory-delegation.mdc`) still governs **who** may do work inline vs **`Task`**.

## Proxy “units” (cumulative heuristic)

Maintain a running **`estimated_units`** for the current turn (reset per user turn unless your orchestrator policy says otherwise). **Units are not tokens** — they are comparable weights for **relative** overload only.

| Signal | Add to `estimated_units` |
|--------|-------------------------|
| File read (full file in context) | `file_size_bytes / 4` (floor 1 per file) |
| Tool call with substantial returned body | **500** × number of such calls (cap each call’s contribution at **8000** unless you have byte counts) |
| Sub-agent YAML envelope (in parent context) | **200** per envelope merged |
| Plan or long rule file read | `line_count * 8` (floor **80** for any file >10 lines) |

**Large-file shortcut:** if a file is **>500 lines** OR **>40 KiB**, treat as **high-risk for coordinator inline work** — prefer **`Task`** to a scoped sub-agent even before summing units.

## Threshold bands

Let **`U`** = `estimated_units`. Let **`W`** = a **notional window proxy** chosen conservatively:

- Default **`W`** = **1_000_000** units (~order-of-magnitude stand-in for “large context”; **tune per platform** using observability in later phases).
- **40% band:** if **`U > 0.40 * W`** before the next large action → **prefer delegation** (`Task` a sub-agent with a tight brief) rather than pulling more bulk into the coordinator.
- **80% band:** if **`U > 0.80 * W`** after an action → **force-delegate** the remainder: coordinator stops bulk work; **`Task`** fresh sub-agent(s) with shard ids + disjoint `touches[]`.

If you cannot estimate **`W`**, use the **large-file shortcut** + **40%/80%** as **relative** triggers: crossing **40%** of a **session-local baseline** you set at turn start (e.g. sum of first three tool returns) means **slow down and delegate**; **2× that baseline** ≈ **80% emergency** path.

## Coordinator checklist

1. After **read-only discovery**, estimate **`U`** for planned reads; if a single read would jump **`U`** over **40%** of **`W`** (or **2× baseline**), **`Task`** instead.
2. Before **merging** many sub-agent envelopes, ensure parent is not also holding full duplicates of child artifacts — cite paths, merge verbatim fields only (see **`subagent-response-protocol`**).
3. On **80%** crossing, **do not** “finish inline” — split remaining work across new **`Task`s** with smaller payloads.

## Calibration

Thresholds are **initial**. Prefer **`agent-observability`** + org observability phases to compare **proxy `U`** vs **observed** session behavior and **tune `W`** / multipliers — **no false precision**.
