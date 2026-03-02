---
name: security-threat-modeling
description: Use when designing authentication or authorization flows, handling sensitive data, mapping trust boundaries, reviewing secret management, evaluating dependency supply chain risks, or when a feature introduces new public exposure or privilege escalation paths.
---

# Security & Threat Modeling

## Overview

Reason about trust boundaries, data exposure, and attack surface as a design activity. Security is not a review gate -- it is a constraint applied from the start. Assume hostile environments. Prefer secure-by-default.

## When to Use

- Before implementing authentication or authorization logic.
- When a feature handles sensitive data (credentials, PII, tokens).
- When mapping trust boundaries between components.
- When reviewing secret storage and rotation.
- When adding a publicly reachable endpoint or surface.
- When evaluating third-party dependencies for supply chain risk.

## When NOT to Use

- Internal tooling with no sensitive data and no external exposure.
- Read-only operations on public, non-sensitive data.

## Core Competencies

| Competency | Key Question |
|---|---|
| Sensitive data | What data would cause harm if exposed? Where does it live? |
| Trust boundaries | Where does trusted input end and untrusted input begin? |
| Least privilege | Does each component have only the permissions it needs? |
| Token lifecycles | How are tokens issued, validated, refreshed, and revoked? |
| Auth flows | Is authentication and authorization enforced at every entry point? |
| Secret rotation | Can secrets be rotated without downtime or redeployment? |

## Practice Loop

1. **Map attack surface** -- for every new feature, list what is exposed and to whom.
2. **Identify public components** -- which endpoints, ports, or storage are reachable externally?
3. **Review permission scopes** -- does each service, role, or token have minimal required access?
4. **Test malicious inputs** -- send invalid, oversized, or crafted inputs to every entry point.
5. **Review supply chain** -- audit dependencies for known vulnerabilities and excessive permissions.

## Failure Signals

Stop and reassess if you observe:

| Signal | Root Cause |
|---|---|
| Implicit trust assumptions | No validation at trust boundary; internal callers assumed safe |
| Overprivileged services | Broad IAM roles, admin tokens used for routine operations |
| Hardcoded secrets | Credentials in source code, config files, or environment defaults |
| Public exposure without intent | Storage buckets, debug endpoints, or admin panels accessible externally |
| Long-lived tokens with no revocation | Tokens that never expire and cannot be invalidated |
| No input validation | User input passed directly to queries, commands, or file paths |

## Quick Reference

```
Threat Modeling Template:

## Data Classification
- What sensitive data does this feature handle?
- Where is it stored? Where does it transit?
- Who can access it? Who should not?

## Trust Boundaries
- Where does untrusted input enter the system?
- What validation is applied at each boundary?
- Are internal service calls authenticated?

## Authentication & Authorization
- How is identity verified?
- How are permissions enforced?
- Is authorization checked at the resource level, not just the route?

## Secrets
- Where are secrets stored? (vault, env, config)
- Can they be rotated without downtime?
- Are they scoped to the minimum required access?

## Token Lifecycle
- How are tokens issued?
- What is the expiry? Is refresh supported?
- Can tokens be revoked immediately?

## Attack Surface
- What endpoints are publicly reachable?
- What inputs are accepted? What is validated?
- What happens with malformed or oversized input?

## Supply Chain
- Are dependencies pinned to known versions?
- Are vulnerability scans running in CI?
- Do dependencies request excessive permissions?
```

## Common Mistakes

| Mistake | Fix |
|---|---|
| Validating input only on the client | Validate on the server; client validation is a UX convenience |
| Using admin credentials for all services | Issue scoped credentials per service with minimum privileges |
| Secrets in environment variables without rotation | Use a secrets manager with automatic rotation support |
| Auth check only at the API gateway | Enforce authorization at each service; don't trust internal calls blindly |
| No dependency vulnerability scanning | Run automated scans in CI; alert on critical CVEs |
| Logging sensitive data | Redact tokens, passwords, and PII from all log output |
