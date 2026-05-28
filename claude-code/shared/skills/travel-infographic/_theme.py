"""Shared theme: palette, matplotlib rcParams, segment colors."""

from __future__ import annotations

BG = "#F1ECE0"
CARD = "#FBF7EE"
CARD_HI = "#E8EFE6"
TEXT = "#1F2937"
TEXT_DIM = "#7A7368"
GRID = "#E5DFD2"
SHADOW = "#2B2620"

TEAL = "#0F8F86"
ORANGE = "#D97442"
VIOLET = "#7C6BB6"
INDIGO = "#3F4B9A"
EMERALD = "#0E7C5E"
AMBER = "#D69E2E"
ROSE = "#C2503C"
SLATE = "#9C9485"

SEGMENT_COLOR = {
    "flight": TEAL,
    "train": ORANGE,
    "bus": ORANGE,
    "car": SLATE,
    "transfer": VIOLET,
    "layover": VIOLET,
    "meet": AMBER,
    "warning": ROSE,
    "alt": INDIGO,
    "tip": EMERALD,
}

SEGMENT_LABEL = {
    "flight": "Перелёт",
    "train": "Поезд",
    "bus": "Автобус",
    "car": "Авто",
    "transfer": "Трансфер",
    "layover": "Пересадка",
    "meet": "Встреча",
    "warning": "Внимание",
    "alt": "Альтернатива",
    "tip": "Совет",
}

NOTE_TYPES = {"meet", "warning", "alt", "tip"}
NOTE_TITLE = {
    "meet": "ВСТРЕЧА",
    "warning": "ВНИМАНИЕ",
    "alt": "АЛЬТЕРНАТИВА",
    "tip": "СОВЕТ",
}


def apply_mpl_style() -> None:
    import matplotlib as mpl

    mpl.rcParams.update(
        {
            "figure.facecolor": BG,
            "figure.dpi": 144,
            "savefig.facecolor": BG,
            "savefig.bbox": "tight",
            "savefig.pad_inches": 0.4,
            "axes.facecolor": CARD,
            "axes.edgecolor": GRID,
            "axes.labelcolor": TEXT_DIM,
            "axes.titlecolor": TEXT,
            "axes.titlesize": 16,
            "axes.titleweight": "bold",
            "axes.titlepad": 18,
            "axes.spines.top": False,
            "axes.spines.right": False,
            "axes.spines.left": False,
            "axes.grid": True,
            "axes.axisbelow": True,
            "text.color": TEXT,
            "xtick.color": TEXT_DIM,
            "ytick.color": TEXT_DIM,
            "xtick.major.size": 0,
            "ytick.major.size": 0,
            "grid.color": GRID,
            "grid.linewidth": 0.8,
            "grid.linestyle": "-",
            "font.family": "sans-serif",
            "font.sans-serif": [
                "Helvetica Neue",
                "Helvetica",
                "DejaVu Sans",
                "Arial",
            ],
            "font.serif": [
                "Georgia",
                "Charter",
                "DejaVu Serif",
                "Times New Roman",
            ],
            "font.size": 12,
            "legend.frameon": False,
            "legend.fontsize": 11,
        }
    )


def fmt_hours(hours: float) -> str:
    h = int(hours)
    m = int(round((hours - h) * 60))
    if h == 0:
        return f"{m}м"
    if m == 0:
        return f"{h}ч"
    return f"{h}ч {m}м"


def fmt_price_rub(rub: int) -> str:
    if rub >= 1000:
        return f"{rub // 1000}.{(rub % 1000) // 100} тыс ₽"
    return f"{rub} ₽"


def fmt_price_short(rub: int) -> str:
    return f"{rub // 1000}к ₽" if rub >= 1000 else f"{rub} ₽"


def safe_text(s: str) -> str:
    """Replace glyphs missing from common UI fonts and strip emoji that won't render."""
    import re

    s = (
        s.replace(" → ", " — ")
        .replace("→", "—")
        .replace("←", "—")
        .replace("★", "●")
        .replace("⏱", "")
        .replace("⌛", "")
    )
    s = re.sub(r"[\U0001F000-\U0001FFFF\U0001E000-\U0001EFFF\U00002600-\U000027BF\U0001F1E6-\U0001F1FF]", "", s)
    s = re.sub(r"\s+", " ", s).strip(" ,;:")
    return s
