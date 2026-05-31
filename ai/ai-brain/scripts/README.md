# AI Brain batch scripts

Canonical location for vault maintenance and G2 audit tooling. Stows to **`~/ai-brain/scripts/`** when you apply any AI pack via DotMate (`stow_with_target`).

**Agents:** use these scripts for batch brain ops — do **not** reimplement migration, index rebuild, or policy materialization inline. Prefer **`make`** targets from the dotfiles repo when available.

## Paths

| Context | Script root |
|---------|-------------|
| After stow | `~/ai-brain/scripts/` |
| Dotfiles checkout | `dotfiles/ai/ai-brain/scripts/` |
| Make wrappers | `make <target>` from dotfiles repo root |

Set **`DOTFILES_DIR`** when running **`check-memory-demotion-contract.sh`** from a stowed vault without a sibling dotfiles tree.

## Scripts

| Script | Purpose |
|--------|---------|
| `materialize-brain-policy.sh` | Copy `memory-demotion.yml` into `~/ai-brain` (replace symlink). `--dry-run` (default) or `--apply`. |
| `check-memory-demotion-contract.sh` | Assert `contract_version` parity: policy source vs tech-pack stub vs runtime copy. |
| `migrate-brain-frontmatter.sh` | Migrate KB frontmatter (`lifecycle_state`, etc.). `--dry-run`, `--apply`, `--check-slug`. |
| `brain-rebuild-l1-index.sh` | Rebuild `projects/<slug>/_index.md`. |
| `brain-rebuild-session-index.sh` | Rebuild `session/<task-id>/memory.index.yaml` after demote. |
| `brain-sync-home.sh` | Regenerate `~/ai-brain/Home.md` from project scan. `--apply` to write. |
| `brain-quarantine-triage.sh` | List / triage quarantined nodes. |
| `brain-quarantine-apply.sh` | Apply quarantine moves per signed manifest. |
| `validate-brain-audit-join.sh` | G2 jq join on fixture and/or live `brain-audit-log.jsonl`. |
| `brain-audit-synthetic-episode.sh` | Append synthetic `kb_query` + `kb_demote` episode for G2 gate tests. |
| `brain-efficiency-audit-rollup.sh` | Append SLO proxy row to `brain-efficiency-audit.md`. |
| `brain-lib.sh` | Shared helpers — **source only**, not executed directly. |

## Make targets (dotfiles repo)

```bash
make check-brain-contract      # check-memory-demotion-contract.sh
make materialize-brain-policy  # dry-run materialize
make brain-migrate-dry-run     # migrate frontmatter dry-run (BRAIN_SLUG=...)
make brain-rebuild-l1          # rebuild L1 index
make brain-sync-home           # Home.md sync
make validate-brain-audit      # fixture join
make check-g2-ready            # live ledger join
make brain-audit-synthetic     # synthetic G2 episode
make brain-efficiency-rollup   # efficiency audit row
```

## Examples

```bash
# From stowed vault
~/ai-brain/scripts/materialize-brain-policy.sh --dry-run
~/ai-brain/scripts/brain-rebuild-session-index.sh cursor-abc123 dotfiles --apply

# From dotfiles repo
./ai/ai-brain/scripts/migrate-brain-frontmatter.sh --dry-run --slug dotfiles
make brain-sync-home
```

## Agent rules

- **Entrypoints** (`cto`, `tech-lead`, …): may invoke scripts for remediation phases in approved plans; log command + outcome in session ledger.
- **Handoff agents** (`code-reviewer`, `cro`): recommend script + args in `next_actions[]`; do not run destructive `--apply` without orchestrator checkpoint.
- **Never** patch `~/ai-brain/_schema/` or `_templates/` via scripts — skeleton is human/dotfiles-maintained only.

See **`brain-memory-kb`** skill (Cursor / OpenCode tech pack) and **`brain-conventions`** for query ladder and demotion policy.
