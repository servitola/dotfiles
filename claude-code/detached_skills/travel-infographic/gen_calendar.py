#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.8"]
# ///
"""Calendar heatmap of prices by day."""

from __future__ import annotations

import argparse
import calendar
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import load_data
from _theme import (
    BG,
    EMERALD,
    ROSE,
    TEXT,
    TEXT_DIM,
    apply_mpl_style,
    fmt_price_short,
)


WEEKDAY_RU = ["Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс"]
MONTH_RU = {
    1: "Январь", 2: "Февраль", 3: "Март", 4: "Апрель",
    5: "Май", 6: "Июнь", 7: "Июль", 8: "Август",
    9: "Сентябрь", 10: "Октябрь", 11: "Ноябрь", 12: "Декабрь",
}


def render(data: dict, out: Path) -> None:
    apply_mpl_style()
    import matplotlib.pyplot as plt
    from matplotlib.colors import LinearSegmentedColormap
    from matplotlib.patches import FancyBboxPatch

    year = int(data["year"])
    month = int(data["month"])
    prices: dict[str, int] = {k: int(v) for k, v in data["prices"].items()}

    cal = calendar.Calendar(firstweekday=0)
    weeks = cal.monthdayscalendar(year, month)

    fig, ax = plt.subplots(figsize=(12, 8))
    ax.set_xlim(0, 7)
    ax.set_ylim(0, len(weeks))
    ax.invert_yaxis()
    ax.set_xticks([i + 0.5 for i in range(7)])
    ax.set_xticklabels(WEEKDAY_RU, fontsize=12, color=TEXT_DIM)
    ax.set_yticks([])
    ax.set_aspect("equal")
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.grid(False)
    ax.tick_params(axis="x", pad=10, labelbottom=False, labeltop=True)

    available = [v for v in prices.values() if v > 0]
    if not available:
        raise SystemExit("Пустой prices, нечего рисовать")
    lo, hi = min(available), max(available)
    cmap = LinearSegmentedColormap.from_list("price", [EMERALD, "#FBBF24", ROSE], N=256)
    cheapest_day = min(
        ((date.fromisoformat(k).day, v) for k, v in prices.items() if v > 0),
        key=lambda x: x[1],
    )[0]

    for wi, week in enumerate(weeks):
        for di, day in enumerate(week):
            if day == 0:
                continue
            iso = f"{year:04d}-{month:02d}-{day:02d}"
            price = prices.get(iso, 0)
            x = di + 0.05
            y = wi + 0.05
            w, h = 0.9, 0.9
            if price <= 0:
                color = "#F1F5F9"
            else:
                norm = (price - lo) / (hi - lo) if hi > lo else 0.0
                color = cmap(norm)
            box = FancyBboxPatch(
                (x, y),
                w,
                h,
                boxstyle="round,pad=0.02,rounding_size=0.12",
                facecolor=color,
                edgecolor="none",
                linewidth=0,
            )
            ax.add_patch(box)
            ax.text(
                x + 0.08,
                y + 0.18,
                str(day),
                fontsize=11,
                color=TEXT,
                fontweight="700",
                ha="left",
                va="top",
            )
            if price > 0:
                ax.text(
                    x + w / 2,
                    y + h - 0.18,
                    fmt_price_short(price),
                    fontsize=11,
                    color=TEXT,
                    fontweight="600",
                    ha="center",
                    va="bottom",
                )
                if day == cheapest_day:
                    ax.text(
                        x + w - 0.1,
                        y + 0.18,
                        "●",
                        fontsize=14,
                        color="#B45309",
                        ha="right",
                        va="top",
                    )

    raw_title = data.get("title") or f"{data.get('route', '')} — {MONTH_RU[month]} {year}"
    title = raw_title.strip().replace(" → ", " — ").replace("→", "—")
    ax.set_title(
        title,
        fontsize=20,
        fontweight="700",
        color=TEXT,
        pad=44,
        loc="center",
        family="serif",
    )
    ax.text(
        0.5,
        1.04,
        f"дешевле {fmt_price_short(lo)}   ·   дороже {fmt_price_short(hi)}   ·   ● — самый дешёвый день",
        fontsize=10,
        color=TEXT_DIM,
        transform=ax.transAxes,
        ha="center",
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
