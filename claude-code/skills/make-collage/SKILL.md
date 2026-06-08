---
name: make-collage
description: |
  Build a "design board" style collage out of a batch of photos the user
  just sent: cuts each object out as a transparent PNG, picks a
  background colour from the room photo, then spawns 10 parallel agents
  that each design a distinct collage variant using Python + PIL. Sends
  back a thumbnail grid so the user picks the variant they like, then
  ships the full-resolution file.

  Use when user sends 2+ photos in a row and asks any of:
  "сделай коллаж", "собери коллаж", "сделай мудборд", "несколько
  вариантов коллажа", "10 вариантов", "сделай дизайн-борд",
  "make a collage", "build a moodboard", "design board",
  "несколько коллажей", "разные раскладки".

  Single-photo edits go to the `image-edit` skill, not here.
---

# make-collage

Pipeline:

1. **Triage the photos.** Sort each input file into one of three roles:
   - **scene** — a room/interior photo. Usually 1-2 of these. Used full
     size as a backdrop tile in the collage.
   - **subject** — a plant, pot, object, anything to be cut out. Will
     be made transparent and floated on the canvas.
   - **swatch** — a tiny image that is a solid colour (≤ 200×200, low
     variance). It is *not* a collage element — read its colour and
     use it as the background tone for the canvas.

   Decide by reading each file (Read tool) and by file size. If unsure,
   ask the user.

2. **Cut out every subject in parallel.** One Bash call per image, all
   in the same message:

   ```bash
   uv run ~/projects/dotfiles/claude-code/shared/skills/image-edit/cutout_rembg.py \
     --input /path/to/raw.jpg --output /tmp/coll_<slug>.png
   ```

   Scene photos and swatches are NOT cut out.

3. **Decide background colour.**
   - If the user provided a swatch image → use its centre pixel.
   - Else sample the dominant wall colour of the first scene photo with
     this snippet (warm wall, no furniture):
     ```python
     from PIL import Image
     im = Image.open(scene).convert("RGB")
     # average a small clean rectangle from the upper third
     band = [im.getpixel((x, y)) for y in range(100, 300, 10)
                                  for x in range(im.width//3, 2*im.width//3, 10)]
     bg = tuple(sum(c[i] for c in band)//len(band) for i in range(3))
     ```
   - Tell the user the chosen colour in one sentence before generating.

4. **Spawn 10 parallel agents** — one Agent call per variant, all in a
   single message. Each agent is `general-purpose`, gets the full list
   of prepared assets + bg colour + its unique style brief from
   `styles.md`, and is told to write the result to a specific path
   like `/tmp/coll_v01.png` … `/tmp/coll_v10.png`. Style briefs are
   numbered 1-10 in `styles.md` — never reorder, never make up extras.

   Each agent prompt MUST include, verbatim:
   - All prepared file paths with role labels (scene/subject).
   - Background colour as `(R, G, B)`.
   - Target canvas size: `1280 × 1140` (960 collage + 180 legend strip
     at the bottom).
   - The brief from `styles.md` for its variant number.
   - The output path it must write.
   - A reminder: "do not call any external API, generate the file with
     PIL/numpy only, do not ask follow-up questions, do not write
     anywhere besides the output path".

5. **Build the thumbnail grid.** Run `gallery.py` to assemble the 10
   variants into a single 5-column × 2-row contact sheet with labels
   1-10. Send THIS via `mcp__bot__send_image` with the caption asking
   the user which number she likes.

6. **On reply** (a number like "3" or "third"), send the full-resolution
   variant via `mcp__bot__send_document` (so Telegram doesn't compress
   it). If she asks for tweaks, hand the chosen file to the
   `image-edit` skill or edit inline.

## What each variant agent does

The agent writes ONE standalone Python script and runs it via uv. The
script:
- Creates a `1280 × 1140` canvas filled with the given bg colour.
- Places the scene photo(s) and cut-out subjects per its brief.
- Saves to its assigned `/tmp/coll_vNN.png`.

Agents are free to recolour, scale, rotate, add subtle shadows, soft
gradients — anything PIL can do. They must NOT call rembg / fal / any
network. Cutouts are already prepared. Numbered markers and a legend
strip are optional per brief — some variants skip them.

## Files in this skill

- `SKILL.md` — this file (workflow).
- `styles.md` — the 10 fixed style briefs. Edit briefs here, never
  inline in agent prompts.
- `compose.py` — small helpers (paste with anchor, find pot centre,
  sample colour, dim, recolour-by-hue). Agents `import` this if useful;
  rebuilding from scratch is also fine.
- `gallery.py` — builds the 5×2 thumbnail contact sheet.

## When the user wants the result

Default: send the contact sheet only, full files only after she picks.

If she says "пришли все десять" / "send them all" → send the chosen
variants via `send_document` in a batch. Files are PNG, ~1-2 MB each.

## Anti-patterns

- Don't generate fewer than 10 variants without asking. The skill's
  whole point is breadth — even if some are weaker, she sees options.
- Don't make all 10 minor tweaks of the same layout. The briefs in
  `styles.md` are deliberately distinct so variants feel different.
- Don't run the variants sequentially. Always parallel — 10 Agent
  calls in ONE message.
- Don't ask the user to confirm the bg colour before generating.
  Mention it once, then proceed. She'll tell you if it's wrong.
- Don't put the legend strip on variants whose brief says "no legend".
- Don't bake numbered markers in by default — only when the brief asks
  for them, or when the user explicitly requested them.

## Failure modes

- `cutout_rembg.py` fails on one image → tell the user which one, use
  the original photo as a non-transparent tile in that variant. Don't
  abort the whole batch.
- Agent times out / writes no file → re-spawn just that one with the
  same brief, in the background. The other 9 thumbnails go first.
- The thumbnail grid is too cramped (rare, only if ≥ 6 scenes) →
  switch `gallery.py` to 2 rows × 5 cols of larger thumbs and send as
  a document instead of an inline image.
