# Trusted edit zones (review policy)

## Status

**Policy tier:** **T0 — policy only** in the Gemini pack today. The matching `BeforeTool` hook adapter is **not ported** (see `docs/runbooks/cursor-only-exclusions.md`, `docs/runbooks/gemini-hooks-parity.md`). When the hook lands it will graduate to **T1 — technical**, mirroring the Cursor `cursor-zone-writes.sh` enforcement (matched on both literal and `realpath`-resolved canonical form).

## Auto-accepted zones (intent — enforcement deferred)

Any agent **may** create, update, move, or delete files under the paths below **without** user approval. Until the hook adapter ships, this is **operator policy** — not a programmatic gate. Operators who want strict gating today should keep Gemini's default approval flow on.

| Scope                         | Path pattern                                                                          | Covers                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| Global Gemini docs            | `$HOME/.gemini/docs/**`                                                               | Plans, runbooks, reviews, decision records authored by Gemini agents         |
| Global Gemini memory          | `$HOME/.gemini/memory/**`                                                             | Short-lived / session memory under Gemini home (FSM mirrors, run telemetry)  |
| Unified ai-brain              | `$HOME/ai-brain/**`                                                                   | Org memory, `projects/`, `session/` (under writer policy in `brain-conventions.md`) — **skeleton paths still no-write** (`_schema/`, `_templates/`, root `README.md`, `.gitignore`) |
| Dotfiles stow (same inode)    | `$HOME/dotfiles/ai/gemini-content-team/docs/**`, `$HOME/dotfiles/ai/ai-brain/**`      | Tracked source for stowed symlinks; same file as the corresponding stow target |
| Workspace / project Gemini tree | `<workspace_root>/.gemini/**`                                                       | Project rules, agents, skills, docs, hook scripts, configurations            |

**Why this is safe:** files under these zones are Gemini-agent artifacts by design — rules, agents, skills, memory, documentation, hook scripts, KB docs, and the ai-brain vault (`brain-conventions.md`). They are not the working tree of the product being built; they are the configuration and memory that shape how Gemini behaves. Routine review-for-writes inside these zones is high-friction and low-value, so the intended posture is auto-accept and rely on source control (`git status` / `git diff` / PR review) and brain dedupe policy as the audit trail.

## Out-of-scope (normal approval still applies)

- Writes to a project's **working tree** (anything not under `<workspace>/.gemini/`)
- Writes under `~/.gemini/` **outside** `docs/`, `memory/` (for example `~/.gemini/agents/`, `~/.gemini/skills/`, `~/.gemini/rules/`, `~/.gemini/hooks/`, `~/.gemini/settings.json` — still require explicit approval unless the resolved path is the dotfiles stow target for those files)
- Shell commands outside whatever read-only allowlist a future `safe-shell` Gemini adapter would enforce — until that hook ports, **all** shell commands follow Gemini's default approval flow
- Destructive operations, secret handling, and anything explicitly covered by other always-applied rules (e.g. `error-handling-and-security.md`, brain-skeleton no-write in `brain-conventions.md`) — those rules still govern even inside the auto-accepted zones

## Stow / dotfiles guidance (editing practice, not approval gate)

When edits land under paths like `$HOME/dotfiles/ai/gemini-content-team/**` or `$HOME/dotfiles/ai/ai-brain/**`:

- Prefer editing the tracked source in the dotfiles repo (that's what stow symlinks point at — both `~/ai-brain/foo` and `~/dotfiles/ai/ai-brain/foo` are the same file when stowed).
- Commit and push via the dotfiles repo's normal git workflow (**OpenPGP-sign** commits to the **dotfiles** git root — mandatory per **`brain-conventions.md`**).
- Re-run `./scripts/DotMate.sh stow_with_target ai/gemini-content-team .gemini` only when adding brand-new files or changing the stow structure.

Editing either path works; once the hook adapter ports, both literal and realpath matchers will treat them as equivalent.

## How the hooks **will** fit in (planned, not shipped)

Two hook adapters are scoped under `docs/runbooks/gemini-hooks-parity.md` to mirror the Cursor pack's `cursor-zone-writes.sh` and `safe-shell.sh` once `BeforeTool` matcher names are pinned to a Gemini CLI version:

- **Zone-write adapter** (`BeforeTool` with regex matchers on Gemini file-write tool names) — auto-approves writes inside the zones above. Counterpart of `ai/cursor-content-team/hooks/cursor-zone-writes.sh`.
- **Safe-shell adapter** (`BeforeTool` matched on shell / execute tool name(s) **if** distinct in Gemini) — auto-approves a narrow allowlist of read-only shell commands. Counterpart of `ai/cursor-content-team/hooks/safe-shell.sh`.

Both adapters are intended to be **grant-only** (`failClosed: false` posture) — only ever emit allow decisions for whitelisted operations; everything else passes through to the default Gemini approval flow.

Until they ship, this rule is **declarative** and there is **no programmatic auto-approval** in Gemini for these zones — the operator's manual approval discipline is the only gate.

## Summary

- **Policy intent (auto-accept once enforced):** writes under `$HOME/.gemini/docs/**`, `$HOME/.gemini/memory/**`, `$HOME/ai-brain/**`, `<workspace>/.gemini/**`, and their stow sources under `$HOME/dotfiles/ai/` (`gemini-content-team` + `ai-brain`).
- **Today (enforcement):** none — rely on Gemini default approval and source control until the `BeforeTool` adapter ships.
- **Brain skeleton no-write** (`_schema/`, `_templates/`, root `README.md`, `.gitignore`) **always** applies — even inside otherwise auto-accepted zones.
