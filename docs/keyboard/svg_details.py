"""Render unified detail table below keyboard: full signal chain per key."""
from colors import PALETTE, get_category; from config import DEFAULT_APPS
from icons import icon_slug
_E = lambda t: t.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
_AL = {"VSCode":"Visual Studio Code","IINA":"Iina","WorkBot":"Workbot",
    "Claude Code":"Claude","Activity Manager":"Activity Monitor","GoogleMeets":"zoom.us",
    "YouTube":"_browser","Browser":"_browser","Browser Vim":"_browser",
    "Unix Terminal":"_terminal","Terminal":"_terminal",
    "Shotr":"Shottr","maccy":"Maccy","Warp":"Warp"}
_RH = 24  # row height (was 20)
_SEP = 6  # extra gap between key groups
_KC = PALETTE["karabiner"]; _BC = PALETTE["birman"]; _AC = PALETTE["app"]
_GC = PALETTE["macos"]; _TC = "#1d1d1f"; _DC = "#48484a"; _SC = "#d1d1d6"

def _ic(im, app):
    """Resolve an app reference to a canonical icon name (used for <use href="#icon-…">).

    Returns the icon-map key if present, else None. (Was returning base64 payload
    before the icon-dedup refactor; now returns the name so renderers can
    reference the <symbol> baked into <defs> by svg_defs().)
    """
    a = _AL.get(app, app)
    target = DEFAULT_APPS.get(a, a) if a.startswith("_") else a
    if target in im: return target
    if app in im: return app
    return None


def estimate_height(rows):
    """Estimate table height accounting for multi-line descriptions and separators."""
    if not rows: return 0
    h = 28  # header + gap
    prev_key = ""
    for r in rows:
        nd = len(r.get("descriptions", []))
        h += _RH * max(1, nd)
        if r["key_display"] and prev_key:
            h += _SEP  # separator between key groups
        if r["key_display"]: prev_key = r["key_display"]
    return h + 10


def render(rows, px, sw, sy, im=None):
    """Render single unified table: Key → Karabiner → Birman → Hammerspoon → App Shortcuts."""
    if not rows: return []
    im = im or {}
    has_k = sum(1 for r in rows if r["karabiner"]) >= 3
    has_b = sum(1 for r in rows if r["birman"]) >= 3
    # Adaptive column x-positions — generous spacing
    x0 = px
    xk = x0 + 36
    xb = (xk + 80) if has_k else xk
    xa = (xb + 110) if has_b else xb
    xd = xa + 155
    p = [f'<line x1="{px}" y1="{sy+4}" x2="{sw}" y2="{sy+4}" stroke="{_SC}" stroke-width="0.5"/>']
    # Header row
    dy = sy + 18
    p.append(f'<text x="{x0}" y="{dy}" font-size="11px" font-weight="600" fill="{_DC}">Key</text>')
    if has_k: p.append(f'<text x="{xk}" y="{dy}" font-size="11px" font-weight="600" fill="{_KC}">Karabiner</text>')
    if has_b: p.append(f'<text x="{xb}" y="{dy}" font-size="11px" font-weight="600" fill="{_BC}">Birman</text>')
    p.append(f'<text x="{xa}" y="{dy}" font-size="11px" font-weight="600" fill="{_AC}">Hammerspoon</text>')
    p.append(f'<text x="{xd}" y="{dy}" font-size="11px" font-weight="600" fill="{_DC}">App Shortcuts</text>')
    dy += _RH + 2
    # Separator line under header
    p.append(f'<line x1="{px}" y1="{dy-_RH+6}" x2="{sw}" y2="{dy-_RH+6}" stroke="{_SC}" stroke-width="0.3"/>')
    prev_key = ""
    for r in rows:
        # Separator line between key groups
        if r["key_display"] and prev_key:
            p.append(f'<line x1="{px}" y1="{dy-2}" x2="{sw}" y2="{dy-2}" stroke="{_SC}" stroke-width="0.3" stroke-dasharray="2,2"/>')
            dy += _SEP
        if r["key_display"]: prev_key = r["key_display"]
        row_y = dy
        # Key name — large, bold
        if r["key_display"]:
            p.append(f'<text x="{x0}" y="{dy}" font-size="13px" font-weight="700" fill="{_TC}">{_E(r["key_display"])}</text>')
        # Karabiner output
        if has_k and r["karabiner"]:
            p.append(f'<text x="{xk}" y="{dy}" font-size="12px" fill="{_KC}">{_E(r["karabiner"])}</text>')
        # Birman chars (en  ru  gr)
        if has_b and r["birman"]:
            p.append(f'<text x="{xb}" y="{dy}" font-size="12px" fill="{_BC}">{_E(r["birman"])}</text>')
        # Hammerspoon action with app icon
        if r["hs_action"]:
            ic = _ic(im, r["hs_app"]) if r["hs_app"] else None
            ax = xa + (20 if ic else 0)
            if ic: p.append(f'<use href="#icon-{icon_slug(ic)}" x="{xa}" y="{dy-13}" width="16" height="16"/>')
            cat_c = PALETTE.get(r.get("hs_category", "app"), _AC)
            p.append(f'<text x="{ax}" y="{dy}" font-size="12px" font-weight="500" fill="{cat_c}">{_E(r["hs_action"])}</text>')
        elif r["is_global"]:
            p.append(f'<text x="{xa}" y="{dy}" font-size="11px" fill="{_GC}">macOS</text>')
        # App shortcuts — one per line, with icons
        descs = r.get("descriptions", [])
        if descs:
            for j, (app, func) in enumerate(descs):
                yd = row_y + j * _RH
                dx = xd
                ic = _ic(im, app) if app else None
                if ic:
                    p.append(f'<use href="#icon-{icon_slug(ic)}" x="{dx}" y="{yd-12}" width="14" height="14"/>')
                    dx += 18
                txt = f"{app} — {func}" if app else func
                max_chars = int((sw - dx) / 5.5)
                if len(txt) > max_chars: txt = txt[:max_chars-1] + "…"
                p.append(f'<text x="{dx}" y="{yd}" font-size="11px" fill="{_DC}">{_E(txt)}</text>')
            dy = row_y + max(1, len(descs)) * _RH
        else:
            dy += _RH
    return p
