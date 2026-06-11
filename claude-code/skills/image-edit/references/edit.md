# edit — вписать в сцену + relight

Contents:
- [Prompt building](#prompt-building)
- [Step 1 — free first (edit_hfspace.py)](#step-1--free-first-edit_hfspacepy)
- [Step 2 — paid upgrade if needed (edit_fal.py)](#step-2--paid-upgrade-if-needed-edit_falpy)
- [Multi-reference: compose elements from several user images](#multi-reference-compose-elements-from-several-user-images)
- [Best-quality alternative: MFLUX local](#best-quality-alternative-mflux-local)
- [Errors and fallbacks](#errors-and-fallbacks)
- [Deprecated alternative backends (informational)](#deprecated-alternative-backends-informational)
- [When the user is unhappy with an edit_mflux.py result](#when-the-user-is-unhappy-with-an-edit_mfluxpy-result)

Use for: «поставь горшок на полку при тёплом окне», «смени фон на белую
студию», «сделай вечерний свет».

## Prompt building

Build the prompt in **English** even if the user wrote in Russian — these
models are stronger on English. Translate the user's intent, then enrich
with one lighting preset from `../lighting_presets.md` if light was not
specified.

## Step 1 — free first (`edit_hfspace.py`)

HuggingFace Space Qwen-Image-Edit-2511-Fast. No key, no quota. 8-step
Fast inference, so output is softer and identity sometimes drifts on
cabinets / faces / small text. Daily ZeroGPU budget is shared per IP.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/edit_hfspace.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

## Step 2 — paid upgrade if needed (`edit_fal.py`)

fal.ai FLUX Kontext Pro, ~$0.04 per image. Full-quality FLUX, 3-6 sec,
no queue. Dramatically better identity preservation. Use when the free
output disappointed the user or has obvious drift — apply the offer
protocol from [common.md](common.md) for when to offer this.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/edit_fal.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

Requires `FAL_KEY` in env or in `~/.config/openai_key.sh`. If both are
missing, surface that to the user instead of silently failing.

## Multi-reference: compose elements from several user images

When the user asks to combine pieces of multiple photos they sent or
previously generated ("возьми шкаф из исходника + зеркало из первого
варианта + добавь плотное растение"), **do not refuse with "у меня нет
такого инструмента"**. Pick the photo that should anchor composition,
geometry, and lighting as `--input`, pass the others via repeated
`--ref`, and write the prompt referring to each by index.

Free first via `edit_hfspace.py --ref` (Qwen-Image-Edit-2511 natively
accepts a list of images). Then offer paid upgrade to `edit_fal.py
--ref` (FLUX Kontext Pro multi, up to 4 input images total) if the
free composition under-used the references.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/edit_hfspace.py \
  --input /tmp/coffee-machine-source.jpg \
  --ref /tmp/variant-1-arch-mirror.jpg \
  --prompt "Keep the cabinet, marble countertop, and coffee machine from image 1 exactly. Replace the wall behind them with the arched mirror from image 2. Add a denser monstera plant growing from the wall in the top-left corner. Match lighting and perspective of image 1, photorealistic." \
  --output /tmp/composed.png
```

If the model under-uses a reference (e.g. the mirror from image 2 does
not show up in the result), be more prescriptive in the next attempt:
name the visual element from each image explicitly («the gold arched
frame from image 2, hanging on the wall between the two shelves»), and
avoid abstract verbs like «inspire by» or «using the style of». A
sharper prompt often fixes it on the free model — try that before
suggesting the paid retry.

## Best-quality alternative: MFLUX local

MFLUX local on Apple Silicon (FLUX.1 Kontext [dev]). Use this when the
user wants top quality and is willing to wait. Fully offline after
one-time setup, zero quota. ~12 GB disk for 4-bit model, ~6-15 sec per
1024 px image on M3-M4-M5.

One-time setup (do once on this machine):
1. `huggingface-cli login` (or set `HF_TOKEN`)
2. Visit https://huggingface.co/black-forest-labs/FLUX.1-Kontext-dev
   while logged in and accept the license.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/edit_mflux.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

Send result via `mcp__bot__send_image`.

## Errors and fallbacks

- `edit_hfspace.py` fails on all Spaces (queued / sleeping / ZeroGPU
  quota exhausted) → **offer the paid upgrade immediately** instead of
  trying mflux first: «бесплатные движки сейчас заняты, могу сделать на
  платном — давай?». No dollar amount. Mflux requires HF auth and a
  30+ sec wait, so it's a worse pivot. Only use mflux when the user
  said «no paid».
- `edit_mflux.py` fails with HF auth error → tell the user the one-time
  setup steps from the script's docstring. Don't try to authenticate
  silently.
- `edit_fal.py` failures (`FAL_KEY not set`, HTTP 402) → handle per
  the paid-engine error rules in [common.md](common.md).

## Deprecated alternative backends (informational)

These scripts exist in the skill but are NOT in the default routing —
fal.ai covers their use cases better:

- `edit_gemini.py` — Gemini 2.5 Flash Image. Free tier is broken across
  the board (`limit: 0` even on paid Tier-1 due to a Google quota bug,
  ongoing since ~02.2026). Works only with paid Tier-2+ billing.
- `edit_pollinations.py` — Pollinations Kontext via authenticated API.
  Pollinations migrated to Pollen-credit (paid) model in 2026; free
  signup yields a `sk_*` key with **zero budget**.

Use these only on explicit user request for a different aesthetic. By
default: fal.ai → free HF → mflux.

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
   steps** in [common.md](common.md).
6. **Two or three independent edits requested at once** (e.g.
   "remove text AND place in scene") and Kontext compromised on
   one → split into a chain. See **Compose multiple steps** in
   [common.md](common.md).

Always tell the user which knob you turned and why ("снижаю
image_strength до 0.3 — горшок реформировался"), so they can build
intuition.
