#!/usr/bin/env -S uv run --with Pillow --with numpy
"""Small helpers for collage variants. Optional — agents can re-implement.

Import:
    sys.path.insert(0, "/Users/servitola/projects/dotfiles/claude-code/shared/skills/make-collage")
    from compose import paste_anchor, pot_center_x, sample_bg, fit_h, dim, recolour_hue
"""
from __future__ import annotations
from PIL import Image
import numpy as np


def fit_h(img: Image.Image, h: int) -> Image.Image:
    """Resize keeping aspect, target height h."""
    s = h / img.height
    return img.resize((int(img.width * s), h), Image.LANCZOS)


def fit_w(img: Image.Image, w: int) -> Image.Image:
    s = w / img.width
    return img.resize((w, int(img.height * s)), Image.LANCZOS)


def paste_anchor(canvas: Image.Image, img: Image.Image, x: int, y: int,
                 anchor: str = "tl") -> tuple[int, int]:
    """Paste img on canvas, x/y is the anchor point on img.

    anchor: 'tl' top-left, 'tc' top-centre, 'tr' top-right,
            'cl', 'cc', 'cr', 'bl', 'bc', 'br'.

    Returns the actual top-left position used.
    """
    w, h = img.size
    dx = {"l": 0, "c": w // 2, "r": w}[anchor[1]]
    dy = {"t": 0, "c": h // 2, "b": h}[anchor[0]]
    px, py = x - dx, y - dy
    if img.mode == "RGBA":
        canvas.paste(img, (px, py), img)
    else:
        canvas.paste(img, (px, py))
    return px, py


def pot_center_x(rgba: Image.Image) -> int:
    """Find x of the pot (or whatever sits at the bottom) inside an RGBA cutout."""
    alpha = np.array(rgba.split()[-1])
    h = alpha.shape[0]
    band = alpha[int(h * 0.85):, :]
    cols = band.sum(axis=0).astype(np.float32)
    if cols.sum() == 0:
        return rgba.width // 2
    smoothed = np.convolve(cols, np.ones(20) / 20, mode="same")
    return int(np.argmax(smoothed))


def sample_bg(scene_path: str) -> tuple[int, int, int]:
    """Average the upper-middle band of a scene photo to estimate wall colour."""
    im = Image.open(scene_path).convert("RGB")
    band = [im.getpixel((x, y))
            for y in range(100, max(110, im.height // 3), 10)
            for x in range(im.width // 3, 2 * im.width // 3, 10)]
    if not band:
        return (130, 130, 120)
    return tuple(sum(c[i] for c in band) // len(band) for i in range(3))


def dim(img: Image.Image, factor: float) -> Image.Image:
    """Multiply RGB channels by factor, keep alpha."""
    arr = np.array(img).astype(np.float32)
    arr[:, :, :3] = np.clip(arr[:, :, :3] * factor, 0, 255)
    return Image.fromarray(arr.astype(np.uint8))


def recolour_hue(img: Image.Image, mask_pred, target_rgb: tuple[int, int, int]) -> Image.Image:
    """Recolour pixels where mask_pred(R, G, B, A) is True to target_rgb,
    preserving per-pixel luminance.

    mask_pred: callable returning a boolean ndarray. Example:
        lambda R, G, B, A: (G > R + 5) & (G > B + 5) & (A > 50)
    """
    arr = np.array(img).astype(np.int32)
    R, G, B, A = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    mask = mask_pred(R, G, B, A)
    if mask.sum() == 0:
        return img
    lum = (R * 0.3 + G * 0.59 + B * 0.11).astype(np.float32)
    mean_lum = lum[mask].mean()
    factor = np.clip(lum / mean_lum, 0.5, 1.5)
    tgt = np.array(target_rgb, dtype=np.float32)
    out = arr.copy()
    out[:, :, 0] = np.where(mask, np.clip(tgt[0] * factor, 0, 255).astype(np.int32), out[:, :, 0])
    out[:, :, 1] = np.where(mask, np.clip(tgt[1] * factor, 0, 255).astype(np.int32), out[:, :, 1])
    out[:, :, 2] = np.where(mask, np.clip(tgt[2] * factor, 0, 255).astype(np.int32), out[:, :, 2])
    return Image.fromarray(out.astype(np.uint8))


def darken(rgb: tuple[int, int, int], by: float) -> tuple[int, int, int]:
    return tuple(int(max(0, min(255, c * (1 - by)))) for c in rgb)


def lighten(rgb: tuple[int, int, int], by: float) -> tuple[int, int, int]:
    return tuple(int(max(0, min(255, c + (255 - c) * by))) for c in rgb)
