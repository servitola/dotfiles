#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10", "requests>=2"]
# ///
"""Text overlay with multi-layer neon bloom. --glow=R1,R2,R3; --stroke=N.
Downloads Caveat/Pacifico/MarckScript to ~/.cache/image-edit-fonts.
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
import requests
from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageFont

FONTS = {
    "caveat": "https://github.com/google/fonts/raw/main/ofl/caveat/Caveat%5Bwght%5D.ttf",
    "pacifico": "https://github.com/google/fonts/raw/main/ofl/pacifico/Pacifico-Regular.ttf",
    "marck": "https://github.com/google/fonts/raw/main/ofl/marckscript/MarckScript-Regular.ttf",
}
CACHE = Path.home() / ".cache" / "image-edit-fonts"

def _font(name, size):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / f"{name}.ttf"
    if not path.exists():
        url = FONTS.get(name) or sys.exit(f"unknown font: {name!r}")
        r = requests.get(url, timeout=20); r.raise_for_status(); path.write_bytes(r.content)
    return ImageFont.truetype(str(path), size)


def compose(input_path, output, text, xy, size, font_name, color, radii, glow_color, stroke):
    base = Image.open(input_path).convert("RGB")
    font = _font(font_name, size)
    probe = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    cx, cy = xy
    x, y = int(cx - probe.textlength(text, font=font) / 2), int(cy - size / 2)
    rgb_glow = glow_color[:3]
    for r in sorted(radii, reverse=True):
        if r <= 0: continue
        gl = Image.new("RGB", base.size, (0, 0, 0))
        ImageDraw.Draw(gl).text((x, y), text, font=font, fill=rgb_glow,
                                stroke_width=stroke, stroke_fill=rgb_glow)
        gl = gl.filter(ImageFilter.GaussianBlur(radius=r))
        base = ImageChops.add(base, gl)
    crisp = Image.new("RGBA", base.size, (0, 0, 0, 0))
    ImageDraw.Draw(crisp).text((x, y), text, font=font, fill=color,
                               stroke_width=stroke, stroke_fill=rgb_glow + (255,))
    output.parent.mkdir(parents=True, exist_ok=True)
    Image.alpha_composite(base.convert("RGBA"), crisp).convert("RGB").save(output)
    print(f"OK: {output}")


def _color(s):
    s = s.lstrip("#")
    if len(s) == 6: return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)
    if len(s) == 8: return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), int(s[6:8], 16))
    sys.exit(f"bad color {s!r}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--text", required=True)
    p.add_argument("--xy", required=True, help="text center CX,CY in pixels")
    p.add_argument("--size", type=int, default=64)
    p.add_argument("--font", default="caveat", choices=list(FONTS))
    p.add_argument("--color", default="#FFFFFF")
    p.add_argument("--glow", default="40,18,6")
    p.add_argument("--glow-color", default="#FFD089FF", dest="glow_color")
    p.add_argument("--stroke", type=int, default=0)
    a = p.parse_args()
    if not a.input.exists(): sys.exit(f"not found: {a.input}")
    cx, cy = (int(v) for v in a.xy.split(","))
    radii = [int(r) for r in a.glow.split(",") if r.strip()]
    compose(a.input, a.output, a.text, (cx, cy), a.size, a.font,
            _color(a.color), radii, _color(a.glow_color), a.stroke)


if __name__ == "__main__": main()
