---
name: image-edit
description: |
  Edit, restyle, relight, cut out, inpaint a region, or generate images.
  Four pipelines: cutout (transparent PNG), edit (place subject on a new
  background, relight, or compose 2-3 reference images), inpaint (repaint
  one masked region, keep the rest pixel-identical), generate
  (text-to-image from scratch). Optimized for plants, pots, interiors,
  product shots, but works on any photo.

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

Four pipelines: cutout, edit (single- or multi-reference), inpaint,
generate. Pick one, run the matching script, send the result back via
the bot MCP.

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
| Generate a fresh image from scratch (no input photo) | **generate** | `generate_pollinations.py` | — |

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

Workflow per iteration:
1. Read the previous output image (use the Read tool — you can see it).
2. Identify the region the user named. Look at the pixels and pick
   coordinates — the model is doing this visually, no extra service needed.
3. If the region is a clean rectangle → call `edit_inpaint.py --bbox …`
   directly. Otherwise build a proper mask with `make_mask.py` (next
   section), preview it, then inpaint.
4. Prompt should describe **only what fills the masked region**, in the
   style of the surrounding image. Don't re-describe the whole scene.

Hard rule: do **not** call `edit_hfspace.py` / `edit_fal.py` on a
correction request that names a specific region. The drift on untouched
areas is exactly what frustrates the user.

## Free-first, paid on request

Default routing is **always free**. Run the free script, send the result
to the user, **then in the same reply offer a paid retry** if the result
has obvious quality issues (soft details, melted text, drifting faces,
prompts not followed) OR if the user expresses any dissatisfaction in
the next message.

The offer is one short sentence, embedded in the result message —
not a separate question that blocks the conversation. **Never mention
the dollar cost to the user** — say «на платном движке», «в pro
качестве», «с лучшей моделью», not «$0.04». The cents-level math is
operator concern, not user concern.

> «Если хочется резче и чтобы кофемашина и бюст не плыли — могу
> переделать на платном движке. Сказать?»

Trigger phrases for offering an upgrade proactively:
- The free output drifted on identity (bust morphed, label garbled,
  fingers/faces wrong) — mention this in the offer.
- The user is iterating on the same image >2 times — quality ceiling
  of the free model is being hit.
- The user asked for «фотореалистично», «резко», «как с фотографии»,
  «детально», «pro», «studio».

Trigger phrases for upgrading immediately after user confirms:
- «да», «давай», «переделай», «хочу резче», «на платном»,
  «офигенный», «yes», «do it», «upgrade», «нанеси».

Do not state the cost in any reply, including the one after a paid
call. The script's stdout has the cost for operator logs; don't echo
it back to the user.

If the same user has already opted into paid in this topic this
session, default to paid for follow-up edits in the same conversation
without re-asking. Reset to free on the next session.

If a single user request fans out to 4+ paid calls (multi-variant
generation, chain of edits), check in before the third call without
naming dollars: «это будет ещё несколько правок на платном — ок?»

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

**Step 1 — free first (`edit_hfspace.py`).** HuggingFace Space
Qwen-Image-Edit-2511-Fast. No key, no quota. 8-step Fast inference, so
output is softer and identity sometimes drifts on cabinets / faces /
small text. Daily ZeroGPU budget is shared per IP.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_hfspace.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

**Step 2 — paid upgrade if needed (`edit_fal.py`).** fal.ai FLUX
Kontext Pro, ~$0.04 per image. Full-quality FLUX, 3-6 sec, no queue.
Dramatically better identity preservation. Use when the free output
disappointed the user or has obvious drift — see the **Free-first,
paid on request** section for when to offer this.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_fal.py \
  --input /path/to/input.jpg \
  --prompt "Place this potted plant on a polished oak shelf, soft window light from camera-left at golden hour, warm 3200K, photorealistic" \
  --output /tmp/edit.png
```

Requires `FAL_KEY` in env or in `~/.config/openai_key.sh`. If both are
missing, surface that to the user instead of silently failing.

#### Multi-reference: compose elements from several user images

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
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_hfspace.py \
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

### inpaint — переписать только указанный регион

Use for: «плотнее растение только в верхнем левом углу», «убери надпись
на этикетке, остальное оставь как есть», «замени экран на телефоне».
Anything where the user explicitly wants the rest of the image to stay
pixel-identical. Whole-frame edit pipelines drift on untouched areas —
inpaint doesn't.

**Step 1 — free first (`edit_inpaint.py`).** FLUX.1-Fill-dev HF Space.
White pixels in the mask are repainted; black pixels are preserved.
You can pass either a ready mask PNG or a rectangle:

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_inpaint.py \
  --input /tmp/source.jpg \
  --bbox 0,0,512,512 \
  --prompt "Dense monstera plant growing from the wall, lush leaves filling this corner, matching the warm interior lighting" \
  --variants 3 \
  --output /tmp/inpainted.png
```

`--variants N` (1-4) generates N alternatives **in parallel** with
different seeds. Outputs land at `/tmp/inpainted.png`,
`/tmp/inpainted-2.png`, `/tmp/inpainted-3.png`. Default 1.

**Always default to `--variants 3` on iterate mode** (correction of a
previous output). She picks the best from a grid — far better UX than
single shot and reroll.

After running, assemble a comparison collage with `collage.py` and
send that via `mcp__bot__send_image` (with a short caption like «вот
3 варианта — какой?»). Do not spam 3 separate messages.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/collage.py \
  --inputs /tmp/inpainted.png /tmp/inpainted-2.png /tmp/inpainted-3.png \
  --output /tmp/inpainted_grid.png
```

The collage labels tiles 1/2/3 so she can reply «второй» — you then
pick that file as the new working image.

**Step 2 — paid upgrade if needed (`edit_fal_fill.py`).** fal.ai FLUX
Fill Pro, ~$0.05 **per variant**. One API call with `num_images=N`,
no extra latency. Cleaner edge integration and sharper region content
than the free Space. Offer this when the free inpaint's repainted
region has visible seams or low detail.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/edit_fal_fill.py \
  --input /tmp/source.jpg \
  --mask /tmp/mask.png \
  --variants 3 \
  --prompt "..." \
  --output /tmp/paid.png
```

How to pick the bbox from a fuzzy user description like «верхний левый
угол»:
1. Read the input dimensions (e.g. `from PIL import Image; print(Image.open(p).size)`).
2. Map the area to coordinates: «верхний левый угол» ≈ top 40% height ×
   left 40% width; «нижняя треть» ≈ y = 2/3·H, h = 1/3·H; etc.
3. Pass as `--bbox x,y,w,h`. Round to integers.

For non-rectangular masks (curved selections, multiple regions) use
`make_mask.py` — see the next section. Don't hand-write PIL code per
request; the helper covers rect / ellipse / arch / ring with union,
subtract, and feathering.

The prompt should describe **only what fills the masked region**, in
the style of the surrounding image. Don't describe the unmasked parts
— they're frozen anyway.

Send result via `mcp__bot__send_image`.

#### Picking a mask: auto first, then refine

Two scripts, two stages. Most edits start with **auto_mask.py** — text
description goes through Florence-2 segmentation and you get a polygon
back. Then **make_mask.py** refines: grow, shrink, shift, or compose
with geometric primitives.

**Stage 1 — `auto_mask.py` (Florence-2 HF Space, free).** Hand it the
last image and a short English description. Returns a polygon mask;
caches to `/tmp/_last_mask.png`. Works great for things with clear
visual identity: "the cabinet", "the green plants framing the mirror",
"the dog", "the wooden floor". Struggles on small overlays (tiny neon
text, fine wires) — for those skip to make_mask.py.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/auto_mask.py \
  --like /tmp/prev.jpg \
  --describe "the green plants framing the mirror" \
  --output /tmp/mask.png \
  --preview /tmp/preview.png
```

Description style: short referring phrase, English, definite article
(`the X`). Avoid long compound clauses — Florence-2 was trained on
RefCOCO-style references. «the green frame around the arched mirror»
✓. «that lush vegetation that wraps around the mirror's top arch» ✗.

If it returns no region (`no region matched`): the model didn't latch
on. Either rephrase shorter, or skip to make_mask.py with primitives.

**Stage 2 — `make_mask.py` (local PIL, free, instant).** Two roles:

A) Compose masks from geometric primitives — `rect`, `ellipse`, `arch`
   (rectangle with semicircular top, exactly the mirror shape friend
   works with), `ring` (annulus). `--shape add:rect:…` unions, `--shape
   sub:arch:…` subtracts. Coords accept `%` suffix for percent of dim.

B) **Refine an existing mask** — `--from-mask /tmp/_last_mask.png` plus
   any of `--shift DX,DY`, `--grow N`, `--shrink N`, `--feather N`.
   This is the move when the user says «правее», «побольше», «поуже»
   after seeing a preview. Don't recompute from scratch — shift/grow
   the cached mask.

Recipes:

```bash
# Auto-mask the plants, then she said "толще" → grow last by 25 px
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/auto_mask.py \
  --like /tmp/prev.jpg --describe "the green plants framing the mirror" \
  --output /tmp/mask.png
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --from-mask /tmp/_last_mask.png --grow 25 \
  --output /tmp/mask.png --preview /tmp/preview.png

# Neon caption — Florence-2 won't see it, build by hand
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --output /tmp/mask.png --feather 4 \
  --shape rect:200,120,400,200

# Thin the gold frame: outer arch minus a slightly-smaller arch
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --output /tmp/mask.png --feather 3 \
  --shape arch:200,120,400,600 \
  --shape sub:arch:210,130,380,580

# After preview, she said "правее" → shift cached mask 40 px right
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --from-mask /tmp/_last_mask.png --shift 40,0 \
  --output /tmp/mask.png --preview /tmp/preview.png
```

Workflow rule: **always pass `--preview` and show it to the user before
spending a paid inpaint call.** Caption it «вот эту область перекрашу
— ок?». Five seconds of confirmation beats a wasted ~$0.15 call when
the polygon was off. Free inpaint can skip preview when confident.

Feather 3-6 px is right for most edits. Larger feather (8-12) when the
surrounding texture is busy (foliage, fabric) so the seam disappears
into noise. Feather 0 only when the edit is sharply geometric (e.g.
replacing a phone screen).

### When AI refuses to remove a region — texture fill via `patch_fill.py`

Sometimes diffusion models structurally refuse to obey «remove X»:
- «обрежь зеркало снизу» — FLUX Fill keeps drawing more mirror because
  the visible geometry implies continuation. Kontext often deletes the
  whole mirror instead. We've burned 7+ paid calls on this pattern.
- «убери предмет с тумбы» where the predicted background contains the
  object's prior. Fill regenerates a similar object.
- «короче / меньше / без нижней части» — *structural* edits that the
  model treats as texture continuation, not geometry change.

Symptom: after 2 inpaint attempts the unwanted thing is still there.
Stop retrying. Diffusion has hit a strong prior; more calls won't fix
it.

**Fall back to `patch_fill.py`** — content-aware fill by sampling
clean background texture from elsewhere in the same image. Pure PIL,
free, deterministic.

```bash
uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/patch_fill.py \
  --input /tmp/source.png \
  --output /tmp/out.png \
  --target 365,590,330,425 \
  --sample 780,820,90,190 \
  --feather 6
```

How to pick the `--sample` region:
1. Identify the texture you want repeated (clean wall, plain floor,
   open sky). It must be present elsewhere in the same photo —
   ideally a 50-200 px rectangle of pure that texture.
2. Verify it has no plants / fingers / text leaking in. Crop and look
   at the sample before piping into patch_fill — saves a re-run.
3. If the texture has subtle vertical variation (gradient toward
   floor, light fall-off), sample from the same y-range as the
   target so the gradient lines up.

Pair patch_fill with edge effects:
- If the removed region had a glowing border (LED mirror, neon sign,
  monitor bezel), redraw the new edge after fill — render a thin
  rectangle plus additive bloom (see `compose_text.py` for the
  multi-radius `ImageChops.add` pattern). One-off, ~10 lines of
  inline PIL.
- For sharp geometric edges (window frame, picture frame), use
  `make_mask.py` shapes to define the new outline, then draw it on
  top of the texture fill.

This was the right move for «обрежь зеркало снизу до уровня растений»
in the friend «Идеи» topic — `patch_fill.py` of dark wall + new
horizontal LED bar at the new bottom edge.

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

- `edit_hfspace.py` fails on all Spaces (queued / sleeping / ZeroGPU
  quota exhausted) → **offer the paid upgrade immediately** instead of
  trying mflux first: «бесплатные движки сейчас заняты, могу сделать на
  платном — давай?». No dollar amount. Mflux requires HF auth and a
  30+ sec wait, so it's a worse pivot. Only use mflux when the user
  said «no paid».
- `edit_inpaint.py` fails on all Spaces → same pattern: offer the paid
  `edit_fal_fill.py`. If the user says no, fall back to whole-frame
  `edit_hfspace.py` with a prompt that names the region explicitly
  («in the top-left corner, …; keep the rest unchanged»), and warn
  that untouched areas may drift.
- `edit_fal.py` / `edit_fal_fill.py` fail with «FAL_KEY not set» →
  surface that to the user clearly: «платный движок сейчас недоступен,
  могу только на бесплатном — качество будет ниже». Don't pretend the
  upgrade option exists when it doesn't.
- `edit_fal.py` / `edit_fal_fill.py` fail with HTTP 402 (balance
  empty) → tell the user «платный движок временно недоступен, пиши
  servitola — пока на бесплатном», then run the free script with
  the same flags. No mention of money or balances.
- `cutout_rembg.py` fails (very rare — disk full or onnxruntime bug)
  → fall back to **edit** pipeline with prompt "remove background,
  output the subject on pure white". Tell the user fallback was used.
- `edit_mflux.py` fails with HF auth error → tell the user the one-time
  setup steps from the script's docstring. Don't try to authenticate
  silently.
- Any script error: surface the actual stderr to the user, do not pretend
  it worked.

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
- **Compose from multiple user images, then localise a tweak.**
  Run 1: `edit_hfspace.py --input A --ref B --ref C` to combine the
  scenes into a single base. Run 2: `edit_inpaint.py` with a bbox on
  the area the user is still unhappy about. Preserves the composed
  frame and only repaints the problem region.
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
