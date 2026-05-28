#!/usr/bin/env -S uv run --quiet --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["matplotlib>=3.8"]
# ///
"""Editorial comparison: vertical stack of rich boarding-pass cards.

All coordinates in INCHES (axis units = inches, aspect=equal) so text
offsets stay readable regardless of figure size. Each card is a banner
with leg-by-leg breakdown: dep/arr times, carrier, per-leg duration &
price, layover length & city.

Schema per option (detail fields optional):
{
  "label": "через Ереван (EVN)",
  "total_hours": 8.5,
  "total_price_rub": 21000,
  "itinerary": [
    {"type": "flight", "from": "LCA", "to": "EVN",
     "dep_time": "07:30", "arr_time": "10:45",
     "carrier": "Wizz W6", "duration_h": 3.25, "price_rub": 8500},
    {"type": "layover", "where": "EVN", "duration_h": 2.5},
    {"type": "flight", ...}
  ]
}
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _common import load_data, resolve_display_city
from _theme import (
    AMBER,
    BG,
    CARD,
    CARD_HI,
    EMERALD,
    GRID,
    INDIGO,
    NOTE_TITLE,
    NOTE_TYPES,
    ROSE,
    SEGMENT_COLOR,
    SHADOW,
    SLATE,
    TEAL,
    TEXT,
    TEXT_DIM,
    apply_mpl_style,
    fmt_hours,
    fmt_price_short,
    safe_text,
)


def _clean_city(s: str) -> tuple[str, str | None]:
    """'EVN (Wizz W6)' → ('EVN', 'Wizz W6'). Defends against AI cramming carrier into city field."""
    if not s:
        return s, None
    if "(" in s and ")" in s:
        head, rest = s.split("(", 1)
        carrier = rest.rstrip(") ").strip()
        return head.strip(), carrier or None
    return s.strip(), None

FIG_W = 10.0
CARD_BASE_H = 1.50
H_PER_FLIGHT = 0.95
H_PER_LAYOVER = 0.55
H_PER_MEET = 0.80
TITLE_H = 1.0
GAP_H = 0.30
PAD_X = 0.40


def _normalize_itinerary(opt: dict) -> list[dict]:
    if "itinerary" in opt:
        raw = list(opt["itinerary"])
    else:
        raw = []
        for leg in opt.get("legs", []):
            t = leg.get("type")
            if t == "layover":
                raw.append({"type": "layover", "duration_h": float(leg.get("hours", 0))})
            elif t == "transfer":
                continue
            else:
                label = leg.get("label", "")
                parts = []
                for sep in (" → ", " - ", "—", "->"):
                    if sep in label:
                        parts = [p.strip() for p in label.split(sep, 1)]
                        break
                entry = {"type": t or "flight", "duration_h": float(leg.get("hours", 0))}
                if len(parts) == 2:
                    entry["from"], entry["to"] = parts
                raw.append(entry)

    cleaned = []
    for seg in raw:
        seg = dict(seg)
        t = seg.get("type")
        if t != "layover" and t not in NOTE_TYPES:
            for key in ("from", "to"):
                val = seg.get(key, "")
                if val:
                    city, carrier = _clean_city(str(val))
                    seg[key] = city
                    if carrier and not seg.get("carrier"):
                        seg["carrier"] = carrier
        cleaned.append(seg)
    return cleaned


def _card_height(itinerary: list[dict]) -> float:
    flights = sum(1 for s in itinerary if s.get("type") not in NOTE_TYPES and s.get("type") != "layover")
    layovers = sum(1 for s in itinerary if s.get("type") == "layover")
    notes = sum(1 for s in itinerary if s.get("type") in NOTE_TYPES)
    return CARD_BASE_H + flights * H_PER_FLIGHT + layovers * H_PER_LAYOVER + notes * H_PER_MEET


def render(data: dict, out: Path) -> None:
    apply_mpl_style()
    import matplotlib.pyplot as plt

    options = data["options"]
    n = len(options)
    if n < 1:
        raise SystemExit("Нужна минимум 1 опция")
    if n > 5:
        raise SystemExit("Больше 5 вариантов — сделай два графика")

    has_prices = any(o.get("total_price_rub") for o in options)
    cheapest = min(range(n), key=lambda i: options[i].get("total_price_rub", 10**9)) if has_prices else -1
    fastest = min(range(n), key=lambda i: _opt_hours(options[i]))

    card_heights = [_card_height(_normalize_itinerary(o)) for o in options]
    fig_h = TITLE_H + sum(card_heights) + GAP_H * (n - 1) + 0.4

    fig, ax = plt.subplots(figsize=(FIG_W, fig_h))
    ax.set_xlim(0, FIG_W)
    ax.set_ylim(0, fig_h)
    ax.invert_yaxis()
    ax.set_aspect("equal")
    ax.set_xticks([])
    ax.set_yticks([])
    for spine in ax.spines.values():
        spine.set_visible(False)
    ax.set_facecolor(BG)
    fig.patch.set_facecolor(BG)
    ax.grid(False)

    title = data.get("title", "Сравнение вариантов").replace(" → ", " — ").replace("→", "—")
    ax.text(
        0.15,
        0.40,
        title,
        fontsize=20,
        fontweight="700",
        color=TEXT,
        va="center",
        family="serif",
    )
    subtitle = _build_subtitle(options, cheapest, fastest)
    ax.text(0.15, 0.80, subtitle, fontsize=11, color=TEXT_DIM, va="center")

    cursor_y = TITLE_H
    for i, opt in enumerate(options):
        is_cheapest = i == cheapest
        is_fastest = i == fastest
        is_winner = is_cheapest and is_fastest
        _draw_card(
            ax=ax,
            x=0.10,
            y=cursor_y,
            w=FIG_W - 0.20,
            h=card_heights[i],
            opt=opt,
            is_cheapest=is_cheapest,
            is_fastest=is_fastest,
            is_winner=is_winner,
        )
        cursor_y += card_heights[i] + GAP_H

    plt.savefig(out, facecolor=BG, dpi=260, bbox_inches="tight", pad_inches=0.25)
    plt.close(fig)


def _opt_hours(opt: dict) -> float:
    if "total_hours" in opt:
        return float(opt["total_hours"])
    out_h = opt.get("outbound_hours")
    ret_h = opt.get("return_hours")
    if out_h is not None and ret_h is not None:
        return float(out_h) + float(ret_h)
    return float(sum(l.get("hours", l.get("duration_h", 0)) for l in opt.get("legs", []) + opt.get("itinerary", [])))


def _build_subtitle(options: list, cheapest: int, fastest: int) -> str:
    parts = []
    if cheapest >= 0:
        co = options[cheapest]
        parts.append(f"дешевле — {co['label']}, {fmt_price_short(int(co['total_price_rub']))}")
        if cheapest != fastest:
            fo = options[fastest]
            parts.append(f"быстрее — {fo['label']}, {fmt_hours(_opt_hours(fo))}")
        else:
            parts.append("он же и быстрее")
    else:
        return ""
    return "   ·   ".join(parts)


def _draw_card(*, ax, x, y, w, h, opt, is_cheapest, is_fastest, is_winner):
    from matplotlib.patches import FancyBboxPatch, Rectangle

    if is_winner:
        accent = EMERALD
        bg = CARD_HI
    elif is_cheapest:
        accent = EMERALD
        bg = CARD
    elif is_fastest:
        accent = INDIGO
        bg = CARD
    else:
        accent = SLATE
        bg = CARD

    for j in range(4):
        offset = 0.04 + j * 0.025
        alpha = 0.05 - j * 0.011
        if alpha <= 0:
            break
        shadow = FancyBboxPatch(
            (x + offset, y + offset),
            w,
            h,
            boxstyle="round,pad=0.005,rounding_size=0.12",
            facecolor=(0.17, 0.15, 0.13, alpha),
            edgecolor="none",
            zorder=1,
        )
        ax.add_patch(shadow)

    card = FancyBboxPatch(
        (x, y),
        w,
        h,
        boxstyle="round,pad=0.005,rounding_size=0.12",
        facecolor=bg,
        edgecolor="none",
        linewidth=0,
        zorder=2,
    )
    ax.add_patch(card)

    stripe = FancyBboxPatch(
        (x, y),
        0.16,
        h,
        boxstyle="round,pad=0,rounding_size=0.05",
        facecolor=accent,
        edgecolor="none",
        zorder=3,
    )
    ax.add_patch(stripe)

    header_y = y + 0.42
    title_x = x + PAD_X

    label_text = safe_text(opt["label"])
    label_fs = 16 if len(label_text) <= 36 else 14 if len(label_text) <= 48 else 12
    ax.text(
        title_x,
        header_y,
        label_text,
        fontsize=label_fs,
        fontweight="700",
        color=TEXT,
        ha="left",
        va="center",
        family="serif",
        zorder=5,
    )

    badges = []
    if is_winner:
        badges.append(("● ОПТИМАЛЬНО", EMERALD))
    else:
        if is_cheapest:
            badges.append(("● ДЕШЕВЛЕ", EMERALD))
        if is_fastest:
            badges.append(("● БЫСТРЕЕ", INDIGO))
    if badges:
        ax.text(
            title_x,
            header_y + 0.35,
            "  ·  ".join(b[0] for b in badges),
            fontsize=10.5,
            fontweight="800",
            color=badges[0][1] if len(badges) == 1 else EMERALD,
            ha="left",
            va="center",
            zorder=5,
        )

    price = int(opt.get("total_price_rub", 0) or 0)
    hours = float(opt.get("total_hours", 0))
    right_edge = x + w - PAD_X
    time_x = right_edge
    price_x = right_edge - 2.2

    if price > 0:
        ax.text(
            price_x,
            header_y,
            fmt_price_short(price),
            fontsize=22,
            fontweight="800",
            color=accent if (is_cheapest or is_winner) else TEXT,
            ha="right",
            va="center",
            zorder=5,
        )
        ax.text(
            price_x,
            header_y + 0.35,
            "цена",
            fontsize=10,
            color=TEXT_DIM,
            ha="right",
            va="center",
            zorder=5,
        )
    out_h = opt.get("outbound_hours")
    ret_h = opt.get("return_hours")
    if out_h is not None and ret_h is not None:
        ax.text(
            time_x,
            header_y - 0.05,
            f"туда {fmt_hours(float(out_h))}",
            fontsize=13,
            fontweight="700",
            color=accent if (is_fastest or is_winner) else TEXT,
            ha="right",
            va="center",
            zorder=5,
        )
        ax.text(
            time_x,
            header_y + 0.30,
            f"обратно {fmt_hours(float(ret_h))}",
            fontsize=13,
            fontweight="700",
            color=accent if (is_fastest or is_winner) else TEXT,
            ha="right",
            va="center",
            zorder=5,
        )
        note = opt.get("overnight_note")
        if note:
            ax.text(
                time_x,
                header_y + 0.62,
                safe_text(note),
                fontsize=9.5,
                color=TEXT_DIM,
                fontweight="600",
                ha="right",
                va="center",
                zorder=5,
            )
    else:
        ax.text(
            time_x,
            header_y,
            fmt_hours(hours),
            fontsize=22,
            fontweight="700",
            color=accent if (is_fastest or is_winner) else TEXT,
            ha="right",
            va="center",
            zorder=5,
        )
        ax.text(
            time_x,
            header_y + 0.35,
            "в пути",
            fontsize=10,
            color=TEXT_DIM,
            ha="right",
            va="center",
            zorder=5,
        )

    divider_y = y + 1.10
    perf_left = x + PAD_X
    perf_right = x + w - PAD_X
    n_dots = 90
    dot_xs = [perf_left + (perf_right - perf_left) * i / (n_dots - 1) for i in range(n_dots)]
    ax.scatter(
        dot_xs,
        [divider_y] * n_dots,
        s=2.2,
        color=TEXT_DIM,
        alpha=0.55,
        zorder=4,
        marker="o",
        linewidths=0,
    )
    notch_r = 0.08
    notch_color = BG
    ax.scatter(
        [x, x + w],
        [divider_y, divider_y],
        s=180,
        color=notch_color,
        zorder=5,
        marker="o",
        edgecolors="none",
    )

    itin = _normalize_itinerary(opt)
    if not itin:
        return
    cursor_y = divider_y + 0.05
    for seg in itin:
        if seg.get("type") == "layover":
            _draw_layover_row(ax, x, cursor_y, w, seg)
            cursor_y += H_PER_LAYOVER
        elif seg.get("type") in NOTE_TYPES:
            _draw_note_row(ax, x, cursor_y, w, seg)
            cursor_y += H_PER_MEET
        else:
            _draw_flight_row(ax, x, cursor_y, w, seg)
            cursor_y += H_PER_FLIGHT


def _draw_flight_row(ax, card_x, y, card_w, seg: dict):
    mode = seg.get("type", "flight")
    color = SEGMENT_COLOR.get(mode, TEAL)

    left_x = card_x + PAD_X
    right_x = card_x + card_w - PAD_X

    dep_t = safe_text(seg.get("dep_time", "")) or "—:—"
    arr_t = safe_text(seg.get("arr_time", "")) or "—:—"
    fr_name, fr_code = resolve_display_city(str(seg.get("from", "")))
    to_name, to_code = resolve_display_city(str(seg.get("to", "")))
    carrier = safe_text(seg.get("carrier", ""))
    dur = float(seg.get("duration_h", 0))
    price = seg.get("price_rub")

    line_y = y + 0.55
    time_y = line_y - 0.30

    ax.text(
        left_x,
        time_y,
        dep_t,
        fontsize=12,
        fontweight="700",
        color=TEXT_DIM,
        ha="left",
        va="center",
        zorder=5,
    )
    ax.text(
        left_x,
        line_y,
        fr_name,
        fontsize=14,
        fontweight="700",
        color=TEXT,
        ha="left",
        va="center",
        family="serif",
        zorder=5,
    )

    ax.text(
        right_x,
        time_y,
        arr_t,
        fontsize=12,
        fontweight="700",
        color=TEXT_DIM,
        ha="right",
        va="center",
        zorder=5,
    )
    ax.text(
        right_x,
        line_y,
        to_name,
        fontsize=14,
        fontweight="700",
        color=TEXT,
        ha="right",
        va="center",
        family="serif",
        zorder=5,
    )

    conn_x0 = left_x + 1.65
    conn_x1 = right_x - 1.65
    if conn_x1 > conn_x0:
        ax.plot(
            [conn_x0, conn_x1],
            [line_y, line_y],
            color=color,
            linewidth=2.0,
            solid_capstyle="round",
            zorder=4,
        )
        ax.scatter(
            [conn_x0, conn_x1],
            [line_y, line_y],
            s=28,
            color=color,
            edgecolors="white",
            linewidths=1.0,
            zorder=5,
        )

    detail_parts = []
    if carrier:
        detail_parts.append(carrier)
    if dur > 0:
        detail_parts.append(fmt_hours(dur))
    if isinstance(price, (int, float)) and price > 0:
        detail_parts.append(fmt_price_short(int(price)))
    if detail_parts:
        mid_x = (conn_x0 + conn_x1) / 2 if conn_x1 > conn_x0 else (left_x + right_x) / 2
        detail_text = "   ·   ".join(detail_parts)
        detail_fs = 10.5 if len(detail_text) <= 48 else 9 if len(detail_text) <= 64 else 8
        ax.text(
            mid_x,
            line_y - 0.28,
            detail_text,
            fontsize=detail_fs,
            color=TEXT,
            fontweight="600",
            ha="center",
            va="center",
            zorder=6,
        )


def _draw_layover_row(ax, card_x, y, card_w, seg: dict):
    dur = float(seg.get("duration_h", 0))
    where_raw = seg.get("where", "")
    where, _ = resolve_display_city(str(where_raw)) if where_raw else ("", None)
    line_y = y + 0.28

    parts = [f"пересадка {fmt_hours(dur)}"]
    if where and where != "—":
        parts.append(where)
    text = "  ·  ".join(parts)

    left_x = card_x + PAD_X
    right_x = card_x + card_w - PAD_X
    side = 1.6
    ax.plot([left_x, left_x + side], [line_y, line_y], color=GRID, linewidth=1, zorder=3)
    ax.plot([right_x - side, right_x], [line_y, line_y], color=GRID, linewidth=1, zorder=3)
    ax.text(
        (left_x + right_x) / 2,
        line_y,
        text,
        fontsize=10.5,
        fontweight="600",
        color=TEXT_DIM,
        ha="center",
        va="center",
        zorder=5,
    )


def _draw_note_row(ax, card_x, y, card_w, seg: dict):
    """Banner for meet/warning/alt/tip — color and title from segment type."""
    from matplotlib.patches import FancyBboxPatch

    seg_type = seg.get("type", "meet")
    color = SEGMENT_COLOR.get(seg_type, AMBER)
    title = NOTE_TITLE.get(seg_type, "ЗАМЕТКА")

    left_x = card_x + PAD_X
    right_x = card_x + card_w - PAD_X
    band_y = y + 0.08
    band_h = H_PER_MEET - 0.20

    band = FancyBboxPatch(
        (left_x, band_y),
        right_x - left_x,
        band_h,
        boxstyle="round,pad=0.005,rounding_size=0.08",
        facecolor=color + "22",
        edgecolor=color,
        linewidth=1.2,
        zorder=4,
    )
    ax.add_patch(band)

    where = safe_text(str(seg.get("where", "")))
    time = safe_text(str(seg.get("time", "")))
    note = safe_text(str(seg.get("note", "")))

    title_y = band_y + band_h - 0.22
    ax.text(
        left_x + 0.18,
        title_y,
        f"● {title}",
        fontsize=10.5,
        fontweight="800",
        color=color,
        ha="left",
        va="center",
        zorder=6,
    )
    if time:
        ax.text(
            right_x - 0.18,
            title_y,
            time,
            fontsize=11,
            fontweight="700",
            color=TEXT,
            ha="right",
            va="center",
            zorder=6,
        )
    if where:
        ax.text(
            left_x + 0.18,
            title_y - 0.28,
            where,
            fontsize=12.5,
            fontweight="700",
            color=TEXT,
            ha="left",
            va="center",
            family="serif",
            zorder=6,
        )
    if note:
        note_fs = 10 if len(note) <= 90 else 8.5
        ax.text(
            left_x + 0.18,
            title_y - 0.52,
            note,
            fontsize=note_fs,
            color=TEXT_DIM,
            fontweight="600",
            ha="left",
            va="center",
            zorder=6,
        )


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--data", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()
    render(load_data(args.data), Path(args.out))
    print(args.out)


if __name__ == "__main__":
    main()
