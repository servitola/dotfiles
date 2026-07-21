#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fal-client>=0.4", "Pillow>=10"]
# ///
"""Inpaint via fal.ai FLUX Fill Pro (~$0.05/variant). See SKILL.md.

White=repaint, black=preserve. Pass --mask PNG or --bbox x,y,w,h.
--variants N (1-4): one paid call, returns N alternatives.
Outputs are written as <output>, <output_stem>-2.png, -3.png, -4.png.
Requires FAL_KEY in env or ~/.config/openai_key.sh.
"""
from __future__ import annotations
import argparse, os, re, shutil, sys, tempfile, urllib.request
from pathlib import Path
import fal_client
from PIL import Image, ImageDraw


def _upload(path: Path) -> str:
    """Upload to fal storage from an ASCII-named copy when needed.

    fal-client sends the file name in an HTTP header (ASCII only); a
    Cyrillic name fails there and 1.x reports it as "Invalid storage type".
    """
    if path.name.isascii():
        return fal_client.upload_file(str(path))
    with tempfile.TemporaryDirectory() as tmp:
        safe = Path(tmp) / f"upload{path.suffix or '.png'}"
        shutil.copyfile(path, safe)
        return fal_client.upload_file(str(safe))


def _load_key():
    if os.environ.get("FAL_KEY"): return
    p = Path.home() / ".config" / "openai_key.sh"
    if p.exists():
        pat = re.compile(r'^\s*(?:export\s+)?FAL_KEY\s*=\s*["\']?([^"\'#\s]+)')
        for line in p.read_text().splitlines():
            m = pat.match(line)
            if m: os.environ["FAL_KEY"] = m.group(1); return
    sys.exit("FAL_KEY not set and not found in ~/.config/openai_key.sh")


def _bbox_mask(input_path, bbox):
    try: x, y, w, h = (int(v) for v in bbox.split(","))
    except ValueError: sys.exit(f"--bbox must be x,y,w,h ints, got: {bbox!r}")
    with Image.open(input_path) as src: size = src.size
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rectangle([x, y, x+w, y+h], fill=255)
    _, out = tempfile.mkstemp(prefix="fal_fill_", suffix=".png")
    mask.save(out); Path(out).chmod(0o644); return Path(out)


def inpaint(input_path, mask_path, prompt, output, variants):
    _load_key()
    iu = _upload(input_path); mu = _upload(mask_path)
    res = fal_client.subscribe("fal-ai/flux-pro/v1/fill", with_logs=False,
        arguments={"prompt": prompt, "image_url": iu, "mask_url": mu, "num_images": variants})
    images = res.get("images", []) if isinstance(res, dict) else []
    if not images: sys.exit(f"unexpected fal response: {res!r}")
    output.parent.mkdir(parents=True, exist_ok=True)
    paths = [output] + [output.with_name(f"{output.stem}-{i+1}{output.suffix}") for i in range(1, len(images))]
    for img, dst in zip(images, paths):
        url = img.get("url") if isinstance(img, dict) else None
        if not url: sys.exit(f"missing url in fal image: {img!r}")
        with urllib.request.urlopen(url) as r: dst.write_bytes(r.read())
        print(f"OK: {dst}")
    print(f"DONE: {len(paths)} variant(s), cost≈${0.05*len(paths):.2f}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, type=Path)
    p.add_argument("--prompt", required=True)
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--variants", type=int, default=1, choices=range(1, 5), metavar="N")
    g = p.add_mutually_exclusive_group(required=True)
    g.add_argument("--mask", type=Path); g.add_argument("--bbox")
    a = p.parse_args()
    if not a.input.exists(): sys.exit(f"input not found: {a.input}")
    if a.mask and not a.mask.exists(): sys.exit(f"mask not found: {a.mask}")
    mask_path = a.mask or _bbox_mask(a.input, a.bbox)
    inpaint(a.input, mask_path, a.prompt, a.output, a.variants)


if __name__ == "__main__": main()
