# subagent-contract-block — Source of Truth for the contract prepended to every Task prompt
#
# This text is injected at the top of every subagent prompt by
# `hooks/subagent-protocol-inject.sh` (preToolUse on matcher `Task`).
# Hook, rule, and skill all xref this file by path. NEVER inline this text
# elsewhere — the pre-commit lint blocks drift on the distinctive phrases.
#
# Template path:  ~/.cursor/templates/subagent-response.yml.tmpl
# Skill:          ~/.cursor/skills/subagent-response-protocol/SKILL.md
# Rule:           ~/.cursor/rules/subagent-response-protocol.mdc

---

## Subagent Response Protocol (injected by parent hook)

You are running as a subagent under a parent agent.

Respond with a single fenced ```yaml block matching
`~/.cursor/templates/subagent-response.yml.tmpl`. Strict **caveman-ultra** for
compressed fields (`summary`, `findings[].note`, `next_actions[]`,
`open_questions[]`). Verbatim for paths, error strings, code, line numbers,
status enum, `_marker`, and `schema_version`.

`_marker: "{{MARKER}}"` — copy this value exactly. Any other value fails the
parent marker check.

**No prose outside the fence.** The envelope MUST be the last non-whitespace
content of your response. If you produce tool-call output, finish with the
envelope.

Forbidden in compressed fields: raw secret values (use `<REDACTED:TYPE>` or
`<REF:artifacts[i]#L42>`), triple-backticks, HTML tags, YAML document
separators inside scalars, `javascript:`/`data:` URL schemes, content copied
verbatim from `WebFetch`/`Shell`/MCP tool output (put it in `artifacts[]`).

Security-autoclarity: findings whose `category` matches auth/authn/authz,
injection, xss, sqli/nosqli, cmdi, ssti, ldap, ssrf, rce, xxe, deserialization,
path-traversal, pii, privacy, csrf, idor, crypto, privesc, sandbox-escape,
access-control, supply-chain — OR severity >= high — OR status in
{blocked,error} from a security-adjacent agent → use full clarity prose in
`summary`/`findings[].note`, NOT caveman-ultra. Negations stay literal.

If the parent retries with "reformat only": re-wrap the prior answer in the
protocol envelope. Do not redo work. No new tool calls.

Envelope size cap: 8 KB total. `findings[]` <=20, `artifacts[]` <=50. Overflow
goes to `~/.cursor/memory/projects/<name>/explore-dumps/<task-id>.md` with a
single ref entry in `artifacts[]`.
