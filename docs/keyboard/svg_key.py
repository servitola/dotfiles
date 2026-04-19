"""Render a single keyboard key as SVG elements."""
from config import KEY_RADIUS as R
from colors import PALETTE as P, get_category as _cat, CATEGORY_ICONS

_E = lambda t: t.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;")
_SYM = set("←→↑↓⏮⏭⏪⏩↩⌦")
_BIG = {"PgUp","PgDn","Home","End","F1","F2","F3","F4","F5","F6",
        "F7","F8","F9","F10","F11","F12","`","Vol ↑","Vol ↓","▶/⏸"}

def _fs(lb, w, has_top):
    if has_top: return 8 if len(lb)>8 else (9 if len(lb)>6 else 10)
    if any(c in _SYM for c in lb): return 18
    if lb in _BIG: return 14
    return 7 if len(lb)>12 else (8 if len(lb)>10 else (9 if len(lb)>6 else 10))

def _rect(x,y,w,h,fill,stroke,sw,filt):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{R}" fill="{fill}" stroke="{stroke}" stroke-width="{sw}" filter="url(#{filt})"/>'

def render_key(x, y, w, h, kd, entry, icon=None, is_mod=False):
    p, cx, cy = [], x+w/2, y+h/2
    if is_mod:
        fl = "#e3f0ff" if not entry else P["key_bg_bound"]
        p.append(_rect(x,y,w,h,fl,"#007aff","1.5","shadow-bound"))
        if entry:
            c, lb = P.get(_cat(entry),P["app"]), entry.get("label","")
            p.append(f'<text x="{cx}" y="{cy+1}" text-anchor="middle" class="bind-label" fill="{c}" font-size="{_fs(lb,w,False)}px">{_E(lb)}</text>')
            p.append(f'<text x="{x+w-5}" y="{y+h-5}" text-anchor="end" class="key-label" fill="#007aff">{_E(kd)}</text>')
        else:
            p.append(f'<text x="{cx}" y="{cy+4}" text-anchor="middle" class="bind-label" fill="#007aff">{_E(kd)}</text>')
    elif entry:
        cat = _cat(entry)
        c, lb = P.get(cat,P["app"]), entry.get("label","")
        p.append(_rect(x,y,w,h,P["key_bg_bound"],P["key_border"],"0.5","shadow-bound"))
        p.append(f'<rect x="{x}" y="{y+2}" width="3" height="{h-4}" rx="1.5" fill="{c}"/>')
        cat_icon = CATEGORY_ICONS.get(cat)
        has_top = bool(icon or cat_icon)
        fs = _fs(lb, w, has_top)
        if icon:
            p.append(f'<image x="{cx-9}" y="{y+5}" width="18" height="18" href="data:image/png;base64,{icon}"/>')
        elif cat_icon:
            p.append(f'<use href="#{cat_icon}" x="{cx-7}" y="{y+4}" width="14" height="14" fill="{c}" stroke="{c}"/>')
        ty = (y + 33 if has_top else cy + (6 if fs >= 14 else 4))
        p.append(f'<text x="{cx}" y="{ty}" text-anchor="middle" class="bind-label" fill="{c}" font-size="{fs}px">{_E(lb)}</text>')
        p.append(f'<text x="{x+w-5}" y="{y+h-5}" text-anchor="end" class="key-label">{_E(kd)}</text>')
    else:
        p.append(_rect(x,y,w,h,P["key_bg"],P["key_border_unbound"],"0.5","shadow"))
        p.append(f'<text x="{cx}" y="{cy+3}" text-anchor="middle" class="key-label">{_E(kd)}</text>')
    return "\n".join(p)
