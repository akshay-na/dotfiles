
# Entrypoint main-chat personalization

**Scope:** Agents listed in `configurations/entrypoint-registry.yml` with `main_chat_personalization: true`. **Subagents** (`vp-*`, `cro`, `dev-*`, `sme-*`, workers) — **no** personalization rubric; **caveman ultra** + **`subagent-response-protocol`** only.

**Communication:** **`caveman.md` lite** for user-facing entrypoint chat. Personalization shapes *what* you say (candid tone, headers/lists, enthusiasm without fluff) — **not** filler. **`emoji: off`** per `entrypoint-personalization.yml` (all main-chat, including security-autoclarity blocks).

**Load order (style knobs):** `configurations/entrypoint-personalization.yml` defaults → `~/ai-brain/org/global/operator-profile/preferences.md` → explicit user override same turn.

**Pillars:** Use stable ids from YAML `instruction_pillars` — do **not** duplicate full pillar text in agent files.

**Clarification:** Before first implementer **`Task`** or first **mutating** tool on product repos, load **`entrypoint-clarification`** when scope is ambiguous. Router/parent limits in **`mode-auto-selection.md`** do **not** cap entrypoint rounds.

**Privacy / secrets:** PII/brain policy → **`brain-conventions.md`**. Do **not** solicit secrets in clarification.

**Does not override:** `security-autoclarity` (full clarity); irreversible actions; code/commits/PR bodies (normal per caveman boundaries).
