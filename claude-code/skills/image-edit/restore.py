#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["Pillow>=10", "numpy>=1.24"]
# ///
"""Restore color & sharpness after a paid edit (Kontext/Fill) bleached or shrank it.

Kontext often comes back paler, softer, and smaller than the source. This re-aligns
the edit to the original instead of re-running the whole expensive edit:
  1. histogram-match each RGB channel to the reference (the original photo)  → color back
  2. UnsharpMask                                                              → crispness back
  3. LANCZOS upscale to the reference's exact size                            → size back

Pure NumPy histogram matching (CDF LUT per channel) — same result as
skimage.exposure.match_histograms, no extra dependency. Deterministic.

  restore.py --input edited.png --reference original.jpg --output final.png
  restore.py --input edited.png --reference original.jpg --output final.png \
    --no-match            # only sharpen + upscale
  restore.py ... --sharpen 0.6 --no-upscale --preview /tmp/preview.png
"""
from __future__ import annotations
import argparse, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter


def match_histograms(src: np.ndarray, ref: np.ndarray) -> np.ndarray:
    """Match src (HxWx3 uint8) channel CDFs to ref (HxWx3 uint8)."""
    out = np.empty_like(src)
    for c in range(3):
        s = src[..., c].ravel()
        r = ref[..., c].ravel()
        s_vals, s_idx, s_counts = np.unique(s, return_inverse=True, return_counts=True)
        r_vals, r_counts = np.unique(r, return_counts=True)
        s_cdf = np.cumsum(s_counts).astype(np.float64) / s.size
        r_cdf = np.cumsum(r_counts).astype(np.float64) / r.size
        mapped = np.interp(s_cdf, r_cdf, r_vals)
        out[..., c] = mapped[s_idx].reshape(src[..., c].shape).astype(np.uint8)
    return out


def main():
    p = argparse.ArgumentParser(description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--input", required=True, type=Path, help="the edited image to restore")
    p.add_argument("--reference", required=True, type=Path, help="the original source photo")
    p.add_argument("--output", required=True, type=Path)
    p.add_argument("--no-match", action="store_true", help="skip histogram matching")
    p.add_argument("--no-upscale", action="store_true", help="skip upscale to reference size")
    p.add_argument("--sharpen", type=float, default=0.8,
                   help="UnsharpMask strength 0..2 (0 disables); default 0.8")
    p.add_argument("--preview", type=Path, help="also write a <=768px preview here")
    a = p.parse_args()
    for f in (a.input, a.reference):
        if not f.exists(): sys.exit(f"not found: {f}")

    edited = Image.open(a.input).convert("RGB")
    ref = Image.open(a.reference).convert("RGB")

    if not a.no_match:
        arr = match_histograms(np.asarray(edited), np.asarray(ref))
        edited = Image.fromarray(arr, "RGB")

    if a.sharpen > 0:
        radius = 2.0
        percent = int(round(a.sharpen * 100))
        edited = edited.filter(ImageFilter.UnsharpMask(radius=radius, percent=percent, threshold=2))

    if not a.no_upscale and edited.size != ref.size:
        edited = edited.resize(ref.size, Image.LANCZOS)

    a.output.parent.mkdir(parents=True, exist_ok=True)
    edited.save(a.output)
    print(f"OK: {a.output} ({edited.size[0]}x{edited.size[1]})")

    if a.preview:
        prev = edited.copy()
        prev.thumbnail((768, 768), Image.LANCZOS)
        a.preview.parent.mkdir(parents=True, exist_ok=True)
        prev.save(a.preview)
        print(f"preview: {a.preview} ({prev.size[0]}x{prev.size[1]})")


if __name__ == "__main__": main()
