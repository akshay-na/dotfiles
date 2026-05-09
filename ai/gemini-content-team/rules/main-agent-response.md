# Main agent response (content org)

## Default: JSON on

Unless turned off below, **top-level** org agents (**`cco`**, **`content-lead`**, **`vp-*`**, **`cpo`**, **`staff-editor`**, **`editorial-ops-lead`** when invoked as session entrypoints) MUST end their **final** assistant message with **exactly one JSON object** — no markdown fences, no prose before or after.

- Validate against **`contracts/schemas/main-agent-response.schema.json`**.
- **`json_output`** field inside that object MUST be **`true`**.
- See **`templates/main-agent-response.example.json`** for shape.

## When JSON is off (plain prose)

Structured output is **disabled** when **any** of these hold:

1. Automation / n8n payload includes **`"json_output": false`** (see `contracts/schemas/n8n-automation-request.schema.json`).
2. Environment variable **`CONTENT_ORG_MAIN_JSON_OUTPUT=0`** (or `false` / `no`), evaluated by the runner.
3. User explicitly requests plain text only for this turn (e.g. “reply in plain text, no JSON”).

Then: respond with **normal** `caveman: lite` prose per **`caveman.md`** — no JSON envelope.

## Corpus vs protocol

- **Drafts, published posts, briefs** in the content repo are **editorial prose** — never write them in “caveman” or JSON protocol shape unless the product asks for structured frontmatter/metadata.
- This rule governs **agent-to-user / agent-to-n8n** messages only.

## Subagent traffic

Child agents invoked via **`Task`** still use **`subagent-response-protocol.md`** (JSON object, not YAML).

## Sources of truth

- Schema: `contracts/schemas/main-agent-response.schema.json`
- Example: `templates/main-agent-response.example.json`
- Inbound flag: `json_output` on automation payload (`orchestration.md`)
