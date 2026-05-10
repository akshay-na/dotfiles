---
name: video-editor-handoff
description: Structured handoff from content org to tech remotion-builder for programmatic video; Task payload, workspace_root, Remotion paths, composition id, output basename, aspect ratio, audio policy, ffmpeg recipe id.
version: 2
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
5. **Output spec** — resolution, duration cap, final **`assets/...`** or corpus-relative encode path, **and** Remotion CLI basename when rendering inside **`tools/remotion/out/`** during implementation.
6. **Render mode** — `ssr_headless_shell` (default) vs `experimental_csr` (explicit sign-off).
7. **Skia** — yes/no; entry path / **`LoadSkia()`** reference.
8. **ffmpeg** — **recipe id** or **`none`** (post-mux / transcode only; primary encode still via Remotion CLI unless plan says otherwise).

## Remotion naming linkage (content-foundry)

Under corpus **`tools/remotion/`**:

- **`video_slug`** — directory name under **`src/videos/<video_slug>/`**; must match Remotion **`Composition` `id`** and the default **`out/<basename>.mp4`** basename for stable n8n keys.
- **`remotion_src_dir`** — e.g. **`tools/remotion/src/videos/<video_slug>/`** (repo-relative from corpus root).
- **`composition_id`** — same string as **`video_slug`** unless a legacy exception is documented in the plan.
- **`output_basename`** — filename stem for **`tools/remotion/out/<output_basename>.mp4`** (no directory); promote to **`assets/...`** per plan after QA.
- **`aspect_ratio`** — **`16:9`** | **`9:16`** (Reels / vertical).
- **`audio`** — **`required`** | **`optional`** plus free-text notes (music vs VO, levels, loop vs one-shot, rights).

## Task payload (minimal)

- `workspace_root`
- `content_id` (if applicable; stable id for automation)
- `target_note_path`
- `approved_plan_path`
- `brief_markdown`
- `video_slug`
- `remotion_src_dir` (e.g. `tools/remotion/src/videos/<video_slug>/`)
- `composition_id` (typically identical to `video_slug`)
- `output_basename` (e.g. `cf-2026-0042-topic-slug` or `lab-topic-slug`)
- `aspect_ratio` (`16:9` | `9:16`)
- `audio` (`required` | `optional` + notes)
- `render_mode`
- `skia_enabled` (boolean)
- `ffmpeg_recipe_id` | `none`
- `output_paths_glob` or explicit file targets (final **`assets/...`** when applicable)

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
