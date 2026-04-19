"""Compose a full keyboard SVG from layout + key entries."""
from config import KEY_UNIT as U, KEY_HEIGHT as H, KEY_GAP as G, MOD_TO_KEYS
from layout import ROWS, get_key_id
from svg_defs import svg_defs
from svg_key import render_key
from colors import PALETTE, CATEGORY_LABELS, get_category


def render(title, layer_mods, key_entries, icon_map):
    mod_keys, all_mk = set(), set()
    for m in layer_mods: mod_keys |= MOD_TO_KEYS.get(m, set())
    for ks in MOD_TO_KEYS.values(): all_mk |= ks
    hide = all_mk - mod_keys - {"tab"}  # Tab is dual-purpose, always visible
    px, py, th, lh = 24, 20, 40, 36
    tw = sum(w for _, w, _ in ROWS[0])
    sw = px*2 + tw*U + (len(ROWS[0])-1)*G
    sh = py*2 + th + len(ROWS)*(H+G) + lh
    p = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{sw}" height="{sh}" '
         f'viewBox="0 0 {sw} {sh}">', svg_defs(),
         f'<text x="{px}" y="{py+22}" class="title">{title.replace("&","&amp;")}</text>']
    cy = py + th
    for row in ROWS:
        cx = px
        for disp, wu, kid in row:
            w = wu*U + (wu-1)*G if wu > 1 else U
            if kid in hide: cx += w+G; continue
            res = get_key_id(kid)
            im = kid in mod_keys
            e = key_entries.get(res)
            ic = icon_map.get(e.get("app","")) if e else None
            p.append(render_key(cx, cy, w, H, disp, e, ic, im))
            cx += w+G
        cy += H+G
    ly, lx = cy+8, px
    used = {get_category(e) for e in key_entries.values()}
    for cat, lab in CATEGORY_LABELS.items():
        if cat not in used: continue
        p.append(f'<rect x="{lx}" y="{ly}" width="10" height="10" rx="2" fill="{PALETTE[cat]}"/>')
        p.append(f'<text x="{lx+14}" y="{ly+9}" class="legend-text">{lab}</text>')
        lx += 14 + len(lab)*6.5 + 16
    p.append("</svg>")
    return "\n".join(p)
