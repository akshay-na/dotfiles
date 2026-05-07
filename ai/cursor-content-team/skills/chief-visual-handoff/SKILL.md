---
name: chief-visual-handoff
description: Structured handoff to org singleton chief-visual-officer for corpus image generation; Task payload, workspace_root, paths.
version: 1
---

# chief-visual-handoff

Org skill — **`~/.cursor/skills/chief-visual-handoff/`** after stow. Use before **`Task`** to **`chief-visual-officer`** from **`cco`**, **`content-lead`**, org VPs, or project SMEs.

## When to use

- Approved plan or phase includes **`generate_image: true`**, **`assets/<channel>/`** in `touches[]`, or explicit **hero / carousel / thumb** deliverables.
- Project SMEs finished copy and need **raster** committed in the corpus.

## Preconditions

1. **`workspace_root`** is the **content corpus** git root (payload or user-confirmed).
2. Target note has **`content_id`** (`cf-*`) and **`channels`** per corpus schema.
3. Brief present: `image_prompt` and/or **`sme-visual-brief`** block (mood, palette, on-image text, negatives from **`_meta/brand-glossary.md`**).
4. **`assets/<channel>/`** exists or will be created; basename **`{content_id}-hero`** (or `-card-1` …).

## Task payload (minimal)

- `workspace_root`
- `content_id`, `channel`
- `target_note_path` (relative to `workspace_root`)
- `brief_markdown`
- `aspect_ratio` (e.g. `1.91:1`, `16:9`)
- `deliverables` — `hero` | `carousel:3` | `thumb`

## After CVO returns

- Confirm files under **`assets/`**; note **`asset_hero`** + **`image_alt`**, then **`make validate`** (or corpus validator) if the repo defines one.
- Project **`reviewer-editorial`** may run for visual QA when the repo has it.

## Model

**`chief-visual-officer`** is pinned to **`composer-2`**; do not retarget without user approval.
