#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.8"]
# ///
"""Cost breakdown stacked bars: base + taxes + bag + seat per option."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import load_data
from _theme import (
    BG,
    EMERALD,
    INDIGO,
    AMBER,
    ROSE,
    SLATE,
    TEAL,
    TEXT,
    TEXT_DIM,
    apply_mpl_style,
    fmt_price_short,
)

COMPONENTS = [
    ("base", "Тариф", TEAL),
    ("taxes", "Сборы", INDIGO),
    ("bag", "Багаж", AMBER),
    ("seat", "Место", ROSE),
    ("extra", "Допы", SLATE),
]


def render(data: dict, out: Path) -> None:
    apply_mpl_style()
    import matplotlib.patches as mpatches
    import matplotlib.pyplot as plt

    options = data["options"]
    n = len(options)
    fig_h = max(2.5, 1.0 + n * 1.0)
    fig, ax = plt.subplots(figsize=(13, fig_h))

    totals = [sum(opt.get("cost_breakdown", {}).values()) for opt in options]
    max_total = max(totals) if totals else 1
    y_positions = list(range(n - 1, -1, -1))
    cheapest = min(range(n), key=lambda i: totals[i])

    for y, opt, total in zip(y_positions, options, totals):
        breakdown = opt.get("cost_breakdown", {})
        cursor = 0.0
        for key, label, color in COMPONENTS:
            v = breakdown.get(key, 0)
            if v <= 0:
                continue
            ax.barh(
                y, v, left=cursor, height=0.55, color=color, edgecolor=BG, linewidth=3
            )
            if v / max_total > 0.04:
                ax.text(
                    cursor + v / 2,
                    y,
                    f"{label}\n{fmt_price_short(v)}",
                    ha="center",
                    va="center",
                    fontsize=10,
                    color="white",
                    fontweight="600",
                )
            cursor += v

        label_text = opt["label"]
        if cheapest == y_positions.index(y):
            label_text = f"● дешевле   {label_text}"
        ax.text(
            -max_total * 0.01,
            y + 0.45,
            label_text,
            ha="left",
            va="bottom",
            fontsize=13,
            color=TEXT,
            fontweight="700",
            family="serif",
        )
        ax.text(
            max_total * 1.02,
            y,
            fmt_price_short(int(total)),
            ha="left",
            va="center",
            fontsize=12,
            color=TEXT,
            fontweight="700",
        )

    ax.set_xlim(0, max_total * 1.18)
    ax.set_ylim(-0.7, n - 0.2)
    ax.set_yticks([])
    ax.grid(axis="x", linewidth=0.5)
    ax.xaxis.set_major_formatter(plt.FuncFormatter(lambda v, _: fmt_price_short(int(v))))

    seen = []
    for opt in options:
        for key in opt.get("cost_breakdown", {}):
            for k, label, color in COMPONENTS:
                if k == key and (k, label, color) not in seen:
                    seen.append((k, label, color))
    handles = [mpatches.Patch(color=c, label=lbl) for _, lbl, c in seen]

    raw_title = data.get("title", "Что внутри цены")
    title = raw_title.replace(" → ", " — ").replace("→", "—")
    ax.set_title(
        title,
        fontsize=20,
        fontweight="700",
        color=TEXT,
        pad=24,
        loc="left",
        family="serif",
    )
    ax.legend(
        handles=handles,
        loc="upper center",
        bbox_to_anchor=(0.5, -0.16 if n <= 2 else -0.10),
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
