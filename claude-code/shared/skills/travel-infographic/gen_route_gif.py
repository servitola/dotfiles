#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "staticmap>=0.5.7",
#   "pillow>=10",
#   "imageio>=2.34",
#   "imageio-ffmpeg>=0.4",
# ]
# ///
"""Animated route: progressively draws each segment on Carto base map.

Outputs .mp4 (preferred — small + Telegram auto-plays via sendAnimation)
or .gif (universal fallback).
"""

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

WIDTH = 960
HEIGHT = 600
FPS = 18
FRAMES_PER_SEGMENT = 30
HOLD_FRAMES = 40


def render(data: dict, out: Path) -> None:
    from PIL import Image, ImageDraw

    stops_xy = [resolve_coords(s) for s in data["stops"]]
    zoom, cwx, cwy = fit_zoom_center(stops_xy, WIDTH, HEIGHT, padding=100)
    base = fetch_base_map(WIDTH, HEIGHT, zoom, cwx, cwy)

    font_label = _try_font(18, bold=True)
    font_summary = _try_font(20, bold=True)

    def project(lat: float, lon: float) -> tuple[float, float]:
        wx, wy = latlon_to_world(lat, lon, zoom)
        return world_to_pixel(wx, wy, cwx, cwy, WIDTH, HEIGHT)

    seg_paths = []
    for seg in data["segments"]:
        a = stops_xy[seg["from_idx"]]
        b = stops_xy[seg["to_idx"]]
        mode = seg.get("mode", "flight")
        pts = great_circle(*a, *b, 120) if mode == "flight" else straight_line(*a, *b, 60)
        px = [project(la, lo) for la, lo in pts]
        seg_paths.append((mode, px, seg))

    frames: list = []
    revealed_stops: set[int] = set()
    cumulative_layer = Image.new("RGBA", base.size, (0, 0, 0, 0))

    first_stop_idx = data["segments"][0]["from_idx"] if data["segments"] else 0
    revealed_stops.add(first_stop_idx)
    _draw_stop(cumulative_layer, project, stops_xy, first_stop_idx, data, font_label)

    frames.append(_compose(base, cumulative_layer, data, font_summary, partial=True))

    for mode, px, seg in seg_paths:
        color = SEGMENT_COLOR.get(mode, SLATE) + "FF"
        line_w = 6 if mode == "flight" else 5
        for f in range(1, FRAMES_PER_SEGMENT + 1):
            t = f / FRAMES_PER_SEGMENT
            idx = max(1, int(len(px) * t))
            segment_layer = cumulative_layer.copy()
            d = ImageDraw.Draw(segment_layer)
            for i in range(idx - 1):
                d.line([px[i], px[i + 1]], fill=color, width=line_w)
            head = px[min(idx, len(px) - 1)]
            _draw_head_marker(d, head, mode)
            frames.append(_compose(base, segment_layer, data, font_summary, partial=True))

        d = ImageDraw.Draw(cumulative_layer)
        for i in range(len(px) - 1):
            d.line([px[i], px[i + 1]], fill=color, width=line_w)
        to_idx = seg["to_idx"]
        revealed_stops.add(to_idx)
        _draw_stop(cumulative_layer, project, stops_xy, to_idx, data, font_label)

    final = _compose(base, cumulative_layer, data, font_summary, partial=False)
    for _ in range(HOLD_FRAMES):
        frames.append(final)

    _save(frames, out)


def _draw_stop(layer, project, stops_xy, idx, data, font) -> None:
    from PIL import ImageDraw

    d = ImageDraw.Draw(layer)
    lat, lon = stops_xy[idx]
    x, y = project(lat, lon)
    r = 11
    d.ellipse([x - r - 2, y - r - 2, x + r + 2, y + r + 2], fill="#FFFFFFFF")
    d.ellipse([x - r, y - r, x + r, y + r], fill=TEAL + "FF")
    d.ellipse([x - 4, y - 4, x + 4, y + 4], fill="#FFFFFFFF")
    name = data["stops"][idx]["name"]
    tw = d.textlength(name, font=font)
    bx, by = x + 18, y - 13
    pad = 7
    d.rounded_rectangle(
        [bx - pad, by - pad, bx + tw + pad, by + 22 + pad],
        radius=7,
        fill=(255, 255, 255, 235),
        outline=(0, 0, 0, 30),
        width=1,
    )
    d.text((bx, by), name, fill=TEXT + "FF", font=font)


def _draw_head_marker(draw, head: tuple[float, float], mode: str) -> None:
    x, y = head
    color = SEGMENT_COLOR.get(mode, SLATE)
    r = 9
    draw.ellipse([x - r - 3, y - r - 3, x + r + 3, y + r + 3], fill="#FFFFFFFF")
    draw.ellipse([x - r, y - r, x + r, y + r], fill=color + "FF")


def _compose(base, overlay, data, font, partial: bool):
    from PIL import Image, ImageDraw

    out = Image.alpha_composite(base, overlay)
    d = ImageDraw.Draw(out)
    title = data.get("title", "")
    if title:
        pad = 12
        tw = d.textlength(title, font=font)
        d.rounded_rectangle(
            [16, 14, 16 + tw + pad * 2, 14 + 32 + pad],
            radius=9,
            fill=(255, 255, 255, 240),
            outline=(0, 0, 0, 25),
            width=1,
        )
        d.text((16 + pad, 14 + pad - 2), title, fill=TEXT + "FF", font=font)
    if not partial:
        summary = _summary_text(data)
        if summary:
            tw = d.textlength(summary, font=font)
            pad = 12
            x = WIDTH - tw - pad * 2 - 16
            y = HEIGHT - 50
            d.rounded_rectangle(
                [x, y, x + tw + pad * 2, y + 36],
                radius=9,
                fill=(255, 255, 255, 245),
                outline=(0, 0, 0, 25),
                width=1,
            )
            d.text((x + pad, y + 6), summary, fill=TEXT + "FF", font=font)
    return out.convert("RGB")


def _summary_text(data: dict) -> str:
    parts = []
    if "total_hours" in data:
        parts.append(f"Время: {fmt_hours(data['total_hours'])}")
    if "total_price_rub" in data:
        parts.append(f"Цена: {fmt_price_short(int(data['total_price_rub']))}")
    return "   ·   ".join(parts)


def _save(frames: list, out: Path) -> None:
    ext = out.suffix.lower()
    if ext == ".gif":
        first = frames[0]
        rest = frames[1:]
        first.save(
            out,
            save_all=True,
            append_images=rest,
            duration=int(1000 / FPS),
            loop=0,
            optimize=True,
            disposal=2,
        )
    else:
        import imageio.v3 as iio
        import numpy as np

        arr = [np.asarray(f) for f in frames]
        iio.imwrite(
            out,
            arr,
            fps=FPS,
            codec="libx264",
            quality=8,
            macro_block_size=1,
            ffmpeg_params=["-pix_fmt", "yuv420p"],
        )


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
    p.add_argument("--out", required=True, help="path ending in .mp4 (preferred) or .gif")
    args = p.parse_args()
    render(load_data(args.data), Path(args.out))
    print(args.out)


if __name__ == "__main__":
    main()
