# Brain Conventions

## Canonical Root

- Root: `~/.gemini/ai-brain/` (preferred when Cursor migration applied) or `~/ai-brain/` per legacy layout — follow local `README` / migration state in your environment.
- Integrated namespace (no top-level KB/memory split).
- Tracked skeleton: `_schema/`, `_templates/`, `README.md`, `.gitignore`.
- Local runtime content: `projects/`, `org/`, `session/`, `.meta/`, `Home.md`, `.obsidian/graph.json`.

## Operating Model

- **Memory lane (RAM-like):** short-lived orchestration context and quick recall.
- **Knowledge lane (HDD-like):** durable, canonical structural and decision knowledge.
- **Promotion path:** memory -> KB when reused/stable/high-signal.

## Query and Token Discipline

- Lookup-first, body-later.
- Escalate query depth only when needed.
- Prefer compact summaries and reference pointers.
- Avoid duplicate payload transfer between subagents and orchestrators.

## Writer Policy

- C-suite agents (`cto`, `vp-onboarding`, `vp-architecture`, `vp-engineering`, `ciso`, `sre-lead`, `staff-engineer`, `vp-platform`, `atlassian-pm`) and `tech-lead` may perform bounded touch-writes to memory and KB. **Content org entrypoints** **`cco`**, **`content-lead`**, and **`metrics-steward`** (within analytics policy) may perform bounded touch-writes under **`~/ai-brain/projects/<project_name>/`** and **`<content-brain>`** per **`rules/brain-paths.md`** and **`skills/project-identity`** — **not** skeleton paths. **Not** to the vault skeleton paths in **Vault skeleton (tracked stow — no agent writes)** below.
- Excluded from KB/memory writes for dedup control: `code-reviewer`, `senior-dev`, `cro`.
- All other agents are read/query only for brain (`~/ai-brain/`) and must not write memory or KB.
- Project agents (`dev-*`, `sme-*`, `qa-*`, `reviewer-*`, `devops`) are read/query only.

### Vault skeleton (tracked stow — no agent writes)

**Hard rule:** no agent writes to the **ai-brain skeleton** shipped from dotfiles. Canonical source tree (edit only by humans / dotfiles maintainers, not automation):

- `dotfiles/ai/ai-brain/_schema/**`
- `dotfiles/ai/ai-brain/_templates/**`
- `dotfiles/ai/ai-brain/README.md`, `dotfiles/ai/ai-brain/.gitignore`

After stow, equivalent runtime paths include `~/ai-brain/_schema/**`, `~/ai-brain/_templates/**`, and the root `README.md` / `.gitignore` there; if `~/.gemini/ai-brain/` mirrors or symlinks the same skeleton, treat those paths the same — **no agent patches** to the skeleton content.

**Read-only for every agent** (including `cco`, `content-lead`, C-suite org roles, editorial specialists, subagents): do **not** create, delete, move, or patch skeleton paths during planning, corpus work, CCO plans, or KB/memory automation. **Query and cite** when needed; store durable content under `projects/`, `org/`, `session/`, etc.

**Exception:** the **human** explicitly requests dotfiles / schema-template maintenance, or a normal reviewed git change to `dotfiles/ai/ai-brain/`. Agents must **not** self-initiate skeleton edits.

## Private vault context (PII vs secrets)

**Assumption:** **`~/ai-brain`** and the **content corpus** (`<project>`) are **private** or **local-only** — not world-readable.

- **PII allowed** when it helps the workflow: **name**, **address**, **email**, **phone**, public **handles** tied to the operator, employer / **role**, and similar fields the user **explicitly** shares or approves (e.g. signatures, bylines).
- **Strictly forbidden:** **passwords**, **passphrases**, **API keys**, **tokens** (OAuth, access, refresh, session), **private keys**, **cookies**, **MFA seeds**, **payment** / full **bank** identifiers, **secret** env or config dumps. Use **`<REDACTED>`** or “**secrets manager**” — never raw values.
- **Do not** push brain or corpus PII into **public** surfaces or untrusted integrations without human review.
- Prefer reading **`org/global/operator-profile/`** before inferring stable prefs.

## Operator profile

- **Path:** **`~/ai-brain/org/global/operator-profile/`** (same brain root as **Canonical Root** above).
- **Layout:** **`_templates/operator-profile.md`** — agents **read** template, **write** only under **`operator-profile/`**.
- **Who may write:** org roles with brain **touch-write** per **Writer Policy** (`cco` / `content-lead` coordinated updates when plans call for it; same bounded discipline as other `org/` writes).
- **Prompt analysis:** maintain **`prompt-signals.md`** / **`predicted-needs.md`** from **high-signal** prompts; tag **`inferred`** + date; **no** secrets; refresh conservatively.

## Git commits — signing

- **DotMate / dotfiles repository** (the **git root** of the DotMate checkout — **`ai/cursor-tech-team/rules/brain-conventions.mdc`** when stowed to Cursor): **OpenPGP-sign every commit**; **never** **`--no-gpg-sign`** on that repository.
- **Content corpus**, **`~/ai-brain`**, and **other** agent/automation commits under this pack: **`git commit --no-gpg-sign`** or **`git -c commit.gpgsign=false commit`**, unless a **project ADR** overrides.

## Commit message format (`~/.gitmessage` + Conventional Commits)

Use **`$HOME/.gitmessage`** (DotMate: `dotfiles/git/.gitmessage` when stowed). Prefer **`git commit --no-gpg-sign -t "$HOME/.gitmessage"`** or **`--file`** per [**`content-git-workflow`**](../skills/content-git-workflow/SKILL.md) for **corpus/brain**; **dotfiles** uses **signed** commits per **Signing** above.

1. **Subject:** **`type[(optional-scope)]: imperative summary`** — Conventional Commits (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `perf`, `style`, …). **≤ ~72 characters** total; **no trailing period**; imperative mood.
2. **Content corpus lifecycle `type` (this pack / vault repos):** when the commit is **mainly** about atoms at a **stage**, prefer **`draft`**, **`staging`**, or **`published`** as **`type`** (parallel to `draft/` / `staging/` / `published/` paths), e.g. `draft: add LinkedIn hook cf-2026-0001`, `staging: tighten CTA after review`, `published: promote cf-2026-0003`. Optional **`(scope)`** may hold channel or `cf-*`, e.g. `draft(linkedin): …`. Use standard types (`chore`, `fix`, `docs`, …) for **repo-only** work (indexes, `_meta`, tooling) that is not stage-dominant.
3. **Body: concise** — match template sections; **at most 2–3** bullets if needed; **`Context:`** / **`Impact:`** **one short line each** by default; avoid essays (detail belongs in PR or plan docs).
4. **`Notes:`** — optional **brief** operational refs (e.g. `Task-ID`, ticket keys) only.
5. **Attribution — forbidden in commit messages:** **`Co-authored-by:`** for AI/IDE/bots, **`AI-authored`**, **`Generated-by:`**, “written by AI”, or vendor tool credit — **do not** add these.

## Entrypoint + decision agents — KB duty (gradual, mandatory)

Applies to **Gemini** content entrypoints and org decision agents. **Goal:** grow **`<content-brain>`** = **`~/ai-brain/projects/<project_name>/`** and **`org/`** **incrementally**. Use **`brain-memory-kb`**, **`project-identity`**, **`rules/brain-paths.md`**.

- **Who (writes):** **`cco`**, **`content-lead`**, **`metrics-steward`** (within scope), plus org roles allowed **touch-writes** above when executing routed work. **Who (handoff only):** personas that must not touch brain FS — emit structured handoffs for **`cco`** / **`content-lead`** to persist.
- **Per project:** Resolve **`project_name`** / **`<content-brain>`** for **every** workspace / payload root in scope — **no** collapsing multiple corpora into one node.
- **Start:** **`brain-memory-kb`** lookup on **`projects/<project_name>/`**, **`session/`**, **`org/`** before **`cco`** planning or **`content-lead`** execution.
- **Gradual persistence:** At **each** DAG phase boundary, critic pass, or automation checkpoint: **≥ 1** bounded write ( **`~/.gemini/memory/`** mirror + promote to **`<content-brain>`** or **`~/ai-brain/org/`** per policy). Default **≤ 3** new/changed durable paths per checkpoint unless the plan enumerates brain **`touches[]`**. **Dedupe** existing KB nodes.
- **Git-backed `~/ai-brain`:** **`pull --rebase` before first brain write** when **`~/ai-brain`** is a git repo (§ below); after material writes: scoped **`add` / `commit` / `push`** per **Signing** — keep **origin** (e.g. GitHub) **in sync** when configured.
- **Fail-closed:** Do not finish a run that produced **new** durable facts without persistence or explicit **`degraded`** in **`session/`** / reports.

## `~/ai-brain` as a git repository (optional)

**Two intentional layouts:** (a) **`~/ai-brain`** is a **git clone** (personal / sync to GitHub); (b) **no** `.git` under `~/ai-brain` — vault **local-only** (office laptop). **Do not** `git init` brain on local-only machines. If your only git root for the vault is **`~/.gemini/ai-brain`**, substitute that path for **`$HOME/ai-brain`** in **`-C`** below.

1. **Detect:** `git -C "$HOME/ai-brain" rev-parse --git-dir` succeeds and work tree is **`$HOME/ai-brain`**. If **not**, **skip** pull / commit / push for brain — do nothing.

2. **If** it **is** a repo and there are **staged-worthy changes** (allowed paths only; **never** skeleton paths):
   - **`git -C "$HOME/ai-brain" pull --rebase`** first. On conflict: **stop**, surface error, human resolves.
   - **`git add`** (path-scoped).
   - **`git commit --no-gpg-sign`** (message per **Commit message format** above).
   - **`git push`** (no **`--force`** to default branch without break-glass).

3. Clean tree after pull → **no** commit/push.

## Retention and Growth

- Do not auto-delete memory.
- Keep memory bounded via dedupe/supersede/archive and compact entries.
- Promote stable decisions/constraints/risks/principles into durable KB nodes.
