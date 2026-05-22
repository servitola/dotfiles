"""Render `by-action.svg` — all active bindings grouped by category.

Companion to the per-layer SVGs in this directory: those answer
«what does key X do?», this one answers «how do I trigger action Y?».

Layout: stacked panels, one per category (Apps, Window Mgmt, Media/Audio,
Navigation, Browser/Translate, System). Each row visualises the chord as
a sequence of macOS-style key caps separated by `+`, followed by an arrow
and the action label with its app icon.
"""
import re
from collections import defaultdict
from config import KEY_RADIUS, MOD_DISPLAY, MOD_ORDER, DEFAULT_APPS, FKEY_MAPPING, KEY_DISPLAY
from labels import get_label, FN_APP
from colors import PALETTE as PL, CATEGORY_LABELS, get_category
from icons import icon_slug
from svg_defs import svg_defs
from classify import _parse_modifiers
from svg_details import _AL


# ─── chord humanisation ────────────────────────────────────────────────────
_SYM_TO_MOD = {"⇪": "hyper", "⇧": "shift", "⌃": "ctrl", "⌥": "alt", "⌘": "cmd"}
_CANONICAL_MOD_ORDER = ("hyper", "shift", "ctrl", "alt", "cmd")
_FKEY_RE = re.compile(r'^([⇪⇧⌃⌥⌘]*)(F\d+|num\d+)$')


def human_chord(active_chord):
    """Translate a Karabiner-emitted active chord to what the user physically presses.

    Example:  `F15` → `⇪⇧f` (Hyper+Shift+f, which Karabiner remaps to F15).
              `num1` → `⇧⌃⌥⌘h` (all four LEFT modifiers + h).
              `⇧F17` → `⇪⇧r` (Hyper+Shift+r).

    Pass-through for plain chords like `⇪h`, `⌃⌥a` etc.
    """
    # 1) Direct match — `F13`, `⇧F13`, `num1`, … live as full strings in FKEY_MAPPING
    mapping = FKEY_MAPPING.get(active_chord)
    if mapping is None:
        # 2) Strip explicit modifier prefix, look up base F-key — e.g. `⇧F17` → F17 + extra ⇧
        m = _FKEY_RE.match(active_chord)
        if not m: return active_chord
        prefix, base = m.group(1), m.group(2)
        base_mapping = FKEY_MAPPING.get(base)
        if base_mapping is None: return active_chord
        src_key, base_mods = base_mapping
        extra = {_SYM_TO_MOD[c] for c in prefix}
        mapping = (src_key, base_mods | extra)
    src_key, src_mods = mapping
    mods_str = "".join(MOD_DISPLAY[m] for m in _CANONICAL_MOD_ORDER if m in src_mods)
    key_str = KEY_DISPLAY.get(src_key, src_key)
    return mods_str + key_str


# ─── geometry ──────────────────────────────────────────────────────────────
PAD_X        = 28        # outer left/right padding
PAD_Y        = 24        # outer top padding
PANEL_GAP    = 18        # vertical gap between category panels
PANEL_PAD_X  = 20        # left/right padding inside a panel
PANEL_HDR_H  = 38        # height of the category header inside a panel
ROW_H        = 30        # height of one binding row
CHORD_LEFT   = 30        # x offset (from panel left) where chord starts
ARROW_X      = 220       # x offset where the `→` glyph lives
ACTION_X     = 250       # x offset where the action label starts
PAGE_W       = 980       # total page width

# Modifier glyph priority for key-cap rendering: hyper first, then others.
_MOD_SYMS = "⇪⇧⌃⌥⌘⇥"

# Categories rendered, in this order. Skip "macos" / "birman" / "karabiner"
# tag-only entries — those describe inputs, not user-triggered actions.
PANEL_ORDER = ("app", "window", "media", "nav", "browser", "system")


# ─── key-cap renderer ──────────────────────────────────────────────────────
def _cap(x, y, w, h, label, color, mod=False):
    """Render a single key cap: rounded rect + centred glyph."""
    bg     = "#d4e4f7" if mod else PL["key_bg_bound"]
    border = color if mod else PL["key_border"]
    text   = color if mod else PL["text"]
    fs     = 13 if len(label) == 1 else 11
    return (
        f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{KEY_RADIUS}" '
        f'fill="{bg}" stroke="{border}" stroke-width="0.7"/>'
        f'<text x="{x + w/2}" y="{y + h/2 + 4}" text-anchor="middle" '
        f'font-size="{fs}px" font-weight="500" fill="{text}">'
        f'{label.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")}'
        f'</text>'
    )


def _render_chord(chord, x_left, y_center, color):
    """Render a chord like `⇪⇧h` as `[⇪]+[⇧]+[H]` key caps.

    Returns (svg_fragment, end_x).
    """
    parts = []
    rest = chord
    # Pull modifier symbols off the front
    while rest and rest[0] in _MOD_SYMS:
        parts.append((rest[0], True))
        rest = rest[1:]
    if rest:
        parts.append((rest.upper() if len(rest) == 1 else rest, False))

    caps = []
    cap_h = 22
    cap_top = y_center - cap_h / 2
    cx = x_left
    for i, (label, is_mod) in enumerate(parts):
        if i > 0:
            caps.append(
                f'<text x="{cx + 4}" y="{y_center + 4}" '
                f'font-size="11px" fill="{PL["text_dim"]}">+</text>'
            )
            cx += 14
        # Cap width based on label width: 22 for single glyph, more for longer
        w = 22 if len(label) <= 1 else 14 + 7 * len(label)
        caps.append(_cap(cx, cap_top, w, cap_h, label, color, mod=is_mod))
        cx += w + 2
    return "\n".join(caps), cx


# ─── data shaping ──────────────────────────────────────────────────────────
def _chord_sort_key(chord):
    """Order chords inside a category by physical-key first, then modifier count.

    Groups related bindings together — e.g. `⇪b → Warp` sits next to
    `⇪⇧b → iTerm` because both use the `b` key, only the modifier differs.
    """
    rest = chord
    while rest and rest[0] in _MOD_SYMS:
        rest = rest[1:]
    physical = rest.lower() if rest else "~"  # sort empty last
    mod_count = sum(1 for c in chord if c in _MOD_SYMS)
    return (physical, mod_count, chord)


def _collect_bindings(active_entries):
    """Group all active bindings by category.

    Returns {category: [(human_chord, entry), …]} sorted by chord complexity.
    Active chord strings like `F15` / `num1` are translated to the source chord
    the user actually presses (`⇪⇧f` / `⇧⌃⌥⌘h`) via FKEY_MAPPING.
    """
    by_cat = defaultdict(list)
    seen = set()
    for e in active_entries:
        chord = human_chord(e["chord"])
        target = e.get("app") or e.get("fn") or ""
        key = (chord, target)
        if key in seen: continue
        seen.add(key)
        cat = get_category(e)
        if cat not in PANEL_ORDER: continue
        by_cat[cat].append((chord, e))
    for cat in by_cat:
        by_cat[cat].sort(key=lambda x: _chord_sort_key(x[0]))
    return by_cat


# ─── panel renderer ────────────────────────────────────────────────────────
def _icon_for_entry(e, im):
    """Resolve canonical icon name for an entry (returns slug-able name or None)."""
    app = e.get("app", "")
    if app:
        a = _AL.get(app, app)
        if a in im: return a
        if app in im: return app
    fn = e.get("fn", "")
    if fn and fn in FN_APP:
        target = DEFAULT_APPS.get(FN_APP[fn], FN_APP[fn])
        if target in im: return target
    return None


def _render_panel(cat, rows, im, x, y, w):
    """Render one category panel. Returns (svg_fragment, panel_height)."""
    color = PL.get(cat, PL["app"])
    label = CATEGORY_LABELS.get(cat, cat.title())
    panel_h = PANEL_HDR_H + len(rows) * ROW_H + 14
    p = []
    # Panel background card
    p.append(
        f'<rect x="{x}" y="{y}" width="{w}" height="{panel_h}" rx="14" '
        f'fill="{PL["kb_bg"]}" stroke="{PL["kb_border"]}" stroke-width="0.5" '
        f'filter="url(#shadow-card)"/>'
    )
    # Header: category accent stripe + label
    hdr_y = y + 22
    p.append(
        f'<circle cx="{x + PANEL_PAD_X + 6}" cy="{hdr_y - 3}" r="6" fill="{color}"/>'
    )
    p.append(
        f'<text x="{x + PANEL_PAD_X + 20}" y="{hdr_y}" font-size="14px" '
        f'font-weight="600" fill="{PL["text"]}">{label}</text>'
    )
    p.append(
        f'<text x="{x + w - PANEL_PAD_X}" y="{hdr_y}" text-anchor="end" '
        f'font-size="11px" fill="{PL["text_dim"]}">{len(rows)} bindings</text>'
    )
    # Rows
    row_y = y + PANEL_HDR_H
    prev_key = None
    for chord, entry in rows:
        cy = row_y + ROW_H / 2
        # Extract the physical key (everything after modifier prefix)
        rest = chord
        while rest and rest[0] in _MOD_SYMS:
            rest = rest[1:]
        cur_key = rest.lower() if rest else ""
        # Hairline between groups: when physical key changes, draw a faint divider
        if prev_key is not None and cur_key != prev_key:
            p.append(
                f'<line x1="{x + PANEL_PAD_X}" y1="{row_y - 1}" '
                f'x2="{x + w - PANEL_PAD_X}" y2="{row_y - 1}" '
                f'stroke="{PL["kb_border"]}" stroke-width="0.4" '
                f'stroke-dasharray="2,3"/>'
            )
        prev_key = cur_key
        # chord caps
        chord_svg, _end_x = _render_chord(chord, x + PANEL_PAD_X + CHORD_LEFT, cy, color)
        p.append(chord_svg)
        # arrow
        p.append(
            f'<text x="{x + PANEL_PAD_X + ARROW_X}" y="{cy + 4}" '
            f'font-size="13px" fill="{PL["text_dim"]}">→</text>'
        )
        # icon + action
        icon_name = _icon_for_entry(entry, im)
        ax = x + PANEL_PAD_X + ACTION_X
        if icon_name:
            slug = icon_slug(icon_name)
            p.append(
                f'<use href="#icon-{slug}" x="{ax}" y="{cy - 10}" '
                f'width="20" height="20"/>'
            )
            ax += 26
        action = get_label(entry)
        p.append(
            f'<text x="{ax}" y="{cy + 4}" font-size="13px" '
            f'font-weight="500" fill="{color}">{action}</text>'
        )
        row_y += ROW_H
    return "\n".join(p), panel_h


# ─── main entry ────────────────────────────────────────────────────────────
def render(active_entries, im, title="Keyboard Cheatsheet — by Action"):
    """Build the full by-action SVG document."""
    by_cat = _collect_bindings(active_entries)
    panels_w = PAGE_W - 2 * PAD_X
    # Compute total height
    total_h = PAD_Y + 28  # title space
    for cat in PANEL_ORDER:
        if cat not in by_cat: continue
        total_h += PANEL_HDR_H + len(by_cat[cat]) * ROW_H + 14 + PANEL_GAP
    total_h += PAD_Y

    out = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{PAGE_W}" '
        f'height="{total_h}" viewBox="0 0 {PAGE_W} {total_h}">',
        svg_defs(im),
        f'<rect width="{PAGE_W}" height="{total_h}" fill="white"/>',
        f'<text x="{PAD_X}" y="{PAD_Y + 6}" class="title">{title}</text>',
    ]
    y = PAD_Y + 28
    for cat in PANEL_ORDER:
        if cat not in by_cat: continue
        frag, h = _render_panel(cat, by_cat[cat], im, PAD_X, y, panels_w)
        out.append(frag)
        y += h + PANEL_GAP
    out.append("</svg>")
    return "\n".join(out)
