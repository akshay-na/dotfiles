# Gemini CLI hooks + verification scripts

This directory holds two related (but distinct) classes of scripts:

## 1. Runtime Gemini CLI hook adapters

Scripts that speak the [Gemini hooks](https://geminicli.com/docs/hooks/) I/O contract: **stdin** is the hook JSON payload; **stdout** must be **only** valid JSON; **stderr** for logs. Wired via `~/.gemini/settings.json` (see `docs/runbooks/gemini-settings-merge.md`).

These do **not** assume Cursor `hooks.json` payload shapes — source traceability against `dotfiles/ai/cursor-content-team/hooks/*.sh` is a discovery exercise, not a copy.

| Script | Role |
|--------|------|
| `gemini-hook-json-pass-through.sh` | Validates / parses stdin JSON and echoes compact JSON; invalid → `{}`. Safe substrate for `SessionStart` / `SessionEnd` / no-op `BeforeTool` wiring. |

After changing hook definitions via `git pull`, expect Gemini's **untrusted hook** fingerprint flow — re-trust per `docs/runbooks/gemini-stow-and-trust.md`.

## 2. Verification scripts (Make-target tooling, not session hooks)

Scripts run from the repo root via `make verify-gemini-pack` (and individual targets) or directly. They are **not** wired into Gemini hook events; they live here because they verify the Gemini pack's contracts.

| Script | Role |
|--------|------|
| `verify-gemini-hooks.sh` | Asserts `gemini-hook-json-pass-through.sh` emits strict JSON on stdout (closes parity-plan **OR-02**). |
| `check-gemini-agent-frontmatter.sh` | Asserts every agent `.md` carries **only** `name` + `description` in YAML frontmatter (Gemini registry policy, parity-plan **P4**). |
| `verify-gemini-manifest.sh` | Cursor ↔ Gemini drift detector (parity-plan **OR-07**). Uses `manifest-pairs.txt` + `manifest-exclusions.txt` + `manifest-gemini-only.txt`. |
| `remind-content-pack-dual-edit.sh` | Lite manual reminder; full drift detection is in `verify-gemini-manifest.sh`. |
| `install-pre-commit.sh` | Optional opt-in: installs `verify-gemini-manifest.sh --staged` as the dotfiles repo's git `pre-commit` hook. |

### Manifest configuration

| File | Purpose |
|------|---------|
| `manifest-pairs.txt` | Declarative pair rules (cursor glob ↔ gemini glob). Documentation for humans; the script's transforms align with these rules. |
| `manifest-exclusions.txt` | **Cursor-only** paths intentionally without a Gemini twin (e.g. `hooks.json`, `mcp.json`, `cursor-zone-writes.sh`). Drift detector skips these. |
| `manifest-gemini-only.txt` | **Gemini-only** paths intentionally without a Cursor twin (`GEMINI.md`, `docs/**`, internal personas, etc.). |

When adding a new file to the Cursor pack with no Gemini equivalent, add the path to `manifest-exclusions.txt` **and** document the rationale in `docs/runbooks/cursor-only-exclusions.md`. Same for Gemini-only additions in `manifest-gemini-only.txt`.

### Make targets

```text
make verify-gemini-hooks      # JSON stdout test for adapter
make verify-gemini-frontmatter  # Agent registry frontmatter
make verify-gemini-manifest   # Drift between Cursor + Gemini packs (working tree vs HEAD)
make verify-gemini-pack       # All three above
```

### CI / pre-commit

For pre-commit (staged-only, fail-closed):

```bash
./ai/gemini-content-team/hooks/install-pre-commit.sh
```

For CI (compare to base branch):

```bash
./ai/gemini-content-team/hooks/verify-gemini-manifest.sh --against origin/main
```

### Stow note

This directory stows to `~/.gemini/hooks/`. Only the **runtime hook adapters** are intended to be invoked by Gemini at session time; the **verification scripts** are dev / CI tooling and are inert under Gemini's session lifecycle (Gemini only invokes scripts wired in `settings.json` `hooks`).
