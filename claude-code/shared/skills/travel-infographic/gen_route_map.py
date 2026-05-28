#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["staticmap>=0.5.7", "pillow>=10"]
# ///
"""Static route map: stops + segments on light Carto base."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import load_data, resolve_coords
from _map import (
    fetch_base_map,
    fit_zoom_center,
    great_circle,
    latlon_to_world,
    straight_line,
    world_to_pixel,
)
from _theme import (
    SEGMENT_COLOR,
    SLATE,
    TEAL,
    TEXT,
    TEXT_DIM,
    fmt_hours,
    fmt_price_short,
)

WIDTH = 1200
HEIGHT = 800


def render(data: dict, out: Path) -> None:
    from PIL import Image, ImageDraw, ImageFont

    stops_xy = [resolve_coords(s) for s in data["stops"]]
    zoom, cwx, cwy = fit_zoom_center(stops_xy, WIDTH, HEIGHT, padding=120)
    base = fetch_base_map(WIDTH, HEIGHT, zoom, cwx, cwy)

    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)

    def project(lat: float, lon: float) -> tuple[float, float]:
        wx, wy = latlon_to_world(lat, lon, zoom)
        return world_to_pixel(wx, wy, cwx, cwy, WIDTH, HEIGHT)

    for seg in data["segments"]:
        a = stops_xy[seg["from_idx"]]
        b = stops_xy[seg["to_idx"]]
        mode = seg.get("mode", "flight")
        color = SEGMENT_COLOR.get(mode, SLATE)
        pts = great_circle(*a, *b, 80) if mode == "flight" else straight_line(*a, *b, 30)
        px = [project(la, lo) for la, lo in pts]
        for i in range(len(px) - 1):
            draw.line([px[i], px[i + 1]], fill=color + "FF", width=6 if mode == "flight" else 5)

    font = _try_font(20, bold=True)
    font_small = _try_font(14, bold=False)
    for i, (lat, lon) in enumerate(stops_xy):
        x, y = project(lat, lon)
        r = 12
        draw.ellipse([x - r - 2, y - r - 2, x + r + 2, y + r + 2], fill="#FFFFFFFF")
        draw.ellipse([x - r, y - r, x + r, y + r], fill=TEAL + "FF")
        draw.ellipse([x - 4, y - 4, x + 4, y + 4], fill="#FFFFFFFF")
        name = data["stops"][i]["name"]
        tw = draw.textlength(name, font=font)
        bx, by = x + 18, y - 14
        pad = 8
        draw.rounded_rectangle(
            [bx - pad, by - pad, bx + tw + pad, by + 24 + pad],
            radius=8,
            fill=(255, 255, 255, 235),
            outline=(0, 0, 0, 20),
            width=1,
        )
        draw.text((bx, by), name, fill=TEXT + "FF", font=font)

    summary = _summary_text(data)
    if summary:
        _draw_summary_card(draw, summary, font_small)

    out_img = Image.alpha_composite(base, overlay).convert("RGB")
    out_img.save(out, "PNG", optimize=True)


def _summary_text(data: dict) -> str:
    parts = []
    if "total_hours" in data:
        parts.append(f"Время: {fmt_hours(data['total_hours'])}")
    if "total_price_rub" in data:
        parts.append(f"Цена: {fmt_price_short(int(data['total_price_rub']))}")
    return "   ·   ".join(parts)


def _draw_summary_card(draw, text: str, font) -> None:
    pad = 14
    tw = draw.textlength(text, font=font)
    x = WIDTH - tw - pad * 2 - 24
    y = HEIGHT - 50
    draw.rounded_rectangle(
        [x, y, x + tw + pad * 2, y + 36],
        radius=10,
        fill=(255, 255, 255, 240),
        outline=(0, 0, 0, 25),
        width=1,
    )
    draw.text((x + pad, y + 8), text, fill=TEXT + "FF", font=font)


def _try_font(size: int, bold: bool):
    from PIL import ImageFont

    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Avenir.ttc",
    ]
    for c in candidates:
        try:
            return ImageFont.truetype(c, size)
        except OSError:
            continue
    return ImageFont.load_default()


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--data", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()
    render(load_data(args.data), Path(args.out))
    print(args.out)


if __name__ == "__main__":
    main()
