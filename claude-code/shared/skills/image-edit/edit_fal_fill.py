#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fal-client>=0.4", "Pillow>=10"]
# ///
"""Inpaint a region via fal.ai FLUX Fill Pro. Paid (~$0.05 per image).

Use when only part of the image must change. Full-quality FLUX Fill —
better identity preservation, sharper edges, no GPU queue. Pass either
a paint mask PNG or a --bbox x,y,w,h that is rasterised into a
rectangular mask. White = repaint, black = preserve.

Requires FAL_KEY in env or in ~/.config/openai_key.sh.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
import tempfile
import urllib.request
from pathlib import Path

import fal_client
from PIL import Image, ImageDraw


def inpaint(input_path: Path, mask_path: Path, prompt: str, output_path: Path) -> None:
    _load_fal_key()

    image_url = fal_client.upload_file(str(input_path))
    mask_url = fal_client.upload_file(str(mask_path))

    result = fal_client.subscribe(
        "fal-ai/flux-pro/v1/fill",
        arguments={
            "prompt": prompt,
            "image_url": image_url,
            "mask_url": mask_url,
        },
        with_logs=False,
    )
    out_url = _first_image_url(result)
    if not out_url:
        raise SystemExit(f"unexpected fal response: {result!r}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(out_url) as resp:
        output_path.write_bytes(resp.read())
    print(f"OK: {output_path} (endpoint=fal-ai/flux-pro/v1/fill, cost≈$0.05)")


def _first_image_url(result):
    images = result.get("images") if isinstance(result, dict) else None
    if not images:
        return None
    first = images[0]
    return first.get("url") if isinstance(first, dict) else None


def _bbox_to_mask(input_path: Path, bbox_str: str) -> Path:
    try:
        x, y, w, h = (int(v.strip()) for v in bbox_str.split(","))
    except ValueError:
        sys.exit(f"--bbox must be x,y,w,h integers, got: {bbox_str!r}")
    with Image.open(input_path) as src:
        size = src.size
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rectangle([x, y, x + w, y + h], fill=255)
    fd, out = tempfile.mkstemp(prefix="fal_fill_mask_", suffix=".png")
    mask.save(out)
    Path(out).chmod(0o644)
    return Path(out)


def _load_fal_key() -> None:
    if os.environ.get("FAL_KEY"):
        return
    secrets = Path.home() / ".config" / "openai_key.sh"
    if secrets.exists():
        pattern = re.compile(r'^\s*(?:export\s+)?FAL_KEY\s*=\s*["\']?([^"\'#\s]+)')
        for line in secrets.read_text().splitlines():
            m = pattern.match(line)
            if m:
                os.environ["FAL_KEY"] = m.group(1)
                return
    sys.exit("FAL_KEY not set and not found in ~/.config/openai_key.sh")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    mask_group = parser.add_mutually_exclusive_group(required=True)
    mask_group.add_argument("--mask", type=Path, help="PNG mask, white=repaint, same size as input")
    mask_group.add_argument("--bbox", help="rectangle to repaint, format: x,y,w,h in input pixels")
    args = parser.parse_args()

    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")

    if args.mask:
        if not args.mask.exists():
            sys.exit(f"mask not found: {args.mask}")
        mask_path = args.mask
    else:
        mask_path = _bbox_to_mask(args.input, args.bbox)

    inpaint(args.input, mask_path, args.prompt, args.output)


if __name__ == "__main__":
    main()
