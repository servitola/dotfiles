#!/usr/bin/env -S uv run --with Pillow
"""Build a 5x2 thumbnail contact sheet from 10 collage variants.

Usage:
    uv run gallery.py --inputs v01.png v02.png ... v10.png --output sheet.png
"""
from __future__ import annotations
import argparse
from PIL import Image, ImageDraw, ImageFont


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--inputs", nargs="+", required=True,
                   help="paths to variant images, in order 1..10")
    p.add_argument("--output", required=True)
    p.add_argument("--cols", type=int, default=5)
    p.add_argument("--tile-w", type=int, default=420)
    p.add_argument("--gap", type=int, default=18)
    p.add_argument("--bg", default="50,52,46")
    a = p.parse_args()

    bg = tuple(int(x) for x in a.bg.split(","))
    cols = a.cols
    rows = (len(a.inputs) + cols - 1) // cols

    # Load first to derive aspect ratio
    first = Image.open(a.inputs[0])
    tile_w = a.tile_w
    tile_h = int(tile_w * first.height / first.width)
    pad = a.gap
    label_h = 36

    W = cols * tile_w + (cols + 1) * pad
    H = rows * (tile_h + label_h) + (rows + 1) * pad
    sheet = Image.new("RGB", (W, H), bg)
    draw = ImageDraw.Draw(sheet)

    try:
        font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial Bold.ttf", 22)
    except OSError:
        font = ImageFont.load_default()

    for i, path in enumerate(a.inputs):
        r, c = divmod(i, cols)
        x = pad + c * (tile_w + pad)
        y = pad + r * (tile_h + label_h + pad)
        im = Image.open(path).convert("RGB").resize((tile_w, tile_h), Image.LANCZOS)
        sheet.paste(im, (x, y))
        # Number label below the tile
        label = str(i + 1)
        bbox = draw.textbbox((0, 0), label, font=font)
        tw = bbox[2] - bbox[0]
        lx = x + tile_w // 2 - tw // 2
        ly = y + tile_h + 4
        draw.text((lx, ly), label, fill=(240, 235, 220), font=font)

    sheet.save(a.output)
    print(f"OK: {a.output} ({W}x{H})")


if __name__ == "__main__":
    main()
