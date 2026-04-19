"""Compose a full keyboard SVG from layout + key entries."""
from config import KEY_UNIT as U, KEY_HEIGHT as H, KEY_GAP as G, MOD_TO_KEYS, DEFAULT_APPS
from layout import ROWS, get_key_id
from svg_defs import svg_defs
from svg_key import render_key
from colors import PALETTE, CATEGORY_LABELS, get_category
from labels import FN_APP

def _resolve_icon(e, im):
    app = e.get("app","")
    if app and app in im: return im[app]
    fn = e.get("fn","")
    if fn and fn in FN_APP:
        r = DEFAULT_APPS.get(FN_APP[fn], FN_APP[fn])
        if r in im: return im[r]
    h = e.get("app_hint","")
    return im.get(h) if h else None

def render(title, layer_mods, key_entries, icon_map):
    mk, amk = set(), set()
    for m in layer_mods: mk |= MOD_TO_KEYS.get(m, set())
    for ks in MOD_TO_KEYS.values(): amk |= ks
    hide = amk - mk - {"tab"}
    px, py, th, lh = 24, 20, 40, 36
    tw = sum(w for _,w,_ in ROWS[0])
    sw, sh = px*2+tw*U+(len(ROWS[0])-1)*G, py*2+th+len(ROWS)*(H+G)+lh
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{sw}" height="{sh}" viewBox="0 0 {sw} {sh}">',
         svg_defs(), f'<rect width="{sw}" height="{sh}" rx="16" fill="white" fill-opacity="0.92"/>',
         f'<text x="{px}" y="{py+22}" class="title">{title.replace("&","&amp;")}</text>']
    cy = py+th
    for row in ROWS:
        cx = px
        for d, wu, kid in row:
            w = wu*U+(wu-1)*G if wu>1 else U
            if kid in hide: cx += w+G; continue
            e = key_entries.get(get_key_id(kid))
            ic = _resolve_icon(e, icon_map) if e else None
            p.append(render_key(cx, cy, w, H, d, e, ic, kid in mk, wu))
            cx += w+G
        cy += H+G
    ly, lx = cy+8, px
    used = {get_category(e) for e in key_entries.values()}
    for cat, lab in CATEGORY_LABELS.items():
        if cat not in used: continue
        p.append(f'<rect x="{lx}" y="{ly}" width="10" height="10" rx="2" fill="{PALETTE[cat]}"/>')
        p.append(f'<text x="{lx+14}" y="{ly+9}" class="legend-text">{lab}</text>')
        lx += 14+len(lab)*6.5+16
    p.append("</svg>")
    return "\n".join(p)
