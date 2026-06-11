# generate — с нуля без фото

Use for: «нарисуй сцену для растения», экспериментальные мокапы.

## Step 1 — free first (`generate_pollinations.py`)

Pollinations.ai FLUX, free, no key (text-to-image still works on the
public endpoint as of 2026; only the image-edit `kontext` model was
gated).

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/generate_pollinations.py \
  --prompt "Cozy bright living room with monstera plant on a wooden floor, soft morning light, photorealistic" \
  --output /tmp/gen.png
```

## Step 2 — paid upgrade if needed (`generate_fal.py`)

fal.ai FLUX Pro 1.1, ~$0.04 per variant. Sharper detail, better prompt
following, no free-tier queue. Use when the free output disappointed
the user (soft details, melted text, ignored prompt) — apply the offer
protocol from [common.md](common.md) for when to offer this.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/generate_fal.py \
  --prompt "Cozy bright living room with monstera plant on a wooden floor, soft morning light, photorealistic" \
  --output /tmp/gen.png \
  --variants 3 \
  --ratio landscape_4_3
```

- `--variants N` — 1-4 images per call (default 1); extra files land
  next to `--output` as `gen-1.png`, `gen-2.png`, …
- `--ratio` — fal `image_size` preset: `square_hd` (default),
  `portrait_4_3`, `landscape_4_3`, etc.

Requires `FAL_KEY` in env or in `~/.config/openai_key.sh`. `FAL_KEY
not set` / HTTP 402 → handle per the paid-engine error rules in
[common.md](common.md).

Send via `mcp__bot__send_image`.
