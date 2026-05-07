# Content Cursor org pack

Standalone **content agency** Cursor configuration. Stow or symlink **this directory** to **`~/.cursor`** when doing editorial work; use **one pack at a time** — do not merge with the **tech** Cursor pack in the same target.

## Layout

- `agents/` — `cco`, `content-lead`, `editorial-cro`, **`chief-visual-officer`** (org singleton, visual), **`chief-profile-metrics`** (browser profile metrics when no API), **`chief-growth-strategy`** (growth intel + creator benchmarks via **`vp-research`**), content VPs, `vp-research`, etc.
- `rules/` — `agent-orchestration.mdc`, **`strict-tool-boundaries.mdc`**, `git-safety.mdc`, `orchestration.mdc`, `brain-conventions.mdc`, `vp-research.mdc`, `subagent-response-protocol.mdc`, `main-agent-response.mdc`, `mode-auto-selection.mdc`, plus copied baselines (`base`, `error-handling`, …).
- `skills/` — `content-plan-intake`, `content-git-workflow`, `generate-content-pipeline`, `content-team-discovery`, `editorial-cro-loop`, **`chief-visual-handoff`**, `brain-memory-kb`, `kb-identity`, orchestration helpers, etc.
- `configurations/` — `routing-table.yml`, `pipelines/article.yml`, `orchestration-policies/`.
- `hooks/` + `hooks.json` — subagent inject/lint (rule file: `subagent-response-protocol.mdc`).
- `docs/plans/` — implementation spec copy.

## Flow

**Plan → generate_content → git pull/commit/push** (SSH assumed for the content repo only). Commits use **`~/.gitmessage`**: **concise Conventional Commits** subject (`draft` / `staging` / `published` lifecycle types when stage-primary, else `feat` / `chore` / …) + short **Context** / **Impact** + **AI `Notes:`** per `content-git-workflow` / `brain-conventions.mdc`.

**n8n:** see `rules/orchestration.mdc` for payload fields (`task_id`, `target_paths[]`, `push_after_commit`, …).

## Specialists

No **`atlassian-pm`**, no org **QA** tier. Human reviews after automation.

## Activate (example)

After cloning or copying this pack, from the repository root that contains this `.cursor` folder:

```bash
ln -sfn "$(pwd)/.cursor" ~/.cursor
```

Or use Cursor Settings “Rules / Agents” to import this folder if your client supports multi-root pack selection.

## Brain

Durable data may still live under **`~/.cursor/ai-brain/`** (see `brain-conventions.mdc`) — shared _data_ with tech is OK; **rules/skills** here are content-only.

Private vault policy (see `brain-conventions.mdc`): **PII allowed** in private/local brain + corpus contexts when user-approved; **secrets forbidden** (passwords, API keys, tokens, private keys, cookies, MFA seeds, payment/bank secrets). Operator profile path: `~/ai-brain/org/global/operator-profile/` (layout in `_templates/operator-profile.md`).
