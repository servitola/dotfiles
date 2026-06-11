# cutout — точный alpha-matte

Use for: транспарентный PNG, тонкие листья, иголки, волоски, стекло.
Backend: **local rembg** with `birefnet-general` model. Fully offline after
the first run downloads the ~300 MB ONNX model into `~/.u2net/`.

```bash
uv run ~/projects/dotfiles/claude-code/skills/image-edit/cutout_rembg.py \
  --input /path/to/input.jpg \
  --output /tmp/cutout.png
```

First run: ~5–10 min while uv installs deps and rembg downloads the model.
Subsequent runs: ~3–5 sec on M-series. Tell the user once "первый запуск
дольше — скачивается модель", then no further mention.

Result: PNG with alpha. Send via `mcp__bot__send_document` (NOT
`send_image` — Telegram compresses images to JPEG and kills transparency).

## Fallback

- `cutout_rembg.py` fails (very rare — disk full or onnxruntime bug)
  → fall back to **edit** pipeline with prompt "remove background,
  output the subject on pure white". Tell the user fallback was used.
