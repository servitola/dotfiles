---
name: image-edit
description: |
  Edit, restyle, relight, cut out, inpaint a region, or generate images.
  Pipelines: cutout (transparent PNG), edit (new background, relight,
  compose 2-3 references), inpaint (one masked region), generate
  (text-to-image). Works on any photo.

  Use when user sends a photo and asks: "обработай фото", "сделай
  картинку", "убери фон", "вырежи фон", "сделай прозрачный", "поставь на",
  "смени фон", "другой свет", "вписать в сцену", "сгенерируй картинку",
  "нарисуй картинку", "edit photo", "remove background", "cutout",
  "place on", "relight", "change background", "generate image", "restyle".

  In a Telegram topic whose CLAUDE.md routes photos here, process every
  incoming image through this skill.
---

# image-edit

Four pipelines: cutout, edit (single- or multi-reference), inpaint,
generate. Pick one, load that pipeline's reference, run the matching
script, send the result back via the bot MCP. Load the smallest set of
references that fits the task — one branch per request.

## Decide which pipeline

Read the user's request literally — do not improvise.

| User asks for | Pipeline | First attempt (free) | Paid upgrade (~$0.04-0.05) |
|---|---|---|---|
| Transparent PNG, just remove background | **cutout** | `cutout_rembg.py` (local) | — (already top quality) |
| Place subject on a new background, change lighting, edit the scene | **edit** | `edit_hfspace.py` | `edit_fal.py` |
| Combine elements from 2-4 images user already sent / generated | **edit (multi-ref)** | `edit_hfspace.py --ref …` | `edit_fal.py --ref …` |
| Change one region only, keep the rest pixel-identical | **inpaint** | `edit_inpaint.py` | `edit_fal_fill.py` |
| **Iterate on a previous result** — fix one detail without losing what works | **inpaint** (see *Iterate mode* below) | `edit_inpaint.py` | `edit_fal_fill.py` |
| **Remove a region that AI keeps redrawing** (after 2 failed inpaint attempts) | **texture fill** | `patch_fill.py` (PIL, free, deterministic) | — |
| Generate a fresh image from scratch (no input photo) | **generate** | `generate_pollinations.py` | `generate_fal.py` |

Then run the chosen branch:

- **cutout** → run the commands from [cutout.md](references/cutout.md)
  — rembg invocation, first-run model download, send-as-document rule.
- **edit / edit multi-ref** → follow [edit.md](references/edit.md)
  — prompt building, free → paid escalation, multi-reference
  composition, mflux local backend, image_strength troubleshooting.
- **inpaint / texture fill** → follow [inpaint.md](references/inpaint.md)
  — iterate workflow, bbox and mask building (auto_mask + make_mask),
  variants + collage, paid Fill upgrade, patch_fill fallback.
- **generate** → run the command from [generate.md](references/generate.md)
  — Pollinations FLUX invocation, paid FLUX Pro upgrade (`generate_fal.py`).

Request needs two or more transformations (clean a label then place in
scene, cutout then relight, replace a caption)? Chain pipelines —
follow the chain patterns in [common.md](references/common.md).

Ambiguous request ("сделай красиво") → ask one short question:
"Прозрачный PNG или вписать в сцену? Если в сцену — опиши свет и фон."

## Iterate mode — default when refining a previous generation

When the user replies to (or follows up on) an image you generated and
asks for a correction («тоньше рамка», «убери надпись», «зеркало
пошире», «не та зелень справа», «надпись другую», «без растений снизу»),
**default to inpaint, not whole-frame edit**. Whole-frame regenerates
everything and loses the parts she already liked — that's why the same
scene gets rerolled 15+ times in a topic.

The signal: she's iterating on the **last image you sent**, not asking
for a different scene. Cues:
- Reply quotes / references the previous bot image.
- Verbs like «поправь», «исправь», «только X», «без X», «другой/другая X»,
  «убери», «добавь», «тоньше», «толще», «выше», «ниже», «правее», «левее».
- She names specific elements visible in the previous image.

Run each correction following the iterate workflow in
[inpaint.md](references/inpaint.md) — read the previous output, pick
the region, mask, inpaint with variants.

Hard rule: do **not** call `edit_hfspace.py` / `edit_fal.py` on a
correction request that names a specific region. The drift on untouched
areas is exactly what frustrates the user.

## Free-first, paid on request

Default routing is **always free**. Run the free script, send the result
to the user, **then in the same reply offer a paid retry** if the result
has obvious quality issues (soft details, melted text, drifting faces,
prompts not followed) OR if the user expresses any dissatisfaction in
the next message.

When offering or running a paid retry, apply the offer protocol from
[common.md](references/common.md) — offer wording, the no-dollar-cost
rule, proactive-offer triggers, session opt-in, multi-call check-in.

## Saving the input photo

Telegram MCP delivers photos as files at known paths in the bot session.
When not obvious, ask the user for the path or copy from the latest file
in `/tmp/`. Never re-upload from URL — pass local path to the script.

## Lighting presets

If the user described a vibe but no specific light, pick from
`lighting_presets.md` and append the chosen preset string to the prompt
verbatim.

## Errors

Each pipeline reference carries its own fallback chain; paid-engine
(fal.ai) errors are in [common.md](references/common.md). Any script
error: surface the actual stderr to the user, do not pretend it worked.

## What this skill does NOT do

- Does not edit pixels locally with PIL/cv2 beyond (a) resize for upload
  and (b) rasterising a `--bbox` into an inpaint mask. Actual repaint
  always goes through rembg/Kontext/Fill pipelines — local PIL edits
  would look like Photoshop circa 2003.
- Does not call paid APIs on the first attempt. Free path runs first;
  paid fal.ai (~$0.04-0.05) only after the user accepts the upgrade
  offer or asks for higher quality directly.
- Does not call paid APIs other than fal.ai (Replicate, Photoroom,
  Gemini paid tier) without explicit user approval.
- Does not batch process more than one photo per invocation. Loop the
  user.
- Does not refuse multi-reference requests («собери из этих картинок»)
  with "no such tool" — that capability lives in
  `edit_hfspace.py --ref`. If you catch yourself about to say "у меня
  нет инструмента, который …", re-read the **Decide which pipeline**
  table first.
