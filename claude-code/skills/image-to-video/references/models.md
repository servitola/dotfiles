# Video model catalog (fal.ai)

All run through `i2v_fal.py --model <id>`. Costs are rough per-clip estimates
for operator logs only — verify on the fal.ai dashboard, never quote to the
user. Pick the cheapest model that meets the quality bar, upgrade on request.

## Image-to-video

| Model id | Tier | Strength | ~Cost / 5s |
|---|---|---|---|
| `fal-ai/kling-video/v2.1/standard/image-to-video` | default | Best balance: natural motion, holds character identity | ~$0.25 |
| `fal-ai/kling-video/v2.1/pro/image-to-video` | premium | Sharper, less drift, better complex motion | ~$0.45 |
| `fal-ai/kling-video/v1.6/standard/image-to-video` | budget | Older Kling, still solid, cheaper | ~$0.18 |
| `fal-ai/minimax/hailuo-02/standard/image-to-video` | alt | Very smooth camera + body motion, expressive | ~$0.30 |
| `fal-ai/wan/v2.2-a14b/image-to-video` | alt | Strong on anime / stylized art (current Wan id) | ~$0.20 |
| `fal-ai/ltx-video-13b-distilled/image-to-video` | fast | Cheapest, fastest, lower fidelity — drafts | ~$0.05 |

Start with the default. Offer Pro when the standard clip drifts on identity,
hands, or faces, or when the user asks for sharper / higher-quality output
with fewer artifacts. Use LTX only for quick throwaway drafts.

## Parameters per model

- **Kling**: accepts `duration` ("5" or "10"), `negative_prompt`,
  `cfg_scale` (0.1-1.0, higher = follows prompt harder, default ~0.5),
  `aspect_ratio` ("1:1" | "16:9" | "9:16"). Omit `aspect_ratio` to keep the
  source framing.
- **Hailuo / Wan / LTX**: accept `duration` and `negative_prompt`; they
  ignore `cfg_scale`. Don't pass `--cfg` to them.

If a model rejects an argument with an HTTP 422, drop that flag and retry.

**Bare `fal-ai/wan-i2v` is dead** — it 403s with a misleading "Exhausted
balance" body even when the account is funded. Use the versioned id in the
table above, and if any model id 403s, fall back to the default Kling model
before assuming an account problem (the script auto-checks balance on 403).

## Text-to-video (no input image)

This skill's script is image-to-video. For pure text-to-video (generate a
clip from a prompt with no picture), use these endpoints with fal_client
directly — same response shape (`result["video"]["url"]`), drop `image_url`:

- `fal-ai/kling-video/v2.1/master/text-to-video` — top Kling quality
- `fal-ai/minimax/hailuo-02/standard/text-to-video` — smooth, cheap

Usually the better path is: generate a still with the `image-edit` skill
first (full control over composition), then animate it here. Two cheap,
controllable steps beat one expensive text-to-video roll.
