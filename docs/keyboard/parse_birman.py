"""Parse Birman .keylayout XML files to extract real character mappings."""
import os, re

_DIR = os.path.join(os.path.dirname(__file__), "..", "..", "keyboard-layout",
                    "Birman.bundle", "Contents", "Resources")
_LAYOUTS = [("En Birman.keylayout", "en"), ("Ru Birman.keylayout", "ru"),
            ("Gr Birman.keylayout", "gr")]

# macOS key codes → physical key names (matching config.BUTTON_FILES)
_CODE = {
    0:"a", 1:"s", 2:"d", 3:"f", 4:"h", 5:"g", 6:"z", 7:"x", 8:"c", 9:"v",
    10:"tilde", 11:"b", 12:"q", 13:"w", 14:"e", 15:"r", 16:"y", 17:"t",
    18:"1", 19:"2", 20:"3", 21:"4", 22:"6", 23:"5", 24:"equal", 25:"9",
    26:"7", 27:"minus", 28:"8", 29:"0", 30:"bracketright", 31:"o", 32:"u",
    33:"bracketleft", 34:"i", 35:"p", 37:"l", 38:"j", 39:"apostrophe",
    40:"k", 41:"semicolon", 42:"backslash", 43:"comma", 44:"slash",
    45:"n", 46:"m", 47:"period", 49:"space",
}

# Modifier layers → keyMap indices.
# Index 1 = shift, 3 = option, 4 = shift+option across all three.
# Base index varies per layout (detected via _find_base_idx).
_STATES = {"base": None, "shift": "1", "option": "3", "shift_option": "4"}

_KM_RE = re.compile(r'<keyMap index="(\d+)">(.*?)</keyMap>', re.S)
_KEY_RE = re.compile(r'<key code="(\d+)"\s+(?:output="([^"]*)"|action="([^"]+)")')
_ACT_RE = re.compile(r'<action id="([^"]+)">(.*?)</action>', re.S)
_WHEN_RE = re.compile(r'<when state="none"\s+(?:output="([^"]*)"|next="([^"]+)")')
_TERM_RE = re.compile(r'<when state="([^"]+)"\s+output="([^"]*)"')
_DEF_RE = re.compile(r'defaultIndex="(\d+)"')
_SET_RE = re.compile(r'keyMapSet id="([^"]+)"')
_ENT = re.compile(r'&#x([0-9a-fA-F]+);')


def _decode(s):
    return _ENT.sub(lambda m: chr(int(m.group(1), 16)), s) if s else ""


_MOD_BASE = re.compile(r'<keyMapSelect mapIndex="(\d+)">\s*<modifier keys="(command\?|)"/>', re.S)


def _find_base_idx(content):
    """Find base keyMap index from modifierMap: keys="" (no mods) or keys="command?" (optional cmd).
    Falls back to defaultIndex."""
    m = _MOD_BASE.search(content)
    if m: return m.group(1)
    dm = _DEF_RE.search(content)
    return dm.group(1) if dm else "0"


def _parse_one(path):
    """Return {physical_key: {state: char}} for one keylayout file."""
    with open(path, encoding="utf-8") as f:
        content = f.read()
    # Find base index from modifierMap
    base_idx = _find_base_idx(content)
    # Find first keyMapSet id
    sm = _SET_RE.search(content)
    if not sm: return {}
    sid = sm.group(1)
    chunk = content.split(f'<keyMapSet id="{sid}">')[1].split("</keyMapSet>")[0]
    # Build actions → output (resolve dead keys via terminators)
    actions = {}
    terms = {}
    for m in _TERM_RE.finditer(content.split("<terminators>")[-1] if "<terminators>" in content else ""):
        terms[m.group(1)] = _decode(m.group(2))
    for m in _ACT_RE.finditer(content):
        wm = _WHEN_RE.search(m.group(2))
        if not wm: continue
        out = _decode(wm.group(1)) if wm.group(1) is not None else terms.get(wm.group(2), "")
        if out: actions[m.group(1)] = out
    # base_idx found from modifierMap above
    # Extract per-state per-key
    result = {}
    state_indices = {s: (idx if idx else base_idx) for s, idx in _STATES.items()}
    for state, idx in state_indices.items():
        for km in _KM_RE.finditer(chunk):
            if km.group(1) != idx: continue
            for k in _KEY_RE.finditer(km.group(2)):
                code = int(k.group(1))
                if code not in _CODE: continue
                phys = _CODE[code]
                out = _decode(k.group(2)) if k.group(2) is not None else actions.get(k.group(3), "")
                if out and ord(out[0]) >= 32:
                    result.setdefault(phys, {})[state] = out
    return result


def parse_birman():
    """Return {physical_key: {state: (en, ru, gr)}} from all three keylayout files."""
    per_lang = {}
    for fname, lang in _LAYOUTS:
        path = os.path.join(_DIR, fname)
        if os.path.exists(path):
            per_lang[lang] = _parse_one(path)
    # Merge into combined
    all_keys = set()
    for d in per_lang.values():
        all_keys |= d.keys()
    result = {}
    for key in all_keys:
        result[key] = {}
        for state in _STATES:
            en = per_lang.get("en", {}).get(key, {}).get(state, "")
            ru = per_lang.get("ru", {}).get(key, {}).get(state, "")
            gr = per_lang.get("gr", {}).get(key, {}).get(state, "")
            if en or ru or gr:
                result[key][state] = (en, ru, gr)
    return result


# Map generator layer modifiers → birman state name
LAYER_TO_STATE = {
    frozenset(): "base",
    frozenset({"shift"}): "shift",
    frozenset({"alt"}): "option",
    frozenset({"shift", "alt"}): "shift_option",
}
