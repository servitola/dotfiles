#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10"]
# ///
"""Build a labelled grid collage from N images. See SKILL.md.

Use after running inpaint with --variants N to send one comparison
image to the user. Auto-layout: 1=1×1, 2=1×2, 3=1×3, 4=2×2.
Each tile is labelled "1", "2", … in the bottom-left corner.

  collage.py --inputs a.png b.png c.png --output grid.png
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

LAYOUTS = {1: (1, 1), 2: (1, 2), 3: (1, 3), 4: (2, 2)}


def _font(size):
    for name in ("/System/Library/Fonts/Helvetica.ttc",
                 "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"):
        if Path(name).exists():
            try: return ImageFont.truetype(name, size)
            except OSError: pass
    return ImageFont.load_default()


def _label(img, text, size):
    d = ImageDraw.Draw(img)
    f = _font(size)
    pad = size // 4
    tw = d.textlength(text, font=f)
    box = (pad, img.height - size - 2*pad, pad + tw + 2*pad, img.height - pad)
    d.rectangle(box, fill=(0, 0, 0, 200))
    d.text((pad*2, img.height - size - pad), text, font=f, fill=(255, 255, 255))


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--inputs", nargs="+", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--tile", type=int, default=512, help="max width/height per tile (px)")
    p.add_argument("--gap", type=int, default=8, help="gap between tiles (px)")
    a = p.parse_args()
    n = len(a.inputs)
    if n not in LAYOUTS: sys.exit(f"need 1-4 inputs, got {n}")
    for path in a.inputs:
        if not path.exists(): sys.exit(f"not found: {path}")
    rows, cols = LAYOUTS[n]
    tiles = []
    for path in a.inputs:
        with Image.open(path) as im:
            im = im.convert("RGB"); im.thumbnail((a.tile, a.tile))
            tiles.append(im.copy())
    tw, th = tiles[0].size
    W = cols * tw + (cols + 1) * a.gap
    H = rows * th + (rows + 1) * a.gap
    canvas = Image.new("RGB", (W, H), (24, 24, 24))
    for i, im in enumerate(tiles):
        r, c = divmod(i, cols)
        x = a.gap + c * (tw + a.gap); y = a.gap + r * (th + a.gap)
        canvas.paste(im, (x, y))
        labelled = canvas.crop((x, y, x + tw, y + th))
        _label(labelled, str(i + 1), max(20, th // 16))
        canvas.paste(labelled, (x, y))
    a.output.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(a.output)
    print(f"OK: {a.output} ({W}x{H}, {n} tiles)")


if __name__ == "__main__": main()
