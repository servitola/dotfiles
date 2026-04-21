"""Render rich hover tooltips with app icons and shortcut lists."""
from svg_details import _ic, _E
from parse_brew import get_brew_desc

_LH, _PX, _PY = 18, 10, 8
_TW = 240


def group_by_key(descriptions, layer_mods):
    from classify import _parse_modifiers
    out = {}
    for chord, sk, app, func, tip in descriptions:
        mods, key = _parse_modifiers(chord)
        if mods == layer_mods and app:
            out.setdefault(key, []).append((app, func, tip))
    return out


def render_tooltip(x, y, w, h, key_descs, icon_map, brew_descs=None, entry=None):
    bd=brew_descs or {}; im=icon_map or {}; lines=[]; seen=set()
    if entry:
        app,fn=entry.get("app",""),entry.get("fn","")
        if app: lines.append((app,app,"",get_brew_desc(app,bd))); seen.add(app)
        elif fn and entry.get("label",""): lines.append(("",entry["label"],fn.replace("_"," ").replace(".",": "),""))
    for app,func,tip in (key_descs or []):
        lines.append((app,app,func,get_brew_desc(app,bd) if app not in seen else "")); seen.add(app)
    if not lines: return ""
    extra = sum(1 for _,_,_,bd in lines if bd)
    tw, th = _TW, _PY*2 + len(lines)*_LH + extra*12
    tx, ty = x+w/2-tw/2, y+h+4; ax = x+w/2
    p = [f'<g class="key-tip" opacity="0" pointer-events="none">',
         f'<rect x="{tx}" y="{ty}" width="{tw}" height="{th}" rx="10" '
         f'fill="white" stroke="#e5e5ea" stroke-width="0.5" filter="url(#shadow-card)"/>',
         f'<polygon points="{ax-5},{ty} {ax+5},{ty} {ax},{ty-5}" fill="white" stroke="#e5e5ea" stroke-width="0.5"/>',
         f'<polygon points="{ax-4},{ty} {ax+4},{ty} {ax},{ty-4}" fill="white"/>']
    ey = ty + _PY + 12
    for icon_key, title, sub, bdesc in lines:
        ic = _ic(im, icon_key) if icon_key else None; ix = tx+_PX
        if ic: p.append(f'<image x="{ix}" y="{ey-11}" width="13" height="13" href="data:image/png;base64,{ic}"/>'); ix+=16
        p.append(f'<text x="{ix}" y="{ey}" font-size="9px" font-weight="600" fill="#007aff">{_E(title)}</text>')
        if sub: p.append(f'<text x="{ix+len(title)*5.5+4}" y="{ey}" font-size="8px" fill="#1d1d1f">{_E(sub)}</text>')
        ey += _LH
        if bdesc:
            p.append(f'<text x="{tx+_PX+(16 if ic else 0)}" y="{ey-6}" font-size="7px" fill="#86868b" font-style="italic">{_E(bdesc)}</text>')
            ey += 12
    p.append('</g>'); return "\n".join(p)
