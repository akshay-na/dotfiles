# Operator profile — layout under `~/ai-brain/org/global/operator-profile/`

**Purpose:** durable, **private** model of the human operator: who they are (as they choose to share), how they like to work, and **non-sensitive** signals from recent prompts so agents can pre-empt routine needs.

**Skeleton rule:** this file lives in **`_templates/`** (read-only for agents). Agents **create/edit** only files **under** `org/global/operator-profile/`, never patch this template.

## Suggested files

Create the directory if missing; keep files markdown or YAML with short sections.

| File | Content |
|------|---------|
| `README.md` | One paragraph: what this folder is, that it may contain PII, never secrets. |
| `identity.md` | **User-supplied or explicitly stated:** preferred name, pronouns, timezone, locale, city/region if given, email/phone **only if user asked to store** for drafting (e.g. signatures). |
| `preferences.md` | Working style: verbosity, caveman vs prose, tool prefs, default branch habits — from explicit user statements. |
| `prompt-signals.md` | **Inferred (dated bullets):** recurring goals, domains, pain points from **main prompts** — each line tagged `inferred`, optional `confidence: low|med|high`. Refresh conservatively; dedupe. |
| `predicted-needs.md` | Short **hypotheses** (“likely next ask: …”) with **date** and **disclaimer**; delete or supersede stale rows. |

## Hard bans (all files)

Do **not** record: passwords, API keys, OAuth/access/refresh tokens, private keys, session cookies, MFA seeds, full payment or bank identifiers, or paste **secret-bearing** env dumps. Use placeholders: `see 1Password`, `<REDACTED:API_KEY>`.

## PII

In **private** brain / foundry contexts, **PII is allowed** when the human wants it there — still minimize surface (only fields that help the workflow).

## Wikilink

From `Home.md` you may add: `[[org/global/operator-profile/README]]` (Obsidian path as your vault resolves it).
