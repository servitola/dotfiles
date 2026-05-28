#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.8"]
# ///
"""Door-to-door timeline: stacked horizontal bars per option."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import load_data
from _theme import (
    BG,
    CARD,
    EMERALD,
    SEGMENT_COLOR,
    SEGMENT_LABEL,
    SLATE,
    TEXT,
    TEXT_DIM,
    apply_mpl_style,
    fmt_hours,
    fmt_price_short,
    safe_text,
)


def render(data: dict, out: Path) -> None:
    apply_mpl_style()
    import matplotlib.patches as mpatches
    import matplotlib.pyplot as plt

    options = data["options"]
    n = len(options)
    fig_h = max(2.5, 1.0 + n * 1.1)
    fig, ax = plt.subplots(figsize=(13, fig_h))

    best_idx = min(range(n), key=lambda i: options[i].get("total_hours", 1e9))
    cheapest_idx = min(
        range(n), key=lambda i: options[i].get("total_price_rub", 10**9)
    )

    y_positions = list(range(n - 1, -1, -1))
    max_total = max(opt.get("total_hours", sum(l["hours"] for l in opt["legs"])) for opt in options)

    for y, opt in zip(y_positions, options):
        cursor = 0.0
        for leg in opt["legs"]:
            color = SEGMENT_COLOR.get(leg["type"], SLATE)
            w = float(leg["hours"])
            ax.barh(
                y, w, left=cursor, height=0.55, color=color, edgecolor=BG, linewidth=2
            )
            if w / max_total > 0.06:
                label = f"{safe_text(leg['label'])}\n{fmt_hours(w)}"
                ax.text(
                    cursor + w / 2,
                    y,
                    label,
                    ha="center",
                    va="center",
                    fontsize=10,
                    color="white",
                    fontweight="600",
                )
            cursor += w

        total_h = opt.get("total_hours", cursor)
        price = opt.get("total_price_rub")
        right_label = fmt_hours(total_h)
        if price is not None:
            right_label += f"   ·   {fmt_price_short(price)}"
        ax.text(
            max_total * 1.02,
            y,
            right_label,
            ha="left",
            va="center",
            fontsize=12,
            color=TEXT,
            fontweight="700",
        )

    badges_y = {}
    for idx, label in [(best_idx, "● быстрее"), (cheapest_idx, "● дешевле")]:
        badges_y.setdefault(y_positions[idx], []).append(label)

    for y, opt in zip(y_positions, options):
        title = opt["label"]
        badges = badges_y.get(y, [])
        if badges:
            title = f"{title}   " + "  ".join(badges)
        ax.text(
            -max_total * 0.01,
            y + 0.45,
            title,
            ha="left",
            va="bottom",
            fontsize=13,
            color=TEXT,
            fontweight="700",
            family="serif",
        )

    ax.set_xlim(0, max_total * 1.18)
    ax.set_ylim(-0.7, n - 0.2)
    ax.set_yticks([])
    ax.set_xlabel("часы в пути")
    ax.grid(axis="x", linewidth=0.5)
    ax.set_axisbelow(True)

    title = data.get("title", "Сравнение вариантов").replace(" → ", " — ").replace("→", "—")
    ax.set_title(
        title,
        fontsize=20,
        fontweight="700",
        color=TEXT,
        pad=24,
        loc="left",
        family="serif",
    )

    seen_types = []
    for opt in options:
        for leg in opt["legs"]:
            if leg["type"] not in seen_types:
                seen_types.append(leg["type"])
    handles = [
        mpatches.Patch(color=SEGMENT_COLOR.get(t, SLATE), label=SEGMENT_LABEL.get(t, t))
        for t in seen_types
    ]
    ax.legend(
        handles=handles,
        loc="upper center",
        bbox_to_anchor=(0.5, -0.20 if n <= 2 else -0.12),
        ncol=len(handles),
        frameon=False,
    )

    plt.savefig(out, facecolor=BG, dpi=260, bbox_inches="tight", pad_inches=0.25)
    plt.close(fig)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--data", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()
    render(load_data(args.data), Path(args.out))
    print(args.out)


if __name__ == "__main__":
    main()
