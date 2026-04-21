"""Render a single keyboard key — Apple Magic Keyboard keycap."""
from config import KEY_RADIUS as R
from colors import PALETTE as P, get_category as _cat, CATEGORY_ICONS
_E = lambda t: t.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace('"',"&quot;")
_SYM = set("←→↑↓⏮⏭⏪⏩↩⌦🔆🔅")
_BIG = {"PgUp","PgDn","Home","End","Vol ↑","Vol ↓","▶/⏸","`",*(f"F{i}" for i in range(1,13))}

def _fs(lb,w,top):
    mx=int(w/5.5)
    if top: return 8 if len(lb)>mx else (9 if len(lb)>8 else 10)
    if any(c in _SYM for c in lb): return 18
    return 14 if lb in _BIG else (7 if len(lb)>mx else (8 if len(lb)>10 else (9 if len(lb)>6 else 10)))

def _r(x,y,w,h,f,s,sw,fi):
    return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{R}" fill="{f}" stroke="{s}" stroke-width="{sw}" filter="url(#{fi})"/>'

def _txt(cx,ty,lb,c,fs):
    if len(lb)>12 and " " in lb:
        m=len(lb)//2; i=lb.find(" ",m); j=lb.rfind(" ",0,m); i=i if i>0 else j
        if i>0: return (f'<text x="{cx}" y="{ty-5}" text-anchor="middle" class="bind-label" fill="{c}" font-size="{fs}px">{_E(lb[:i])}</text>'
                        f'<text x="{cx}" y="{ty+6}" text-anchor="middle" class="bind-label" fill="{c}" font-size="{fs}px">{_E(lb[i+1:])}</text>')
    return f'<text x="{cx}" y="{ty}" text-anchor="middle" class="bind-label" fill="{c}" font-size="{fs}px">{_E(lb)}</text>'

def _tip(kd,e):
    lb,app,fn=e.get("label",""),e.get("app",""),e.get("fn","")
    if app: return f"{kd}: {app}" if app==lb else f"{kd}: {lb} ({app})"
    return f"{kd}: {lb} — {fn.replace('_',' ').replace('.', ': ').title()}" if fn else (f"{kd}: {lb}" if lb else kd)

def render_key(x,y,w,h,kd,entry,icon=None,is_mod=False,wu=1,extra=""):
    p,cx,cy=['<g class="key-group">'],x+w/2,y+h/2
    if is_mod:
        bg="#d4e4f7" if not entry else P["key_bg_bound"]; bc="#007aff" if not entry else P["key_border"]
        p.append(_r(x,y,w,h,bg,bc,"1","shadow-bound"))
        if entry:
            c,lb=P.get(_cat(entry),P["app"]),entry.get("label",""); p.append(_txt(cx,cy+1,lb,c,_fs(lb,w,False)))
            p.append(f'<text x="{x+w-5}" y="{y+h-5}" text-anchor="end" class="key-label" fill="#007aff">{_E(kd)}</text>')
        else: p.append(f'<text x="{cx}" y="{cy+4}" text-anchor="middle" class="bind-label" fill="#007aff" font-size="14px" font-weight="600">{_E(kd)}</text>')
    elif entry:
        cat,c,lb=_cat(entry),P.get(_cat(entry),P["app"]),entry.get("label","")
        p+=[_r(x,y,w,h,P["key_bg_bound"],P["key_border"],"0.5","shadow-bound"),
            f'<rect x="{x}" y="{y+2}" width="3" height="{h-4}" rx="1.5" fill="{c}"/>']
        is_k=entry.get("source_tag")=="K"; ci=None if is_k else CATEGORY_ICONS.get(cat); icon=None if is_k else icon
        top=bool(icon or ci); fs=min(_fs(lb,w,top),13) if h<30 else _fs(lb,w,top)
        if icon: p.append(f'<image x="{cx-9}" y="{y+5}" width="18" height="18" href="data:image/png;base64,{icon}"/>')
        elif ci: p.append(f'<use href="#{ci}" x="{cx-7}" y="{y+4}" width="14" height="14" fill="{c}" stroke="{c}"/>')
        p.append(_txt(cx,y+33 if top else cy+(6 if fs>=14 else 4),lb,c,fs))
        if h>=30: p.append(f'<text x="{x+w-5}" y="{y+h-5}" text-anchor="end" class="key-label">{_E(kd)}</text>')
    else: p+=[_r(x,y,w,h,P["key_bg"],P["key_border_unbound"],"0.5","shadow"),
               f'<text x="{cx}" y="{cy+3}" text-anchor="middle" class="key-label">{_E(kd)}</text>']
    p+=[f'<title>{_E(_tip(kd,entry) if entry else kd)}</title>']+([extra] if extra else [])+['</g>']; return "\n".join(p)
