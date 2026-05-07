# n8n handoff (webhooks)

Payload tables and JSON Schemas should live next to the automation that owns them, for example:

- **`<content-brain>/integrations/n8n/webhook-contract.md`** and **`event-schemas/`**, or
- a workspace repo under **`.gemini/docs/integrations/n8n/`** when you version contracts with application code.

(`<content-brain>` = `~/ai-brain/projects/<project_name>/` per `rules/project-identity.md`.)

## Git

If contracts or brain files live in git, the wrapper may **`git pull`** before invoking **`cco`** / **`metrics-steward`** and commit after successful writes — same as `rules/repo-hygiene.md` (no dedicated kb-sync script).
