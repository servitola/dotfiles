---
name: image-to-video
description: |
  Animate a single still image into a short video clip (image-to-video)
  via fal.ai — Kling, Hailuo, Wan. The professional way to bring an
  avatar, character, or photo to life: real motion (slurping, waving,
  blinking, hair/steam movement), not slid layers. Outputs MP4; can also
  produce a looping GIF.

  Use when user sends or references an image and asks any of: "оживи
  картинку", "оживи аватарку", "оживи фото", "сделай видео из картинки",
  "анимируй фото", "пусть двигается", "сделай чтобы он двигался",
  "сделай гифку из этой картинки", "сделай живую аватарку",
  "animate this image", "image to video", "make a video from this photo",
  "make it move", "bring this to life".

  Not for: editing/generating a still image (use image-edit), or finding
  an existing reaction GIF on the web (use gif-search).
---

# Image to Video

Turn one still image into a short animated clip. A generative video model
(Kling by default) takes the picture plus a motion description and produces
real frame-by-frame motion with the subject's identity preserved. This is
how professionals animate a finished illustration — not by translating
cropped layers in PIL, which reads as a wobbling sticker.

## When this skill, when image-edit

- The user has (or just generated) a still and wants it to **move** → here.
- The user wants to change, restyle, cut out, or create a still → image-edit.
- Common chain: generate the picture with **image-edit**, then animate it
  here. Two controllable steps beat one text-to-video roll.

## Workflow

1. **Get the source image path.** If the user just generated one, reuse that
   file. If they sent a photo, use its local path (Telegram delivers it to a
   file). Square framing suits avatars; keep the source aspect otherwise.

2. **Write a motion prompt** — describe what *moves*, in English (models are
   stronger on English). The scene already exists in the image, so don't
   re-describe it; name the action and keep it physically plausible for the
   subject. Apply the prompt patterns below.

3. **Run the default model (Kling 2.1 Standard).** Paid on every call — this
   skill has no free tier, so treat the first run as the real attempt and
   make the prompt count.

   ```bash
   uv run ~/.claude/skills/image-to-video/scripts/i2v_fal.py \
     --input /tmp/ramen_cat.png \
     --prompt "the cat lifts the chopsticks to its mouth, slurps the noodles, chews with puffed cheeks, blinks, ears twitch, steam rising" \
     --output /tmp/ramen_cat.mp4 \
     --duration 5
   ```

   Generation takes ~1-2 minutes. The script prints `OK: <path>`.

4. **Verify before sending.** Extract a mid frame with ffmpeg and look at it
   (`ffmpeg -v error -i out.mp4 -vf "select=eq(n\,30)" -vframes 1 /tmp/f.png`).
   Check the subject didn't morph. If it drifted, see *When a clip is wrong*.

5. **Send it.** MP4 auto-plays and loops inline in Telegram:
   `mcp__bot__send_animation(file_path=…)`. Send a real `.gif` file only if
   the user explicitly asks for a GIF — convert first (see *GIF output*) and
   send via `mcp__bot__send_document` so it isn't recompressed.

## Motion prompt patterns

The picture carries the look; the prompt carries the movement. Keep it to one
or two concrete actions — overloading causes drift.

- **Name the action, not the scene.** «the girl smiles and her hair sways in
  the wind, she blinks slowly» — not a full re-description of her outfit.
- **Anchor to the subject's body** so motion stays attached: «the cat's paws
  hold the bowl», «steam rises from the cup», «she waves her right hand».
- **Add ambient life** for richness: blinking, breathing, hair/cloth/steam
  drift, slight camera push-in. These read as «alive» cheaply.
- **One camera move max**: «slow zoom in» or «gentle pan», not both.
- The script's default `negative_prompt` already fights blur, morphing, and
  extra limbs — extend it via `--negative` if a specific artifact appears.

## Choosing a model

Default `fal-ai/kling-video/v2.1/standard/image-to-video` fits most requests.
For sharper results, less identity drift, or when the user asks for higher
quality / sharper output / fewer artifacts, switch to the Pro tier. For anime/stylized art,
Wan is often stronger. Pick the model id from
[models.md](references/models.md) — tiers, costs, per-model parameters, and
the text-to-video endpoints.

## GIF output

When the user wants an actual `.gif` (not the auto-looping MP4), convert with
ffmpeg palettegen for clean colors:

```bash
python3 ~/.claude/skills/image-to-video/scripts/to_gif.py \
  --input /tmp/out.mp4 --output /tmp/out.gif --fps 15 --width 480
```

GIFs are large and 256-color — keep width ≤480 and fps ≤15. Send the result
via `mcp__bot__send_document` to preserve quality.

## When a clip is wrong

Diagnose before re-rolling — a blind retry usually drifts the same way.

- **Identity morphed** (face/colors/outfit shifted mid-clip) → shorten the
  motion to one simple action, lower it to `--duration 5`, and upgrade to the
  Pro model. Complex motion over 10s is the main drift source.
- **Barely moves** → the prompt was too timid. Use stronger active verbs and,
  on Kling, raise `--cfg 0.7` so it follows the prompt harder.
- **Wrong motion entirely** → the model misread the subject. Name the body
  part doing the action explicitly («her right hand waves», not «she greets»).
- **Artifacts / flicker** → add the specific artifact to `--negative`, or try
  Hailuo (`fal-ai/minimax/hailuo-02/standard/image-to-video`) for smoother
  output.

## Cost discipline

Every call is paid and there's no free fallback, so spend it well: get the
prompt right the first time, verify the frame before sending, and don't
silently re-roll more than twice. If a request fans out to several variants
or the user keeps iterating past two tries, check in first — ask whether to
try a couple more variants — without ever naming dollar amounts. Costs are
operator concern; tell the user it runs "on the best model", never a price.

## Errors

- `FAL_KEY not set` → tell the user the video engine is unavailable and to
  ping servitola; don't pretend it worked.
- **HTTP 403 / "User is locked. Reason: Exhausted balance" → DO NOT trust
  this message.** fal returns this exact text in two unrelated cases:
  (a) the account is genuinely out of money, and (b) the **model endpoint
  you called is deprecated/renamed/unavailable** — and the balance is fine.
  The script now disambiguates automatically: on a 403 it checks the real
  balance via `https://rest.alpha.fal.ai/billing/user_balance` and exits
  with either `MODEL_UNAVAILABLE` (retry with the default Kling model —
  drop `--model` — or pick a current id from references/models.md) or
  `BALANCE_EXHAUSTED` (then ping servitola). **Always retry on the default
  Kling model before concluding the engine is dead.** A 403 on a niche
  model (e.g. `fal-ai/wan-i2v`) almost always means that endpoint, not the
  account.
- HTTP 402 (balance empty) → tell the user the video engine is temporarily
  unavailable and to ping servitola. Don't mention balances to the user.
- HTTP 422 (bad argument) → a model rejected a flag (often `cfg_scale` or
  `aspect_ratio` on non-Kling models). Drop that flag and retry; see the
  per-model parameter notes in [models.md](references/models.md).
- Any other failure → surface the actual stderr, don't claim success.
