"""Collect data for the detail section: fn entries and app shortcuts."""
from layout import ROWS, get_key_id

_DN = {get_key_id(k):d for r in ROWS for d,_,k in r if d}
_DN.update(space="Space", tab="Tab", **{"return":"Ret", "capslock":"\u21ea",
    "backspace":"\u232b", "bracketleft":"[", "bracketright":"]", "backslash":"\\",
    "semicolon":";", "apostrophe":"'", "comma":",", "period":".", "slash":"/",
    "tilde":"~", "minus":"\u2013", "equal":"=",
    "left":"\u2190", "right":"\u2192", "up":"\u2191", "down":"\u2193"})


def collect_fn(keys):
    out = []
    for kid, e in sorted(keys.items()):
        if not e.get("fn"): continue
        lb = e.get("label","")
        if lb and any(c.isalpha() for c in lb):
            out.append((_DN.get(kid, kid.upper() if len(kid)==1 else kid), lb, e))
    return out


def collect_app_shortcuts(descriptions, layer_mods):
    from classify import _parse_modifiers
    out = []
    for chord, sk, app, func, tip in descriptions:
        mods, _ = _parse_modifiers(chord)
        if mods == layer_mods and app:
            out.append((chord, app, func, tip))
    return out
