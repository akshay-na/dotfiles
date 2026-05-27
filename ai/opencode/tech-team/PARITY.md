# Parity Doc: Cursor → OpenCode Tech Team

When you add/change/remove something in `ai/cursor/tech-team/`, mirror the change here.
This doc tracks what maps to what.

## Root mapping

| Cursor source | OpenCode target | Notes |
|---|---|---|
| `ai/cursor/tech-team/README.md` | `ai/opencode/tech-team/README.md` | Adapted for OpenCode |
| `ai/cursor/tech-team/hooks.json` | `ai/opencode/tech-team/opencode.jsonc` (plugin config section) | OpenCode uses TS plugins, not shell hooks |
| `ai/cursor/tech-team/mcp.json` | `ai/opencode/tech-team/opencode.jsonc` (`mcp` key) | Direct translation |
| `ai/cursor/tech-team/rules/` | `ai/opencode/tech-team/rules/` + `opencode.jsonc` `instructions` array | `.mdc` → `.md`, referenced by glob |
| `ai/cursor/tech-team/agents/` | `ai/opencode/tech-team/agents/` | Same markdown agents, adapted frontmatter |
| `ai/cursor/tech-team/skills/` | `ai/opencode/tech-team/skills/` | Same format (SKILL.md) |
| `ai/cursor/tech-team/configurations/` | `ai/opencode/tech-team/configurations/` | Shared YAML format |
| `ai/cursor/tech-team/contracts/` | `ai/opencode/tech-team/contracts/` | Shared |
| `ai/cursor/tech-team/docs/` | `ai/opencode/tech-team/docs/` | Shared |
| `ai/cursor/tech-team/templates/` | `ai/opencode/tech-team/templates/` | Shared |
| `ai/cursor/tech-team/hooks/` | `ai/opencode/tech-team/plugins/` | OpenCode TS plugins |

## File-by-file parity

### Rules (`rules/`)
> `ai/cursor/tech-team/rules/*.mdc` → `ai/opencode/tech-team/rules/*.md`

| Cursor | OpenCode | Status |
|---|---|---|
| `agent-orchestration.mdc` | `rules/agent-orchestration.md` | Adapted |
| `base.mdc` | `rules/base.md` | Adapted |
| `brain-conventions.mdc` | `rules/brain-conventions.md` | Adapted |
| `caveman.mdc` | `rules/caveman.md` | Adapted |
| `docs-and-decisions.mdc` | `rules/docs-and-decisions.md` | Adapted |
| `entrypoint-personalization.mdc` | `rules/entrypoint-personalization.md` | Adapted |
| `error-handling-and-security.mdc` | `rules/error-handling-and-security.md` | Adapted |
| `kokoro-audio-builder-governance.mdc` | `rules/kokoro-audio-builder-governance.md` | Adapted |
| `mandatory-delegation.mdc` | `rules/mandatory-delegation.md` | Adapted |
| `mcp-usage.mdc` | `rules/mcp-usage.md` | Adapted |
| `mode-auto-selection.mdc` | `rules/mode-auto-selection.md` | Adapted |
| `n8n-builder-governance.mdc` | `rules/n8n-builder-governance.md` | Adapted |
| `observability.mdc` | `rules/observability.md` | Adapted |
| `remotion-builder-governance.mdc` | `rules/remotion-builder-governance.md` | Adapted |
| `subagent-response-protocol.mdc` | `rules/subagent-response-protocol.md` | Adapted |
| `testing.mdc` | `rules/testing.md` | Adapted |
| `trusted-cursor-edit-zones.mdc` | `rules/trusted-opencode-edit-zones.md` | Adapted |
| `vp-research.mdc` | `rules/vp-research.md` | Adapted |

### Agents (`agents/`)
> `ai/cursor/tech-team/agents/*.md` → `ai/opencode/tech-team/agents/*.md`

| Cursor | OpenCode | Status |
|---|---|---|
| `atlassian-pm.md` | `agents/atlassian-pm.md` | Adapted frontmatter |
| `ciso.md` | `agents/ciso.md` | Adapted frontmatter |
| `code-reviewer.md` | `agents/code-reviewer.md` | Adapted frontmatter |
| `cro.md` | `agents/cro.md` | Adapted frontmatter |
| `cto.md` | `agents/cto.md` | Adapted frontmatter |
| `kokoro-audio-builder.md` | `agents/kokoro-audio-builder.md` | Adapted frontmatter |
| `n8n-builder.md` | `agents/n8n-builder.md` | Adapted frontmatter |
| `remotion-builder.md` | `agents/remotion-builder.md` | Adapted frontmatter |
| `sre-lead.md` | `agents/sre-lead.md` | Adapted frontmatter |
| `staff-engineer.md` | `agents/staff-engineer.md` | Adapted frontmatter |
| `tech-lead.md` | `agents/tech-lead.md` | Adapted frontmatter |
| `vp-architecture.md` | `agents/vp-architecture.md` | Adapted frontmatter |
| `vp-engineering.md` | `agents/vp-engineering.md` | Adapted frontmatter |
| `vp-onboarding.md` | `agents/vp-onboarding.md` | Adapted frontmatter |
| `vp-platform.md` | `agents/vp-platform.md` | Adapted frontmatter |
| `vp-research.md` | `agents/vp-research.md` | Adapted frontmatter |

### Skills (`skills/`)
> `ai/cursor/tech-team/skills/<name>/SKILL.md` → `ai/opencode/tech-team/skills/<name>/SKILL.md`

The skill files are **format-compatible** between Cursor and OpenCode. They should be kept in sync.
OpenCode discovers skills from `~/.config/opencode/skills/`.

| Skill | Status |
|---|---|
| `abstraction-judgment` | Direct copy |
| `agent-observability` | Direct copy |
| `ai-orchestration-prompt-engineering` | Direct copy |
| `atlassian-hierarchy-discovery` | Direct copy |
| `brain-memory-kb` | Direct copy |
| `caveman` | Direct copy |
| `clarity-technical-communication` | Direct copy |
| `closed-loop-execution` | Direct copy |
| `context-budget-guard` | Direct copy |
| `context-cache-discipline` | Direct copy |
| `context-memory` | Empty dir |
| `cro-loop` | Direct copy |
| `cross-stage-feedback` | Direct copy |
| `dev-reviewer-qa-loop` | Direct copy |
| `engineering-economics` | Direct copy |
| `entrypoint-clarification` | Direct copy |
| `failure-engineering` | Direct copy |
| `kb-generation` | Empty dir |
| `kb-identity` | Direct copy |
| `kb-query` | Empty dir |
| `meta-learning-engineering-retrospection` | Direct copy |
| `n8n-builder-execution-gate` | Direct copy |
| `n8n-builder-planning-gate` | Direct copy |
| `observability-as-design` | Direct copy |
| `parallel-dispatch` | Direct copy |
| `performance-runtime-literacy` | Direct copy |
| `pipeline-executor` | Direct copy |
| `pre-execution-validation` | Direct copy |
| `remotion-builder-execution-gate` | Direct copy |
| `remotion-builder-planning-gate` | Direct copy |
| `rule-enforcement` | Direct copy |
| `security-threat-modeling` | Direct copy |
| `skill-validation` | Direct copy |
| `subagent-response-protocol` | Direct copy |
| `swarm-critic-validation` | Direct copy |
| `swarm-deterministic-merge` | Direct copy |
| `swarm-task-decomposition` | Direct copy |
| `systems-design-depth` | Direct copy |
| `task-orchestration` | Direct copy |
| `team-discovery` | Direct copy |

## Configurations (`configurations/`)
Shared YAML format — no adaptation needed. All files are direct copies.

## Contracts (`contracts/`)
Shared markdown format — direct copies. Path references updated for OpenCode.

## Docs (`docs/`)
Shared markdown — direct copies.

## Templates (`templates/`)
Path references updated for OpenCode (`~/.config/opencode/` instead of `~/.opencode/`).

## Hooks → Plugins (`plugins/`)
> Cursor shell hooks → OpenCode TypeScript plugins

| Cursor hook | OpenCode equivalent | Status |
|---|---|---|
| `cursor-zone-writes.sh` | OpenCode permission system | N/A — built-in |
| `safe-shell.sh` | OpenCode permission system (`bash` permissions) | N/A — built-in |
| `subagent-task-antidup-preflight.sh` | OpenCode `task` permission rules | N/A — built-in |
| `subagent-protocol-inject.sh` | `plugins/subagent-protocol-inject.js` | TODO |
| `subagent-protocol-lint.sh` | Pre-commit hook (shared) | Same |
| `telemetry-*.sh` | `plugins/telemetry.js` | TODO |

## How to add a new file

1. Create/change in `ai/cursor/tech-team/<dirname>/<file>`
2. Adapt for OpenCode and create in `ai/opencode/tech-team/<dirname>/<file>`
3. Update this PARITY.md with the mapping
4. Update `opencode.jsonc` if rules/instructions changed
