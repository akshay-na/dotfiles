---
name: video-editor-handoff
description: Structured handoff to Cursor remotion-builder for programmatic video; payload contract; Gemini prepares briefs — execution in Cursor when remotion-builder is available.
version: 1
---

# video-editor-handoff

Org skill — **`~/.gemini/skills/video-editor-handoff/`** after stow. Use when preparing a **handoff** from **`content-lead`**, **`cco`** (explicit user-authorized tech dispatch), or the **user** toward **`remotion-builder`**.

## Execution note (Gemini vs Cursor)

- **`remotion-builder`** is the **Cursor tech-pack** executor (**`~/.cursor/agents/remotion-builder.md`** after DotMate stow). **Gemini CLI** sessions **prepare** this payload; the user (or automation) **runs `remotion-builder` in Cursor** unless a future ADR adds a Gemini-native executor.

## When to use

- Approved plan phase names **`video-editor`**, **programmatic video**, **Remotion**, **Skia**, and/or **ffmpeg** deliverable.
- **`touches[]`** include encoded video under **`assets/video/`** or **`assets/<channel>/`**.

## Preconditions

1. **`workspace_root`** — content corpus git root.
2. **`content_id`** (`cf-*`) and target note path when tied to a corpus atom.
3. **`approved_plan_path`** — under **`<project>/.gemini/docs/plans/`** or **`<project>/.cursor/docs/plans/`** per active tool; phase must list this work.
4. **Brief** — script/beats, brand refs.
5. **Output spec** — resolution, duration cap, **`assets/...`** paths.
6. **Render mode** — `ssr_headless_shell` (default) vs `experimental_csr` (explicit sign-off).
7. **Skia** — yes/no; **`LoadSkia()`** reference.
8. **ffmpeg** — **recipe id** or **`none`**.

## Task payload (minimal)

- `workspace_root`, `content_id`, `target_note_path`, `approved_plan_path`, `brief_markdown`, `render_mode`, `skia_enabled`, `ffmpeg_recipe_id`, `output_paths_glob`

## Target agent

- **`remotion-builder`** (Cursor). Payload must name **`remotion-builder`** explicitly for operators pasting into Cursor.

## Forbidden

- Project **`sme-*`** must not proxy **`Task` `remotion-builder`**.
- Silent auto-dispatch without plan phase + preconditions.

## After execution (Cursor)

- Confirm **`assets/`** outputs; corpus validation per project rules.

## Static raster

- **`chief-visual-officer`** + **`chief-visual-handoff`** — separate from encoded video.
