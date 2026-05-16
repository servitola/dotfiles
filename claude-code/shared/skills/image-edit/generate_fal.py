#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fal-client>=0.4"]
# ///
"""Text-to-image via fal.ai FLUX Pro 1.1 (~$0.04/variant). See SKILL.md.

  generate_fal.py --prompt "..." --output /tmp/g.png --variants 3

Aspect ratios: square_hd | portrait_4_3 | landscape_4_3 | etc.
Requires FAL_KEY in env or ~/.config/openai_key.sh.
"""
from __future__ import annotations
import argparse, os, re, sys, urllib.request
from pathlib import Path
import fal_client


def _load_key():
    if os.environ.get("FAL_KEY"): return
    p = Path.home() / ".config" / "openai_key.sh"
    if p.exists():
        pat = re.compile(r'^\s*(?:export\s+)?FAL_KEY\s*=\s*["\']?([^"\'#\s]+)')
        for line in p.read_text().splitlines():
            m = pat.match(line)
            if m: os.environ["FAL_KEY"] = m.group(1); return
    sys.exit("FAL_KEY not set and not found in ~/.config/openai_key.sh")


def generate(prompt, output, variants, ratio):
    _load_key()
    res = fal_client.subscribe("fal-ai/flux-pro/v1.1", with_logs=False,
        arguments={"prompt": prompt, "num_images": variants,
                   "image_size": ratio, "enable_safety_checker": False})
    images = res.get("images", []) if isinstance(res, dict) else []
    if not images: sys.exit(f"unexpected fal response: {res!r}")
    output.parent.mkdir(parents=True, exist_ok=True)
    paths = [output] + [output.with_name(f"{output.stem}-{i+1}{output.suffix}") for i in range(1, len(images))]
    for img, dst in zip(images, paths):
        url = img.get("url") if isinstance(img, dict) else None
        if not url: sys.exit(f"missing url: {img!r}")
        with urllib.request.urlopen(url) as r: dst.write_bytes(r.read())
        print(f"OK: {dst}")
    print(f"DONE: {len(paths)} variant(s), cost≈${0.04*len(paths):.2f}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--prompt", required=True)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--variants", type=int, default=1, choices=range(1, 5), metavar="N")
    p.add_argument("--ratio", default="square_hd",
                   help="image_size: square_hd | portrait_4_3 | landscape_4_3 | etc.")
    a = p.parse_args()
    generate(a.prompt, a.output, a.variants, a.ratio)


if __name__ == "__main__": main()
