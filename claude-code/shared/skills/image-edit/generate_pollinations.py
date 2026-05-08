#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Text-to-image via Pollinations.ai. Free, no key, FLUX under the hood."""
from __future__ import annotations

import argparse
import sys
import urllib.parse
import urllib.request
from pathlib import Path


BASE_URL = "https://image.pollinations.ai/prompt/"


def generate(prompt: str, output_path: Path, width: int, height: int, model: str, seed: int | None) -> None:
    qs = {
        "width": str(width),
        "height": str(height),
        "model": model,
        "nologo": "true",
        "enhance": "true",
    }
    if seed is not None:
        qs["seed"] = str(seed)
    url = BASE_URL + urllib.parse.quote(prompt, safe="") + "?" + urllib.parse.urlencode(qs)
    req = urllib.request.Request(url, headers={"User-Agent": "image-edit-skill/1.0"})
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(req, timeout=120) as resp:
        if resp.status != 200:
            sys.exit(f"HTTP {resp.status}: {resp.read()[:500]!r}")
        output_path.write_bytes(resp.read())
    print(f"OK: {output_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--prompt", required=True)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--width", type=int, default=1024)
    parser.add_argument("--height", type=int, default=1024)
    parser.add_argument("--model", default="flux", help="flux | flux-realism | turbo | kontext")
    parser.add_argument("--seed", type=int, default=None)
    args = parser.parse_args()
    generate(args.prompt, args.output, args.width, args.height, args.model, args.seed)


if __name__ == "__main__":
    main()
