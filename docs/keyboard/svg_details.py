"""Render unified detail table below keyboard: fn + app shortcuts."""
from colors import PALETTE, get_category; from config import DEFAULT_APPS
_E = lambda t: t.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
_AL = {"VSCode":"Visual Studio Code","IINA":"Iina","WorkBot":"Workbot",
    "Claude Code":"Claude","Activity Manager":"Activity Monitor","GoogleMeets":"zoom.us",
    "YouTube":"_browser","Browser":"_browser","Browser Vim":"_browser",
    "Unix Terminal":"_terminal","Terminal":"_terminal",
    "Shotr":"Shottr","maccy":"Maccy","Warp":"Warp"}
_RH = 26  # row height

def _ic(im,app):
    a=_AL.get(app,app)
    return im.get(DEFAULT_APPS.get(a,a) if a.startswith("_") else a) or im.get(app)

def _merge(fn, apps):
    """Merge fn entries and app shortcuts into one unified list of (chord, app, func, icon_key)."""
    rows = []
    for dn, lb, e in fn:
        app = e.get("app",""); cat_c = PALETTE.get(get_category(e), PALETTE["app"])
        rows.append((dn, lb, e.get("fn","").replace("_"," ").replace(".",": "), app or lb, cat_c))
    for chord, app, func, tip in apps:
        rows.append((chord, app, func, app, PALETTE["app"]))
    return rows

def estimate_height(fn, apps, px, mw):
    rows = _merge(fn, apps)
    return (14 + len(rows)*_RH + 12) if rows else 0

def render(fn, apps, px, sw, sy, im=None):
    rows = _merge(fn, apps)
    if not rows: return []
    im = im or {}
    p=[f'<line x1="{px}" y1="{sy+4}" x2="{sw-px}" y2="{sy+4}" stroke="#d1d1d6" stroke-width="0.5"/>']
    dy=sy+22; cx2,cx3=px+70,px+180; prev=""
    for chord, app_or_label, func, icon_key, color in rows:
        if chord!=prev: p.append(f'<text x="{px}" y="{dy}" font-size="12px" font-weight="600" fill="#1d1d1f">{_E(chord)}</text>')
        prev=chord
        ic=_ic(im,icon_key); ax=cx2+(20 if ic else 0)
        if ic: p.append(f'<image x="{cx2}" y="{dy-13}" width="17" height="17" href="data:image/png;base64,{ic}"/>')
        p+=[f'<text x="{ax}" y="{dy}" font-size="12px" font-weight="500" fill="{color}">{_E(app_or_label)}</text>',
            f'<text x="{cx3}" y="{dy}" font-size="11px" fill="#48484a">{_E(func)}</text>']
        dy+=_RH
    return p
