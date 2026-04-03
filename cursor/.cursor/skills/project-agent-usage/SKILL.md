---
name: project-agent-usage
description: Checklist for tech-lead and project agents on discovering and using typed dev/SME/QA team members with low-token, minimal-context behavior.
---

# Project Agent Usage

## When to Use

- You are `tech-lead` about to assign work to project agents.
- You are a dev/SME/QA agent unsure how to interpret team member names or scopes.
- You need a reminder on keeping context/token usage low when delegating or executing tasks.

## Team Discovery (for tech-lead)

1. **List team agents**
   - Look under `.cursor/agents/` for files whose names match:
     - `dev-*`
     - `sme-*`
     - `qa-*`
     - `devops`
2. **Read scopes**
   - For each agent file, read enough to extract:
     - The agent `name` (frontmatter).
     - The explicit scope/ownership section (what it owns and what it doesn’t).
3. **Build an internal table**
   - Maintain a mental/inline table like:
     - `| Agent | Scope |`
   - Use this table for all assignments (both sequential and parallel).
4. **Refresh regularly**
   - Re-run discovery:
     - At the start of each new plan phase.
     - After `vp-onboarding` or `tech-lead` changes the team members.

## Interpreting Names

- `tech-lead`: single execution entrypoint for the project.
- `dev-<scope>`:
  - Developer roles, scoped by layer/domain/concern.
  - Examples: `dev-frontend`, `dev-backend`, `dev-infra`, `dev-tests`.
- `sme-<domain>`:
  - Subject-matter experts for deep domains.
  - Examples: `sme-payments`, `sme-ml`, `sme-data`.
- `qa-<scope>`:
  - Quality-focused roles.
  - Examples: `qa-unit`, `qa-e2e`, `qa-manual`.
- `devops`:
  - CI/CD and infra-as-code roles when the project actually needs them.

## Low-Token, Minimal-Context Rules

- **Load only what you need**
  - When assigning or executing a task:
    - Read only the specific files and rules relevant to that task.
    - Avoid scanning the entire repo or loading all rules/skills at once.
- **Access memory directly, delegate docs research**
  - For persistent knowledge:
    - Access memory directly via the `context-memory` skill (read/write protocols in `memory-access` and `memory-capture` rules).
    - Query namespaces: `project.<name>`, `project.<name>.<domain>`, `org.global`.
  - For external documentation:
    - Ask `docs-researcher` rather than calling docs MCPs directly.
- **Keep delegation tight**
  - `tech-lead` passes each agent:
    - Only the relevant plan fragment.
    - Only the necessary file paths/snippets.
    - Only the constraints that matter for that agent’s scope.

## Parallel Work Safety

- Only run tasks in parallel when:
  - They are within the same phase.
  - They do not depend on each other’s outputs.
- For each parallel task:
  - Assign it to exactly one agent whose scope matches.
  - Ensure acceptance criteria are clear and verifiable.
- After parallel execution:
  - Aggregate results, run verification, and report back before moving to the next phase.

