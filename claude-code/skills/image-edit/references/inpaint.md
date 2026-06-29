# inpaint — переписать только указанный регион

Contents:
- [When to use](#when-to-use)
- [Iterate workflow (refining a previous generation)](#iterate-workflow-refining-a-previous-generation)
- [Step 1 — free first (edit_inpaint.py)](#step-1--free-first-edit_inpaintpy)
- [Step 2 — paid upgrade if needed (edit_fal_fill.py)](#step-2--paid-upgrade-if-needed-edit_fal_fillpy)
- [Picking a bbox from a fuzzy description](#picking-a-bbox-from-a-fuzzy-description)
- [Picking a mask: auto first, then refine](#picking-a-mask-auto-first-then-refine)
- [When AI refuses to remove a region — texture fill via patch_fill.py](#when-ai-refuses-to-remove-a-region--texture-fill-via-patch_fillpy)
- [Errors and fallbacks](#errors-and-fallbacks)

## When to use

Use for: «плотнее растение только в верхнем левом углу», «убери надпись
на этикетке, остальное оставь как есть», «замени экран на телефоне».
Anything where the user explicitly wants the rest of the image to stay
pixel-identical. Whole-frame edit pipelines drift on untouched areas —
inpaint doesn't.

## Iterate workflow (refining a previous generation)

Workflow per iteration:
1. Read a **≤768 px preview** of the previous output to locate the region —
   `view.py --input prev.png --output /tmp/preview.png`, then Read the preview,
   not the full-res file. Placement is fully legible at that size and costs a
   fraction of the vision tokens (which you pay again every later turn).
2. Identify the region the user named. Look at the pixels and pick
   coordinates — the model is doing this visually, no extra service needed.
   Coordinates scale: a bbox read off a 768 px preview must be multiplied back
   to full-res before passing to `--bbox` (preview_scale = full_width / 768).
3. If the region is a clean rectangle → call `edit_inpaint.py --bbox …`
   directly. Otherwise build a proper mask with `make_mask.py` (see
   [Picking a mask](#picking-a-mask-auto-first-then-refine) below),
   preview it, then inpaint.
4. Prompt should describe **only what fills the masked region**, in the
   style of the surrounding image. Don't re-describe the whole scene.

## Step 1 — free first (`edit_inpaint.py`)

FLUX.1-Fill-dev HF Space. White pixels in the mask are repainted;
black pixels are preserved. You can pass either a ready mask PNG or a
rectangle:

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/edit_inpaint.py \
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
uv run ~/projects/dotfiles/claude-code/skills/image-edit/collage.py \
  --inputs /tmp/inpainted.png /tmp/inpainted-2.png /tmp/inpainted-3.png \
  --output /tmp/inpainted_grid.png
```

The collage labels tiles 1/2/3 so she can reply «второй» — you then
pick that file as the new working image.

## Step 2 — paid upgrade if needed (`edit_fal_fill.py`)

fal.ai FLUX Fill Pro, ~$0.05 **per variant**. One API call with
`num_images=N`, no extra latency. Cleaner edge integration and sharper
region content than the free Space. Offer this when the free inpaint's
repainted region has visible seams or low detail.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/edit_fal_fill.py \
  --input /tmp/source.jpg \
  --mask /tmp/mask.png \
  --variants 3 \
  --prompt "..." \
  --output /tmp/paid.png
```

## Picking a bbox from a fuzzy description

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

## Picking a mask: auto first, then refine

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
uv run ~/projects/dotfiles/claude-code/skills/image-edit/auto_mask.py \
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
   (rectangle with semicircular top — the classic arched-mirror shape),
   `ring` (annulus). `--shape add:rect:…` unions, `--shape
   sub:arch:…` subtracts. Coords accept `%` suffix for percent of dim.

B) **Refine an existing mask** — `--from-mask /tmp/_last_mask.png` plus
   any of `--shift DX,DY`, `--grow N`, `--shrink N`, `--feather N`.
   This is the move when the user says «правее», «побольше», «поуже»
   after seeing a preview. Don't recompute from scratch — shift/grow
   the cached mask.

Recipes:

```bash
# Auto-mask the plants, then she said "толще" → grow last by 25 px
uv run ~/projects/dotfiles/claude-code/skills/image-edit/auto_mask.py \
  --like /tmp/prev.jpg --describe "the green plants framing the mirror" \
  --output /tmp/mask.png
uv run ~/projects/dotfiles/claude-code/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --from-mask /tmp/_last_mask.png --grow 25 \
  --output /tmp/mask.png --preview /tmp/preview.png

# Neon caption — Florence-2 won't see it, build by hand
uv run ~/projects/dotfiles/claude-code/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --output /tmp/mask.png --feather 4 \
  --shape rect:200,120,400,200

# Thin the gold frame: outer arch minus a slightly-smaller arch
uv run ~/projects/dotfiles/claude-code/skills/image-edit/make_mask.py \
  --like /tmp/prev.jpg --output /tmp/mask.png --feather 3 \
  --shape arch:200,120,400,600 \
  --shape sub:arch:210,130,380,580

# After preview, she said "правее" → shift cached mask 40 px right
uv run ~/projects/dotfiles/claude-code/skills/image-edit/make_mask.py \
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

## When AI refuses to remove a region — texture fill via `patch_fill.py`

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
uv run ~/projects/dotfiles/claude-code/skills/image-edit/patch_fill.py \
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
in a friend's ideas topic — `patch_fill.py` of dark wall + new
horizontal LED bar at the new bottom edge.

## Errors and fallbacks

- `edit_inpaint.py` fails on all Spaces → offer the paid
  `edit_fal_fill.py`: «бесплатные движки сейчас заняты, могу сделать на
  платном — давай?». No dollar amount. If the user says no, fall back
  to whole-frame `edit_hfspace.py` with a prompt that names the region
  explicitly («in the top-left corner, …; keep the rest unchanged»),
  and warn that untouched areas may drift.
- `edit_fal_fill.py` failures (`FAL_KEY not set`, HTTP 402) → handle
  per the paid-engine error rules in [common.md](common.md).
