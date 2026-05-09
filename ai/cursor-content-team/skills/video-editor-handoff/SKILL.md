---
name: video-editor-handoff
description: Structured handoff from content org to tech remotion-builder for programmatic video; Task payload, workspace_root, render mode, ffmpeg recipe id.
version: 1
---

# video-editor-handoff

Org skill — **`~/.cursor/skills/video-editor-handoff/`** after stow. Use before **`Task` → `remotion-builder`** from **`content-lead`**, **`cco`** (only when user explicitly authorizes tech dispatch in planning), or the **user**.

## When to use

- Approved plan phase names **`video-editor`**, **programmatic video**, **Remotion**, **Skia**, and/or **ffmpeg** deliverable.
- **`touches[]`** include encoded video under **`assets/video/`** or **`assets/<channel>/`** (e.g. Reels).

## Preconditions

1. **`workspace_root`** — content corpus git root.
2. **`content_id`** (`cf-*`) and target note path when tied to a corpus atom.
3. **`approved_plan_path`** — plan lists this phase (**`content-lead`** execution).
4. **Brief** — script/beats, brand refs, **`sme-visual-brief`**-style notes as needed.
5. **Output spec** — resolution, duration cap, **`assets/...`** basename convention.
6. **Render mode** — `ssr_headless_shell` (default) vs `experimental_csr` (explicit sign-off).
7. **Skia** — yes/no; entry path / **`LoadSkia()`** reference.
8. **ffmpeg** — **recipe id** or **`none`**.

## Task payload (minimal)

- `workspace_root`
- `content_id` (if applicable)
- `target_note_path`
- `approved_plan_path`
- `brief_markdown`
- `render_mode`
- `skia_enabled` (boolean)
- `ffmpeg_recipe_id` | `none`
- `output_paths_glob` or explicit file targets

## Dispatch

- **`Task`** target = **`remotion-builder`** (tech pack — **`~/.cursor/agents/remotion-builder.md`**).
- Payload must **name `remotion-builder` explicitly** for routing.

## Forbidden

- Project **`sme-*`** **must not** **`Task` `remotion-builder`**; they hand briefs to **`video-editor`** / **`content-lead`** / **user**.
- **Silent** inference from generic pipeline — no auto-dispatch without plan phase + preconditions.

## After `remotion-builder` returns

- Confirm **`assets/`** outputs; update atom body / registry per corpus **`content-foundry-validate`** when applicable.
- **Static raster** (heroes/cards) remains **`chief-visual-officer`** + **`chief-visual-handoff`** — separate from encoded video.

## Model

**`remotion-builder`** uses org **`inherit`** / policy pin; do not retarget without user approval.
