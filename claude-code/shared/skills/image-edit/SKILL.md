---
name: image-edit
description: |
  Edit, restyle, relight, cut out, or generate images. Three pipelines:
  cutout (transparent PNG), edit (place subject on a new background or
  relight a scene), generate (text-to-image from scratch). Optimized for
  plants, pots, interiors, product shots, but works on any photo.

  Use when user sends a photo and asks any of: "обработай фото",
  "отредактируй фото", "поправь картинку", "сделай картинку",
  "убери фон", "вырежи фон", "удали фон", "сделай прозрачный",
  "поставь на", "помести на", "смени фон", "другой фон",
  "другой свет", "перегенерь свет", "вписать в сцену",
  "переделай фото", "восстанови фото", "почисти фото",
  "сгенерируй картинку", "нарисуй картинку", "сделай иллюстрацию",
  "edit photo", "edit image", "process image", "remove background",
  "cutout", "transparent", "place on", "relight", "change background",
  "generate image", "make picture", "restyle".

  Also: when working in a Telegram topic whose CLAUDE.md says "any photo
  triggers image-edit", route every incoming image through this skill.
---

# image-edit

Three pipelines. Pick one, run the matching script, send the result back via
the bot MCP.

## Decide which pipeline

Read the user's request literally — do not improvise.

| User asks for | Pipeline | Primary script |
|---|---|---|
| Transparent PNG, just remove background | **cutout** | `cutout_rembg.py` |
| Place subject on a new background, change lighting, edit the scene | **edit** | `edit_hfspace.py` (or `edit_mflux.py` for best quality) |
| Generate a fresh image from scratch (no input photo) | **generate** | `generate_pollinations.py` |

Ambiguous request ("сделай красиво") → ask one short question:
"Прозрачный PNG или вписать в сцену? Если в сцену — опиши свет и фон."

## Pipelines

### cutout — точный alpha-matte

Use for: транспарентный PNG, тонкие листья, иголки, волоски, стекло.
Backend: **local rembg** with `birefnet-general` model. Fully offline after
the first run downloads the ~300 MB ONNX model into `~/.u2net/`.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/cutout_rembg.py \
  --input /path/to/input.jpg \
  --output /tmp/cutout.png
```

First run: ~5–10 min while uv installs deps and rembg downloads the model.
Subsequent runs: ~3–5 sec on M-series. Tell the user once "первый запуск
дольше — скачивается модель", then no further mention.

Result: PNG with alpha. Send via `mcp__bot__send_document` (NOT
`send_image` — Telegram compresses images to JPEG and kills transparency).

### edit — вписать в сцену + relight

Use for: «поставь горшок на полку при тёплом окне», «смени фон на белую
студию», «сделай вечерний свет».

Build the prompt in **English** even if the user wrote in Russian — these
models are stronger on English. Translate the user's intent, then enrich
with one lighting preset from `lighting_presets.md` if light was not
specified.

**Primary backend: HuggingFace Space (Qwen-Image-Edit-2511-Fast).** Free,
no auth, no key, no quota. Rate-limited shared GPU. Script tries 4 Spaces
in order (4-step → 8-step → full quality → official) so flakiness on any
single Space doesn't kill the request.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_hfspace.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

**Best-quality alternative: MFLUX local on Apple Silicon (FLUX.1 Kontext
[dev]).** Use this when the user wants top quality and is willing to wait.
Fully offline after one-time setup, zero quota. ~12 GB disk for 4-bit
model, ~6-15 sec per 1024 px image on M3-M4-M5.

One-time setup (do once on this machine):
1. `huggingface-cli login` (or set `HF_TOKEN`)
2. Visit https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev
   while logged in and accept the license.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_mflux.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

Send result via `mcp__bot__send_image`.

### generate — с нуля без фото

Use for: «нарисуй сцену для растения», экспериментальные мокапы. Backend:
Pollinations.ai FLUX, free, no key (text-to-image still works on the
public endpoint as of 2026; only the image-edit `kontext` model was
gated).

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/generate_pollinations.py \
  --prompt "Cozy bright living room with monstera plant on a wooden floor, soft morning light, photorealistic" \
  --output /tmp/gen.png
```

Send via `mcp__bot__send_image`.

## Saving the input photo

Telegram MCP delivers photos as files at known paths in the bot session.
When not obvious, ask the user for the path or copy from the latest file
in `/tmp/`. Never re-upload from URL — pass local path to the script.

## Lighting presets

If the user described a vibe but no specific light, pick from
`lighting_presets.md` and append the chosen preset string to the prompt
verbatim.

## Errors and fallbacks

- `cutout_rembg.py` fails (very rare — disk full or onnxruntime bug)
  → fall back to **edit** pipeline with prompt "remove background, output
  the subject on pure white". Tell the user fallback was used.
- `edit_hfspace.py` fails on all Spaces (queued/sleeping/down) → if
  `HF_TOKEN` is set and FLUX.1-Kontext-dev license accepted, fall back
  to `edit_mflux.py`. Otherwise tell the user the free Spaces are busy
  and offer mflux setup or a paid path.
- `edit_mflux.py` fails with HF auth error → tell the user the one-time
  setup steps from the script's docstring. Don't try to authenticate
  silently.
- Any script error: surface the actual stderr to the user, do not pretend
  it worked.

## Deprecated / paid backends (informational)

These scripts exist in the skill but are NOT in the default routing:

- `edit_gemini.py` — Gemini 2.5 Flash Image. Free tier is broken across
  the board (`limit: 0` even on paid Tier-1 due to a Google quota bug,
  ongoing since ~02.2026). Works only with paid Tier-2+ billing.
- `edit_pollinations.py` — Pollinations Kontext via authenticated API.
  Pollinations migrated to Pollen-credit (paid) model in 2026; free
  signup yields a `sk_*` key with **zero budget**. Don't use unless the
  user has paid Pollens.

If the user explicitly asks for a paid path, use these. Otherwise stick
with HF Space → MFLUX.

## When the user is unhappy with an `edit_mflux.py` result

If the user says the result is wrong (e.g. «не похоже на оригинал»,
«объект потерял лицо», «выглядит налеплено», «совсем не то»), do **not**
just retry with a tweaked prompt. First diagnose, then pick the right
fix.

`image_strength` semantics (verified against mflux 0.17.5+ behaviour —
same direction as SD img2img):
- **LOWER strength (0.1-0.4)** = less noise injected = MORE input
  preserved. Subject stays close to original.
- **HIGHER strength (0.6-0.9)** = more noise injected = MORE freedom
  to repaint. Subject can transform, lighting integrates better.
- Effective denoise steps ≈ `steps × (1 - strength)`. When you raise
  strength, raise `--steps` proportionally — high strength + few
  steps produces pure noise (we burned 13 minutes on this once).
  Aim for ≥6 effective steps.
- `image_strength=None` (default) is right for ~80 % of edits.

Failure modes and their fixes:

1. **Subject changed identity / lost recognizable features** (face
   morphed, pot reshaped, logo wrong) → re-run with `--image-strength
   0.2` to `0.4`. Lower strength keeps more of the original.
2. **Subject looks pasted / lighting doesn't match the new scene**
   (old shadows still visible, edges sharp against soft background)
   → re-run with `--image-strength 0.6` to `0.85` AND
   `--steps 16-20`. Higher strength lets the model integrate, more
   steps prevent the noise output.
3. **Output ignored the input entirely** (totally different scene,
   composition unrelated) → the prompt was a *concept change*, not
   an *edit instruction*. Kontext is not pure img2img;
   `image_strength` won't fix this. Two options:
   - reframe the prompt as concrete edits anchored to visible
     elements of the input ("the flame in the upper-right becomes
     the eye of the whirlwind"), then retry;
   - switch to the **generate** pipeline if the user actually
     wanted a fresh image and the input was just a vibe reference.
4. **Output is pure RGB noise** → the model didn't get enough
   denoising steps. Cause is almost always
   `--image-strength` set too high relative to `--steps`. Drop
   strength or raise steps so `steps × (1 - strength) ≥ 6`.
5. **Multi-line text replacement is garbled** (e.g. Cyrillic →
   Latin meme caption comes out as half-letters) → known FLUX
   weakness. Don't keep rerunning. Switch to the multi-step
   pattern: 1) Kontext to remove the original text ("erase the
   caption, fill with matching background"), 2) composite the
   new text via PIL with a real font file. See **Compose multiple
   steps** below.
6. **Two or three independent edits requested at once** (e.g.
   "remove text AND place in scene") and Kontext compromised on
   one → split into a chain. See **Compose multiple steps**.

Always tell the user which knob you turned and why ("снижаю
image_strength до 0.3 — горшок реформировался"), so they can build
intuition.

## Compose multiple steps when one pass is not enough

Some user requests don't fit a single pipeline — chain them and pass
the output of step N as the input of step N+1. Recognise these
patterns up front; do not start with one pass and hope for the best.

Common chains:

- **Clean a label, then place in scene.**
  Run 1: `edit_mflux.py` with prompt "remove all text/labels from
  the pot, keep everything else identical, plain ceramic surface".
  Run 2: `edit_mflux.py` on the cleaned output with the
  scene-placement prompt.
- **Cutout + relight on new background.**
  Run 1: `cutout_rembg.py` → transparent PNG.
  Run 2: `edit_mflux.py` with the cutout PNG as input and
  prompt "place this subject on …, lighting from …".
- **Replace meme caption (text) with a different language.**
  Run 1: `edit_mflux.py` "remove the caption text; fill the area
  with matching texture/background; keep illustration identical".
  Run 2: programmatic PIL composite — load the cleaned image, draw
  the new caption with a downloaded font (e.g. Impact, DejaVu
  Sans Bold) plus stroke. This is the only reliable path for
  multi-line text edits because diffusion text rendering breaks at
  >1 short line.
- **Restyle a portrait + new background.**
  If both transformations together degrade quality, do bg first,
  then portrait edit (or vice versa); compare both orders on a
  test sample.

When chaining, name the intermediate files clearly
(`/tmp/<task>_step1_clean.png`, `/tmp/<task>_step2_placed.png`) so
you can iterate on either step without redoing the other.

Tell the user up front you'll run N steps and why ("сначала уберу
надпись, потом поставлю на полку — это две генерации, ~12 минут").
Send only the final result via the bot; don't spam intermediate
files unless the user asks to see the chain.

## What this skill does NOT do

- Does not edit images locally with PIL/cv2 (beyond resize for upload) —
  quality would be worse than the rembg/Kontext pipelines.
- Does not call paid APIs (fal.ai, Replicate, Photoroom) without
  explicit user approval.
- Does not batch process more than one photo per invocation. Loop the
  user.
