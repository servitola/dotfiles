#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["google-genai>=0.8"]
# ///
"""Image edit / background replace / relight via Gemini 2.5 Flash Image.

Free tier: 500 images/day at 1024x1024. Requires GEMINI_API_KEY.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from google import genai
from google.genai import types


MODEL = "gemini-2.5-flash-image"


def edit(input_path: Path, prompt: str, output_path: Path) -> None:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        sys.exit("GEMINI_API_KEY not set")

    img_bytes = input_path.read_bytes()
    mime = _guess_mime(input_path)

    client = genai.Client(api_key=api_key)
    response = client.models.generate_content(
        model=MODEL,
        contents=[
            prompt,
            types.Part.from_bytes(data=img_bytes, mime_type=mime),
        ],
    )

    output_path.parent.mkdir(parents=True, exist_ok=True)
    for part in response.candidates[0].content.parts:
        inline = getattr(part, "inline_data", None)
        if inline and inline.data:
            output_path.write_bytes(inline.data)
            print(f"OK: {output_path}")
            return
    sys.exit(f"No image in response. Text: {response.text!r}")


def _guess_mime(path: Path) -> str:
    suffix = path.suffix.lower()
    if suffix in {".jpg", ".jpeg"}:
        return "image/jpeg"
    if suffix == ".png":
        return "image/png"
    if suffix == ".webp":
        return "image/webp"
    return "image/jpeg"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()
    if not args.input.exists():
        sys.exit(f"input not found: {args.input}")
    edit(args.input, args.prompt, args.output)


if __name__ == "__main__":
    main()
