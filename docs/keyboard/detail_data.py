"""Collect data for the unified detail table: full signal chain per key."""
from layout import ROWS, get_key_id
from config import BUTTON_FILES
from labels import FN_LABELS, FN_APP
from colors import get_category

_DN = {get_key_id(k):d for r in ROWS for d,_,k in r if d}
_DN.update(space="Space", tab="Tab", **{"return":"Ret", "capslock":"\u21ea",
    "backspace":"\u232b", "bracketleft":"[", "bracketright":"]", "backslash":"\\",
    "semicolon":";", "apostrophe":"'", "comma":",", "period":".", "slash":"/",
    "tilde":"~", "minus":"\u2013", "equal":"=",
    "left":"\u2190", "right":"\u2192", "up":"\u2191", "down":"\u2193"})


def _dn(k): return _DN.get(k, k.upper() if len(k)==1 else k)


def collect_full_rows(layer_mods, keys, full_entries, birman_data=None, karabiner_data=None, rider_data=None):
    """Return rows for unified detail table.
    Each row: {key_display, chord, karabiner, birman, is_global, hs_action, hs_app,
               hs_category, descriptions}. Ordered by keyboard position.
    Uses real Karabiner rules and Birman keylayout data as source of truth."""
    from classify import _parse_modifiers
    from parse_birman import LAYER_TO_STATE
    birman_state = LAYER_TO_STATE.get(layer_mods)
    by_key = {}
    for e in full_entries:
        mods, _ = _parse_modifiers(e["chord"])
        if mods != layer_mods: continue
        sk = e["source_key"]
        has_data = e["karabiner"] or e["birman"] or e["descriptions"]
        if not has_data: continue
        by_key.setdefault(sk, []).append(e)
    # Add active-only entries (no comment counterpart in this layer)
    for kid, active in keys.items():
        if kid not in by_key and (active.get("app") or active.get("fn")):
            by_key[kid] = [{"chord": active.get("chord",""), "source_key": kid,
                "karabiner":"", "birman":"", "is_global":False, "descriptions":[]}]
    # Also add keys that have Karabiner remaps but no comment entries
    if karabiner_data:
        for (lm, phys), display in karabiner_data.items():
            if lm == layer_mods and phys not in by_key and phys in set(BUTTON_FILES):
                by_key[phys] = [{"chord":"", "source_key":phys,
                    "karabiner":"", "birman":"", "is_global":False, "descriptions":[]}]
    # Build rows ordered by keyboard position
    rows = []
    for kn in BUTTON_FILES:
        if kn not in by_key: continue
        active = keys.get(kn, {})
        hs = ""
        hs_app = ""
        hs_cat = "app"
        if active.get("app"):
            hs = active["app"] + " — show/hide"; hs_app = active["app"]; hs_cat = get_category(active)
        elif active.get("fn"):
            hs = FN_LABELS.get(active["fn"], active["fn"])
            hs_app = FN_APP.get(active["fn"], "")
            hs_cat = get_category(active)
        for i, e in enumerate(by_key[kn]):
            # Karabiner: prefer real parsed rules, fall back to comment
            kar = ""
            if karabiner_data:
                kar = karabiner_data.get((layer_mods, kn), "")
            if not kar:
                kar = e["karabiner"]
            # Birman: real keylayout data when Karabiner doesn't intercept
            bir = ""
            if not kar and birman_data and birman_state and kn in birman_data:
                chars = birman_data[kn].get(birman_state)
                if chars:
                    en, ru, gr = chars
                    bir = f"{en}  {ru}  {gr}".strip()
            if not bir:
                bir = e["birman"]
            # Merge Rider shortcuts from real keymap into descriptions
            descs = list(e["descriptions"])
            if rider_data and i == 0:
                rider_entries = rider_data.get((layer_mods, kn), [])
                for app, name in rider_entries:
                    if not any(d[0] == "Rider" and d[1] == name for d in descs):
                        descs.append((app, name))
            rows.append({"key_display": _dn(kn) if i == 0 else "",
                "chord": e["chord"], "karabiner": kar,
                "birman": bir, "is_global": e["is_global"],
                "hs_action": hs if i == 0 else "",
                "hs_app": hs_app if i == 0 else "",
                "hs_category": hs_cat if i == 0 else "app",
                "descriptions": descs})
    return rows
