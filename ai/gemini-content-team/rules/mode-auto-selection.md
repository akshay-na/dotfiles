# Mode auto-selection from user prompts

- **Respect agent defaults**: Never override explicit mode instructions in agent definitions (for example **`cco`** in plan mode). This rule only guides which mode to switch into when the current assistant has a choice.

- **Explicit agent invocation (hard gate — overrides heuristics below)**:
  - Triggers include the user **naming** an org or project agent and asking to **use**, **invoke**, **run**, **call**, **dispatch**, **open**, **with**, **via**, **`@...`**, or equivalent (e.g. “use cco”, “invoke content-lead”, “run chief-visual-officer”). User may say “Task” colloquially — treat as **dispatch**, but the **tool** you call is **Gemini’s agent delegation surface**, not Cursor’s **`Task`** tool.
  - **Delegation language (same gate):** also treat as invocation when the user uses **assign**, **delegate**, **hand off to**, **have … draft / implement / handle**, **get … to**, **let … take this**, **through the … agent**, **orchestrate with …**, **with … agent** — whenever an **agent id** from **`~/.gemini/agents/`** or **`<project>/.gemini/agents/*.md`** is clearly the **executor** (not merely mentioned as a topic).
  - **Dispatch primitive (Gemini CLI only):** real agent runs use the **Gemini CLI subagent delegation tool** registered for that agent when **`experimental.enableAgents`** is true (current upstream pattern: **one model-invokable tool per agent**; exact function name appears in the session tool list — pick the tool that targets that agent id / definition). **Cursor IDE’s `Task` tool does not exist here**; do not document or imagine cross-client tool names.
  - **Required:** the **first** substantive step is **that delegation tool call** for the named agent (match **`~/.gemini/agents/`**, **`<project>/.gemini/agents/`**, **`agent-orchestration.md`**). Payload = user goal, constraints, corpus paths, checkpoints, parent correlation ids per orchestration skills.
  - **Tool-order (strict):** **before** the first successful **dispatch** for that user intent, **do not** use file **write** / **patch** / **delete** tools or **shell** that **mutates** git state / vault files **for that intent**. **Allowed first:** read-only file reads / search solely to build the dispatch payload or verify the agent id exists.
  - **Orchestration driver:** if the user names **`cco`**, **`content-lead`**, **`editorial-cro`**, **`video-editor`**, **`chief-visual-officer`**, **`metrics-steward`**, or another **entrypoint** as owner of the work, **dispatch** **that** agent first with the full brief — **never** simulate CCO plans, pipeline phases, or corpus edits **in the parent turn** as a substitute.
  - **Zero-gap subagent chain (orchestrators and parents):** any artifact **owned** by agent **B** **must** come from a **completed dispatch** to **B** — **not** from the parent typing B’s section. **Forbidden gaps:** (a) “here is what **B** would produce” without a finished **dispatch to B**; (b) parent **drafts** B’s copy then skips delegation; (c) **split-brain** — partial tools + partial roleplay; (d) **double execution** — parent writes **`touches[]`** assigned to a child while a child dispatch covers the same paths. Between hops: **parse or fail** per **`subagent-response-protocol.md`** — **no** merge assuming child success if the envelope is missing, malformed after one reformat retry, or **`blocked`/`error`**. Next dispatch only after valid merge or explicit degraded stub per protocol.
  - **Forbidden:** answering **as** that agent in the parent session (CCO-style plans, pipeline narration, **or any other “styled” substitute**) **without** the **delegation tool call**.
  - **Forbidden:** clarifying questions **before** that **dispatch** unless the user message has **zero** actionable substance (then **at most one** minimal clarification).
  - **If delegation fails** (tool error, agent missing from registry, repeated envelope malformed): **stop** after one retry; **tell the user** dispatch failed; **do not** silently become the substitute for a **named entrypoint** — offer to retry or narrow the brief.
  - **Not an invocation:** generic editorial asks **without** naming an entrypoint — use **`agent-orchestration.md`** routing (often **`cco`** then **`content-lead`**), still via **dispatch** when the named entrypoint applies.
  - **Not an invocation:** user **asks about** an agent with **no** request that it **act** — answer in Ask mode; **no** delegation unless they ask to run it.

- **Content org entrypoints** (when the user does **not** name a specific agent):
  - Editorial / drafts / newsletter / channel / **brain + repo corpus** planning → **dispatch** **`cco`** for plans, then **`content-lead`** for execution after checkpoints — not in-chat roleplay of those roles.
  - Pure explanation of existing content → Ask mode.

- **Ask mode (explanation / reading)**:
  - Use Ask mode when the user is primarily asking for explanations, walkthroughs, or conceptual help (e.g. "explain", "what does this do?", "how does X work?") and is not requesting code changes.
  - Stay read-only: do not edit files or run commands unless the user then asks for changes.

- **Debug mode (errors, failures, broken behavior)**:
  - If the user pastes an error message, stack trace, test failure output, or clearly describes broken behavior ("this crashes", "tests are failing", "getting 500s"), switch to Debug mode.
  - Prioritize understanding and reproducing the issue first; propose or apply fixes only after identifying a likely root cause.

- **Agent (implementation) mode (changes, updates, implementation)**:
  - If the user mentions updating, implementing, adding, creating, refactoring, fixing, or otherwise changing code or configuration, use Agent mode for implementation work.
  - Treat phrases like "update this", "implement X", "add Y", "refactor", "fix this" as strong signals for Agent mode, even when the user provides existing code.

- **Plan mode (architecture, multi-step, or ambiguous scope)**:
  - For large, multi-step, or high-impact tasks (architecture, security, performance, observability, infra, migrations), or when the user explicitly asks for a plan or design, switch to Plan mode before implementation.
  - When users invoke org-level agents other than one-shots, assume plan mode as their default, in line with their agent definitions.

- **User intent and conflicts**:
  - If multiple signals appear (for example, an error message plus a request to redesign a feature), prefer Debug mode first to stabilize behavior, then Plan/Agent as appropriate.
  - If the user explicitly names a mode or asks not to switch modes, honor the user instruction over these heuristics, as long as it does not conflict with agent-specific mode requirements.
