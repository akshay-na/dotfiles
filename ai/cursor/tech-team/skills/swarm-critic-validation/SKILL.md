---
name: swarm-critic-validation
description: Post-merge critic pass — schema + policy-only feedback; no direct code edits.
version: 1
---

# Swarm Critic Validation

Role alias: `reviewer-critic` (invoked through `code-reviewer` or `tech-lead` loops).

## Inputs

Merged bundle + quality rules from plan metadata.

## Outputs

GAP report with pass/fail; if fail, route corrective actions back through orchestrator (never lateral Task to implementers).

## Mandatory checks

- Validate anti-dup policy enforcement is enabled.
- Validate touch-write role policy: project agents remain read-only for KB writes.
- Validate per-touch byte cap from orchestration policy is respected.

