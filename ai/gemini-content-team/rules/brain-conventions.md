# Brain conventions — unified ai-brain (Gemini)

Aligned with Cursor `~/.cursor/rules/brain-conventions.mdc`. Gemini agents use the **same** vault layout and discipline.

## Canonical root

- Root: `~/ai-brain/`
- Integrated namespace (no top-level KB/memory split at the filesystem level).
- Tracked skeleton (dotfiles stow): `_schema/`, `_templates/`, `README.md`, `.gitignore`.
- Local runtime content: `projects/`, `org/`, `session/`, `.meta/`, `Home.md`, `.obsidian/graph.json`.

## Operating model

- **Memory lane (RAM-like):** short-lived orchestration context, session notes, quick recall under `session/` and compact org scratch that is safe to supersede.
- **Knowledge lane (HDD-like):** durable, canonical structural and decision knowledge under `org/` and `projects/<name>/`.
- **Promotion path:** memory → KB when reused, stable, or high-signal.

## Query and token discipline

- Lookup-first, body-later.
- Escalate query depth only when needed.
- Prefer compact summaries and reference pointers.
- Avoid duplicate payload transfer between subagents and orchestrators.

## Writer policy (cross-tool)

Same roles as Cursor, interpreted for Gemini:

- **Org-tier touch-write (bounded):** Cursor C-suite + `tech-lead` analogs; for Gemini **orchestration**, `cco` and **`metrics-steward`** may coordinate writes to `~/ai-brain/` only when the change matches org/process/metrics namespaces and does not violate dedup / touch-write quotas. Prefer the same path ownership as Cursor (`org/global`, `projects/<name>/`, etc.). **Never** under the vault skeleton paths listed in **Vault skeleton (tracked stow — no agent writes)** below.
- **Excluded from KB/memory writes (dedup):** treat `code-reviewer`, `senior-dev`, `cro` and **standalone** internal editorial personas the same way—**read/query only** for `~/ai-brain/` unless a single org entrypoint (`cco` outer run) delegates a scoped write documented in the run ledger.
- **Project agents** (`dev-*`, `sme-*`, `qa-*`, `reviewer-*`, `devops`): read/query only for `~/ai-brain/`.

Internal personas (`vp-editorial`, editors, `qa-content`, etc.) follow **`rules/orchestration.md`** for **`<content-brain>/`** paths (**`~/ai-brain/projects/<project_name>/`** per **`rules/project-identity.md`** — Cursor **`kb-identity`** parity). Ephemeral run state uses **`~/.gemini/memory/`** (`rules/memory.md`).

### Vault skeleton (tracked stow — no agent writes)

**Hard rule:** no Gemini agent writes to the **ai-brain skeleton** shipped from dotfiles. Canonical source tree (edit only by humans / dotfiles maintainers, not automation):

- `dotfiles/ai/ai-brain/_schema/**`
- `dotfiles/ai/ai-brain/_templates/**`
- `dotfiles/ai/ai-brain/README.md`, `dotfiles/ai/ai-brain/.gitignore`

After stow, those are the same files as `~/ai-brain/_schema/**`, `~/ai-brain/_templates/**`, and the root `README.md` / `.gitignore` under `~/ai-brain/` (when stowed from dotfiles).

**Read-only for every agent** (including `cco`, `metrics-steward`, all internal personas, and any orchestrated sub-step): do **not** create, delete, move, or patch skeleton paths during pipeline runs, METRICS_READ, BRIEF/DRAFT phases, or promotion to `~/ai-brain/`. **Query and cite** skeleton files when defining structure; put durable content under `projects/`, `org/`, `session/`, or **`<content-brain>/`** per **`rules/brain-paths.md`**.

**Exception:** the **human** explicitly requests dotfiles / schema-template maintenance, or a normal reviewed git change to `dotfiles/ai/ai-brain/`. Agents must **not** self-initiate skeleton edits.

## Private vault context (PII vs secrets)

**Assumption:** **`~/ai-brain`** and **private** editorial vaults are **not** world-readable.

- **PII allowed** for personalization when the user wants it stored: **name**, **address**, **email**, **phone**, role / employer, etc., when **explicitly** shared or approved.
- **Strictly forbidden:** **passwords**, **API keys**, **tokens**, **private keys**, **cookies**, **MFA seeds**, payment / full bank data, secret env dumps — **never** in brain, profile, or n8n payloads. Use redaction or external secret references only.
- **Do not** send brain PII to **public** destinations without human approval.
- Consult **`org/global/operator-profile/`** before guessing long-lived preferences.

## Operator profile

- **Path:** **`~/ai-brain/org/global/operator-profile/`**
- **Layout:** read **`~/ai-brain/_templates/operator-profile.md`**; writes **only** under **`operator-profile/`**.
- **Who may write:** **`cco`**, **`metrics-steward`**, and other roles already allowed **bounded** `~/ai-brain/` touch-writes — for **`operator-profile/`** only when updating personalization / prompt-signal notes; same **no-secrets** rule.
- **Prompt analysis:** dated **`inferred`** lines in **`prompt-signals.md`**; **`predicted-needs.md`** hypotheses with disclaimers; no credential guessing.

## Agent `git commit` (no GPG sign)

The human may have **`commit.gpgsign=true`** globally. **All commits from Gemini agents, wrappers, or automation** must **not** GPG-sign. Use **`git commit --no-gpg-sign`** or **`git -c commit.gpgsign=false commit`**. Applies to **`~/ai-brain`** sync (below), workspace repos, and any scripted commit.

## Commit message format (`~/.gitmessage` + Conventional Commits)

Aligned with Cursor **`brain-conventions.mdc`**. Use **`$HOME/.gitmessage`** when stowed (DotMate: `dotfiles/git/.gitmessage`). Prefer **`-t "$HOME/.gitmessage"`** or a **`--file`** body with the same **section order** (`Context:`, `Impact:`, `Notes:`).

1. **Subject:** **`type[(optional-scope)]: imperative summary`** — Conventional Commits (`feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `ci`, `perf`, `style`, …). **≤ ~72 characters**; **no trailing period**; imperative mood.
2. **Content corpus lifecycle `type` (this pack / editorial vaults):** when the commit is **mainly** about atoms at a **stage**, prefer **`draft`**, **`staging`**, or **`published`** as **`type`** (same idea as `draft/` / `staging/` / `published/` trees), e.g. `draft: add thread outline`, `staging: apply editor feedback`, `published: promote piece`. Optional **`(scope)`**: channel or id. Use **`chore`** / **`fix`** / **`docs`** for repo plumbing (indexes, `_meta`, automation) when stage is not the point.
3. **Body:** **short** — ≤ **2–3** bullets if needed; **`Context:`** / **`Impact:`** **one line each** by default; no long narratives.
4. **`Notes:`** — automation/session lines when **`repo-hygiene.md`** / wrappers require; keep caveats **brief**.

## `~/ai-brain` as a git repository (optional)

**Two intentional layouts:** (a) **`~/ai-brain`** is a **git clone** (e.g. personal → GitHub); (b) **no** `.git` — brain stays **on disk only** (office). **Never** create a repo there unless the human asked.

1. **Detect:** `git -C "$HOME/ai-brain" rev-parse --git-dir` succeeds and work tree is **`$HOME/ai-brain`**. If **not**, **do not** run pull/commit/push on brain.

2. **If** it **is** a repo and there are changes under allowed brain paths (not skeleton):
   - **`git -C "$HOME/ai-brain" pull --rebase`** **before** commit/push. On conflict: stop run, **`rules/orchestration.md`** failure path.
   - **`git add`** (scoped).
   - **`git commit --no-gpg-sign`** with a message matching **Commit message format** above.
   - **`git push`**.

3. Nothing to commit after pull → skip commit/push.

## Retention and growth

- Do not auto-delete memory.
- Keep memory bounded via dedupe, supersede, archive, and compact entries.
- Promote stable decisions, constraints, risks, and principles into durable KB nodes under `~/ai-brain/projects/<name>/` or `~/ai-brain/org/` as appropriate.
