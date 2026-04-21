"""Compose SVG: title, Apple silver keyboard body, trackpad-style detail card."""
from config import KEY_UNIT as U, KEY_HEIGHT as H, KEY_GAP as G, MOD_TO_KEYS, DEFAULT_APPS
from layout import ROWS, get_key_id, trackpad_bounds
from svg_defs import svg_defs; from svg_key import render_key
from detail_data import collect_fn, collect_app_shortcuts; from labels import FN_APP
from svg_details import estimate_height, render as render_det
from svg_tooltip import group_by_key, render_tooltip as rtip
from colors import PALETTE as PL, CATEGORY_LABELS, get_category

_HIDE = {"shift_r"}
def _icon(e, im):
    a=e.get("app",""); fn=e.get("fn","")
    if a and a in im: return im[a]
    if fn and fn in FN_APP: return im.get(DEFAULT_APPS.get(FN_APP[fn],FN_APP[fn]))
    return im.get(e.get("app_hint","")) if e.get("app_hint") else None

def render(title, mods, keys, im, descriptions=None, brew_descs=None):
    mk={k for m in mods for k in MOD_TO_KEYS.get(m,set())}; hide=({k for ks in MOD_TO_KEYS.values() for k in ks}-mk-{"tab"})|_HIDE
    px,py,bd = 28,24,brew_descs or {}
    ds=descriptions or []; fn_det=collect_fn(keys); app_det=collect_app_shortcuts(ds,mods) if ds else []
    tips=group_by_key(ds,mods) if ds else {}
    sw=px*2+max(sum(wu*(U+G) for _,wu,_ in r)-G for r in ROWS); t=title.replace("&","&amp;")
    kb_pad,kb_y = 10, py+28; kb_h = len(ROWS)*(H+G)+kb_pad*2-G
    dh=estimate_height(fn_det,app_det,px,sw-px); sh=kb_y+kb_h+16+max(40,40+dh)+16
    p=[f'<svg xmlns="http://www.w3.org/2000/svg" width="{sw}" height="{sh}" viewBox="0 0 {sw} {sh}">',
       svg_defs(),f'<rect width="{sw}" height="{sh}" fill="none"/>',
       f'<text x="{px}" y="{py+6}" class="title">{t}</text>',
       f'<rect x="4" y="{kb_y}" width="{sw-8}" height="{kb_h}" rx="14" fill="{PL["kb_bg"]}" stroke="{PL["kb_border"]}" stroke-width="0.5"/>']
    cy = kb_y+kb_pad
    for row in ROWS:
        cx = px
        for d,wu,kid in row:
            w=wu*U+(wu-1)*G if wu>1 else U
            if kid in hide: cx+=w+G; continue
            if kid=="updown":
                hh=(H-G)//2
                for i,(sym,k2) in enumerate([("\u2191","up"),("\u2193","down")]):
                    e=keys.get(k2);ic=_icon(e,im) if e else None;yy=cy+i*(hh+G)
                    p.append(render_key(cx,yy,w,hh,sym,e,ic,0,wu,rtip(cx,yy,w,hh,tips.get(k2,[]),im,bd,e)))
            else:
                k2=get_key_id(kid);e=keys.get(k2);ic=_icon(e,im) if e else None
                p.append(render_key(cx,cy,w,H,d,e,ic,kid in mk,wu,rtip(cx,cy,w,H,tips.get(k2,[]),im,bd,e)))
            cx+=w+G
        cy+=H+G
    x1,x2=trackpad_bounds(px,U,G)
    tp_y=kb_y+kb_h+12; tp_h=max(36,36+dh); lx=x1+12; ly=tp_y+14; KB=PL["kb_bg"]; BD=PL["kb_border"]
    p.append(f'<rect x="{x1}" y="{tp_y}" width="{x2-x1}" height="{tp_h}" rx="12" fill="{KB}" stroke="{BD}" stroke-width="0.5" filter="url(#shadow-card)"/>')
    for c,l in ((c,l) for c,l in CATEGORY_LABELS.items() if c in {get_category(e) for e in keys.values()}):
        p+=[f'<circle cx="{lx+5}" cy="{ly}" r="4" fill="{PL[c]}"/>',f'<text x="{lx+14}" y="{ly+4}" class="legend-text">{l}</text>']; lx+=14+len(l)*6.2+18
    p.extend(render_det(fn_det,app_det,x1+8,x2-8,ly+10,im)); p.append("</svg>"); return "\n".join(p)
