---
name: video-editor-handoff
description: Structured handoff from content org to tech remotion-builder for programmatic video; Task payload, workspace_root, Remotion paths, composition id, output basename, aspect ratio, audio policy, handoff_schema_version 2 synthetic audio fields, ffmpeg recipe id.
version: 2
---

# video-editor-handoff

**`handoff_schema_version: 2`** — document this integer in every payload consumed by **`remotion-builder`** so Stage C can branch on **`audio.pipeline`**. Frontmatter **`version: 2`** is the skill package version; keep both aligned for operators.

Org skill — **`~/.cursor/skills/video-editor-handoff/`** after stow. Use before **`Task` → `remotion-builder`** from **`content-lead`**, **`cco`** (only when user explicitly authorizes tech dispatch in planning), or the **user**.

## Synthetic audio pipeline (`handoff_schema_version: 2`)

| Field | Type | Description |
|-------|------|-------------|
| **`audio.pipeline`** | `static` \| `kokoro_whisper_v1` | Default **`static`**: checked-in assets / library paths only. **`kokoro_whisper_v1`**: **`remotion-builder`** **`Task`s `kokoro-audio-builder`** before composition lock-in for **`staticFile`** stems. |
| **`audio.brief_path`** | string | Corpus-relative path to VO / audio brief (markdown or JSON). |
| **`audio.voice_id`** | string | Opaque voice id (no secrets). |
| **`audio.locale`** | string | BCP-47-ish locale tag for TTS/ASR. |
| **`audio.stem_output_dir`** | string | e.g. **`tools/audio-pipeline/out/<video_slug>/`** (repo-relative). |
| **`audio.alignment_format`** | `whisper_words_v1` | Alignment JSON shape: segments with **`words[]`** `{ word, start, end, probability? }`. |
| **`audio.format`** | object | `{ sample_rate, bit_depth, channels, lufs_target, true_peak_max_dbtp }` — loudness probes (**ebur128** / **loudnorm**) use **same field names**. Example: **`lufs_target: -14`**, **`true_peak_max_dbtp: -1.0`**. |
| **`audio.tonejs_mode`** | `off` \| `preview` \| `stem_prerender` | **`render` is forbidden** until headless Tone.js smoke passes per governance. |

When **`audio.pipeline`** is **`kokoro_whisper_v1`**, the payload **must** include **`audio_editor_artifact`** (pointer to **`audio-editor`** output **`video-editor`** incorporated).

## Orchestration

- Project **`sme-*`** **must not** **`Task` `audio-editor`**. Only **`user`**, **`cco`**, or **`content-lead`** dispatch **`audio-editor`** (see **`content-foundry-agent-boundaries.mdc`**).

## Migration: v1 → v2

- **v1:** implicit **`audio.pipeline: static`**; no structured synthetic VO fields.
- **v2:** explicit **`handoff_schema_version: 2`**; optional **`audio.pipeline`** (default **`static`**). Add **`audio.*`** block when using **Kokoro + Whisper**; **`remotion-builder`** validates **`handoff_schema_version`** before **`Task` `kokoro-audio-builder`**.

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

- `handoff_schema_version` — **`2`** for payloads using **`audio.pipeline`** / structured **`audio.*`**; omit or **`1`** only for legacy static-audio-only handoffs (treated as **`audio.pipeline: static`**).
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
- **`audio`** — **v1:** `required` \| `optional` + free-text notes (single scalar). **v2:** prefer an **object** with **`mux`** (`required` \| `optional` \| `silent`), **`notes`** (string), and synthetic fields **`pipeline`**, **`brief_path`**, **`voice_id`**, **`locale`**, **`stem_output_dir`**, **`alignment_format`**, **`format`**, **`tonejs_mode`** per table above (default **`pipeline: static`** when omitted).
- **`audio_editor_artifact`** — required when **`audio.pipeline`** is **`kokoro_whisper_v1`** (path or id to **`audio-editor`** package).
- `render_mode`
- `skia_enabled` (boolean)
- `ffmpeg_recipe_id` | `none`
- `output_paths_glob` or explicit file targets (final **`assets/...`** when applicable)

### Full example payload (`handoff_schema_version: 2`, synthetic VO)

```yaml
handoff_schema_version: 2
workspace_root: /path/to/content-foundry
content_id: cf-2026-0999
target_note_path: staging/video/example.md
approved_plan_path: .cursor/docs/plans/2026-05-10-example-remotion.md
brief_markdown: |
  60s explainer; VO + bed under narration.
video_slug: lab-audio-kokoro-smoke
remotion_src_dir: tools/remotion/src/videos/lab-audio-kokoro-smoke/
composition_id: lab-audio-kokoro-smoke
output_basename: lab-audio-kokoro-smoke
aspect_ratio: "16:9"
audio_editor_artifact: draft/video/audio-briefs/cf-2026-0999-audio.md
audio:
  mux: required
  notes: VO + bed under narration; Kokoro + Whisper alignment.
  pipeline: kokoro_whisper_v1
  brief_path: draft/video/scripts/cf-2026-0999-vo.md
  voice_id: "<PLACEHOLDER_VOICE>"
  locale: en-US
  stem_output_dir: tools/audio-pipeline/out/lab-audio-kokoro-smoke/
  alignment_format: whisper_words_v1
  format:
    sample_rate: 48000
    bit_depth: 16
    channels: mono
    lufs_target: -14
    true_peak_max_dbtp: -1.0
  tonejs_mode: off
render_mode: ssr_headless_shell
skia_enabled: false
ffmpeg_recipe_id: none
```

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
