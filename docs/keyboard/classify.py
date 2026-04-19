"""Group chord entries by modifier layer and map to physical keys."""
import re; from collections import defaultdict as DD
from config import MODIFIER_SYMBOLS, FKEY_MAPPING, MOD_ORDER, MIN_LAYER_ENTRIES
from labels import get_label

_KM = {"⇥":"tab","⎋":"tilde","←":"left","→":"right","↑":"up","↓":"down",",":"comma",
    ".":"period",";":"semicolon","'":"apostrophe","/":"slash","[":"bracketleft",
    "]":"bracketright","\\":"backslash","`":"tilde","~":"tilde","-":"minus","=":"equal","␣":"space"}
_f = frozenset
_T = {_f(): "Base", _f({"hyper"}): "Hyper — Apps + Navigation",
    _f({"ctrl","alt"}): "Ctrl + Alt — Window Management",
    _f({"shift","ctrl","alt"}): "Shift + Ctrl + Alt — Half-Window",
    _f({"hyper","shift"}): "Hyper + Shift — Extended Apps",
    _f({"hyper","ctrl"}): "Hyper + Ctrl — Workspaces + Scroll",
    _f({"hyper","alt"}): "Hyper + Alt — Word Operations",
    _f({"hyper","cmd"}): "Hyper + Cmd — Line Operations",
    _f({"cmd"}): "Cmd — macOS Standard", _f({"alt"}): "Alt — Special Chars + Apps",
    _f({"tab_mod"}): "Tab — Quick Actions"}

def _parse_modifiers(cs):
    mods, r = set(), cs
    if r.startswith("\u21e5") and len(r)>1 and r[1] not in "\u21ea\u21e7\u2303\u2325\u2318":
        mods.add("tab_mod"); r = r[1:]  # Tab as modifier prefix
    for sym, name in MODIFIER_SYMBOLS.items():
        if sym in r: mods.add(name); r = r.replace(sym, "")
    key = r.strip()
    if re.match(r'^F\d+$', key) and key in FKEY_MAPPING:
        key, extra = FKEY_MAPPING[key]; mods |= extra
    if re.match(r'^num\d$', key): key, mods = "space", mods | {"hyper","shift"}
    return frozenset(mods), _KM.get(key, key)


def layer_name(mods):
    if mods in _T: return _T[mods]
    n = {"hyper":"Hyper","shift":"Shift","ctrl":"Ctrl","alt":"Alt","cmd":"Cmd","tab_mod":"Tab"}
    return " + ".join(n[m] for m in MOD_ORDER if m in mods) or "Base"

def layer_filename(mods):
    p = [m for m in MOD_ORDER if m in mods]
    return "-".join(p) + ".svg" if p else "base.svg"

def classify_entries(active, comments):
    layers = DD(dict)
    for e in comments:
        mods, key = _parse_modifiers(e["chord"])
        if e.get("label","").strip("? "): layers[mods][key] = {**e, "label": e.get("label","")}
    for e in active:
        mods, key = _parse_modifiers(e["chord"])
        layers[mods][key] = {**e, "label": get_label(e)}
    return {m: k for m, k in layers.items() if len(k) >= MIN_LAYER_ENTRIES}
