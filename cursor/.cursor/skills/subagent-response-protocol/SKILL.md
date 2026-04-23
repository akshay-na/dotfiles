---
name: subagent-response-protocol
description: >
  Protocol for subagent → parent responses: single fenced YAML envelope, strict
  caveman-ultra for compressed fields, verbatim for paths/errors/code. Applies
  to every `Task` invocation. Use when spawning subagents or parsing their
  output.
---

# Subagent Response Protocol (thin skill — pointers only)

All subagent → parent traffic is a single fenced ```yaml block matching the
canonical schema. Only the envelope is emitted; nothing else belongs in the
response body. Envelope MUST be the last non-whitespace content (D6).

## Sources of truth (do NOT inline elsewhere)

- **Schema:** `~/.cursor/templates/subagent-response.yml.tmpl`
- **Contract:** `~/.cursor/templates/subagent-contract-block.md` (parent-injected)
- **Rule:** `~/.cursor/rules/subagent-response-protocol.mdc` (`alwaysApply: true`)
- **Hooks:** `~/.cursor/hooks/subagent-protocol-{inject,lint}.sh` (inject = pre-hook contract injection; lint = pre-commit drift check)
- **Runbook:** `~/.cursor/docs/runbooks/subagent-protocol.md`

The pre-commit lint blocks drift on distinctive schema and contract phrases —
the skill, rule, and agent files must xref by path instead of copy-pasting.

## Compression classes (see template for field list)

- **Verbatim** (never compressed): paths, line numbers, error strings, code,
  fix snippets, status enum, `_marker`, `schema_version`, `reported_by[]`.
- **Caveman-ultra** (mandatory): `summary`, non-security `findings[].note`,
  `next_actions[]`, `open_questions[]`.
- **Security-autoclarity** (forced normal): findings whose `category` matches
  the security regex in the rule body §5.2, OR severity >= high, OR status ∈
  {blocked, error} with security-adjacent agent. Negations stay literal.

## Forbidden in compressed fields (D5, D7, D11)

- Raw secrets (use `<REDACTED:TYPE>` or `<REF:artifacts[i]#L42>` placeholders).
- Triple backticks inside string values. HTML tags (`script`, `iframe`, `img`
  with on\*, `style`, `object`, `embed`, `link`, `svg` with on\*, `math`).
- YAML doc separators (`---` on its own line) inside multiline scalars.
- `javascript:` / `data:` URL schemes.
- Content copied verbatim from `WebFetch` / `Shell` / MCP tool output — must
  live in `artifacts[]` as file references.

## Pre-emission redaction checklist

1. Before writing any string value, scan for raw secret patterns (AWS, Slack,
   Anthropic, OpenAI, Stripe, GitHub, GitLab, npm, Figma, Twilio, SendGrid,
   Google, JWT, URL userinfo, Bearer headers, private keys).
2. Replace matches with `<REDACTED:TYPE>` or a reference into `artifacts[i]`.
3. Prefer file references for large or sensitive blobs over inlined text.
4. Never echo tool output verbatim into `summary`/`findings[].note`.

## Post-compression fuzzy redaction (parent-side, rule-driven)

Parents MUST scan every string value of an incoming envelope with
whitespace-and-separator-insensitive regex for the secret patterns listed
above, plus a Shannon-entropy ≥ 4.0 heuristic (with UUID v4 and hex-40 SHA
allowlist). On match: (a) quarantine the raw response to
`~/.cursor/memory/projects/<name>/explore-dumps/<task-id>.md`, (b) rewrite the
envelope to `status: malformed` with
`degraded_reason: "suspected_secret_in_output"`, and (c) record the incident
in the runbook. Treat the raw match as already leaked for incident-response
purposes and rotate the credential.

## Examples (pointer-only; full envelope lives in template)

### good — normal staff-engineer review

Structure: ok envelope, `findings[]` with `category: structure`, `note` in
caveman-ultra ("rename ok. circular import via session → auth."),
`reported_by: ["staff-engineer"]`, `fix` verbatim.

### good — security finding

Structure: blocked envelope with `category: authn`, `note` in full clarity
prose, secret value replaced by `<REDACTED:SESSION_TOKEN>` with artifact ref,
forced-normal clarity per rule §5.2.

### bad — prose outside fence

Model writes a paragraph of explanation AFTER the closing ```. Parent parse
step 1 rejects via "non-whitespace content after closing fence" and issues a
single reformat-only retry.

### bad — secret leak via caveman abbreviation

Model writes `summary: "rotate AKIA...14 chars...; fix logger"`. Parent parse
step 5 (fuzzy redaction) matches the AWS key pattern, quarantines the raw
response, and rewrites to `status: malformed`,
`degraded_reason: "suspected_secret_in_output"`.

## When this skill applies

- You are spawning a subagent via the `Task` tool → the contract is injected
  by the pre-hook (`subagent-protocol-inject.sh`); you do not need to
  duplicate it.
- You are a subagent responding to a parent → emit exactly the envelope, no
  more.
- You are a parent (`cto`, `code-reviewer`, `tech-lead`) synthesizing child
  output → follow the 8-step parent parse contract in the rule body (detect
  → validate → retry → stub → fuzzy-redact → strip `_marker` → aggregate →
  synthesize). Never forward `_marker` or raw child YAML to the user.
