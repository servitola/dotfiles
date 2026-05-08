#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = ["rembg[cpu]>=2.0.75", "Pillow>=10"]
# ///
"""Background removal via local rembg with BiRefNet-general.

Fully offline after first run. Model (~300MB) downloads to ~/.u2net/ once.
Same BiRefNet architecture as briaai/RMBG-2.0 Space — comparable quality,
no rate limits, no API drift.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from PIL import Image
from rembg import new_session, remove


def cutout(input_path: Path, output_path: Path, model: str) -> None:
    image = Image.open(input_path)
    session = new_session(model)
    result = remove(image, session=session)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    result.save(output_path, format="PNG")
    print(f"OK: {output_path} ({result.size[0]}x{result.size[1]}, model={model})")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--model",
        default="birefnet-general",
        help="birefnet-general (default, best) | birefnet-portrait | u2net | isnet-general-use",
    )
    args = parser.parse_args()
    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")
    cutout(args.input, args.output, args.model)


if __name__ == "__main__":
    main()
