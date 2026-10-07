"""What each key types in the three layouts this Mac uses, for the keyboard pictures and lint rule D2.

Plain and Shift come from Apple's own layouts (apple-layouts/*.json, written by
tools/dump_apple_layouts.py) with the Spoon's `fixups` on top, since init.lua turns
`baseFixups` on. ⌥ and ⇧⌥ are what BirmanLayer.spoon types: its installed
typography_table.lua, with the `cyrillic` overlay for Russian; in the layouts init.lua lists as
`excludedLayouts` the Spoon stays out, so ⌥ and ⇧⌥ are Apple's own there.

The Lua table is read by a small reader of literal tables rather than by running Lua:
Lua is not a declared dependency of this repo, and Hammerspoon's own interpreter (`hs -c`)
needs a running Hammerspoon, which the pre-commit lint cannot count on.
"""
import copy
import json
import os
import re

_HERE = os.path.dirname(os.path.abspath(__file__))
_REPO = os.path.dirname(os.path.dirname(_HERE))
_APPLE = os.path.join(_HERE, "apple-layouts")
_INIT = os.path.join(_REPO, "hammerspoon", "init.lua")
_SPOON_TABLE = os.path.join(_REPO, "hammerspoon", "Spoons", "BirmanLayer.spoon", "typography_table.lua")

# lang -> (Apple dump, input source id), the layouts constants.env names as LAYOUT_PRIMARY/SECONDARY/TERTIARY.
_LAYOUTS = {"en": ("ABC", "com.apple.keylayout.ABC"),
            "ru": ("RussianWin", "com.apple.keylayout.RussianWin"),
            "gr": ("Greek", "com.apple.keylayout.Greek")}
_CYRILLIC = {"ru"}

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

_STATES = ("base", "shift", "option", "shift_option")
_OPTION_FIELD = {"option": "opt", "shift_option": "shift_opt"}

_TOKEN = re.compile(r"""\s+|--[^\n]*|(?P<str>"(?:\\.|[^"\\\n])*"|'(?:\\.|[^'\\\n])*')|(?P<num>\d+)
                        |(?P<name>[A-Za-z_][A-Za-z0-9_]*)|(?P<punct>[{}\[\]=,;])""", re.X)
_ESCAPE = re.compile(r"\\(u\{[0-9a-fA-F]+\}|x[0-9a-fA-F]{2}|\d{1,3}|.)", re.S)
_SIMPLE_ESCAPE = {"n": "\n", "t": "\t", "r": "\r", "a": "\a", "b": "\b", "f": "\f", "v": "\v"}


def _unescape(match):
    esc = match.group(1)
    if esc.startswith("u{"):
        return chr(int(esc[2:-1], 16))
    if esc[0] == "x":
        return chr(int(esc[1:], 16))
    if esc.isdigit():
        return chr(int(esc))
    return _SIMPLE_ESCAPE.get(esc, esc)


def _lua_string(literal):
    # Lua escapes name bytes; decoding per escape is right for everything below U+0080.
    return _ESCAPE.sub(_unescape, literal[1:-1])


def _tokens(text, path):
    pos, out = 0, []
    while pos < len(text):
        m = _TOKEN.match(text, pos)
        if not m:
            raise ValueError(f"{path}: cannot read Lua at offset {pos}: {text[pos:pos + 30]!r}")
        pos = m.end()
        if m.group("str"):
            out.append(("value", _lua_string(m.group("str"))))
        elif m.group("num"):
            out.append(("value", int(m.group("num"))))
        elif m.group("name"):
            word = m.group("name")
            out.append(("value", {"true": True, "false": False}[word]) if word in ("true", "false") else ("name", word))
        elif m.group("punct"):
            out.append(("punct", m.group("punct")))
    return out


def read_lua_table(path):
    """The value of a Lua file that is `return <literal table>`: strings, integers, booleans, tables with
    `[key] =` or `name =` fields. Anything else (code, positional entries) raises."""
    with open(path, encoding="utf-8") as fh:
        tokens = _tokens(fh.read(), path)
    pos = 0

    def take(kind, text=None):
        nonlocal pos
        if pos >= len(tokens) or tokens[pos][0] != kind or (text is not None and tokens[pos][1] != text):
            got = tokens[pos] if pos < len(tokens) else "end of file"
            raise ValueError(f"{path}: expected {text or kind}, got {got}")
        pos += 1
        return tokens[pos - 1][1]

    def value():
        nonlocal pos
        if tokens[pos][0] == "value":
            pos += 1
            return tokens[pos - 1][1]
        take("punct", "{")
        table = {}
        while tokens[pos] != ("punct", "}"):
            if tokens[pos] == ("punct", "["):
                pos += 1
                key = value()
                take("punct", "]")
            else:
                key = take("name")
            take("punct", "=")
            table[key] = value()
            if tokens[pos] in (("punct", ","), ("punct", ";")):
                pos += 1
        pos += 1
        return table

    take("name", "return")
    result = value()
    if pos != len(tokens):
        raise ValueError(f"{path}: unexpected {tokens[pos]} after the returned table")
    return result


def _is_leaf(value):
    return not isinstance(value, dict) or isinstance(value.get("dead"), str) or value.get("pass") is True


def _merge(into, overlay):
    """The Spoon's merge(): tables merge key by key, a leaf (string, false, {dead}, {pass}) replaces."""
    for key, value in overlay.items():
        if isinstance(into.get(key), dict) and not _is_leaf(into[key]) and not _is_leaf(value):
            _merge(into[key], value)
        else:
            into[key] = copy.deepcopy(value)


def _option_table(spoon, lang):
    table = {k: v for k, v in copy.deepcopy(spoon).items() if k not in ("cyrillic", "fixups")}
    if lang in _CYRILLIC and spoon.get("cyrillic"):
        _merge(table, spoon["cyrillic"])
    return table


def _typed(cell, terminators):
    """A ⌥ cell as the character it shows: a dead key shows its spacing accent, false and pass nothing."""
    if isinstance(cell, str):
        return cell
    if isinstance(cell, dict) and "dead" in cell:
        return terminators.get(cell["dead"], "")
    return ""


def _excluded_layouts():
    """The input source ids in init.lua's `layer.excludedLayouts = { ... }`."""
    with open(_INIT, encoding="utf-8") as fh:
        m = re.search(r"excludedLayouts\s*=\s*\{([^}]*)\}", fh.read())
    return set(re.findall(r'"([^"]+)"', m.group(1))) if m else set()


def _parse_one(lang, spoon, excluded=frozenset()):
    """Return {physical_key: {state: char}} for one layout."""
    dump_name, source = _LAYOUTS[lang]
    with open(os.path.join(_APPLE, f"{dump_name}.json"), encoding="utf-8") as fh:
        apple = json.load(fh)
    fixups = spoon.get("fixups", {}).get(source, {})
    table = _option_table(spoon, lang)
    result = {}
    for code, phys in _CODE.items():
        chars = {layer: apple[layer].get(str(code), "") for layer in ("base", "shift")}
        for layer, fixed in fixups.get(code, {}).items():
            chars[layer] = fixed or ""
        row = table.get("keys", {}).get(code, {})
        for state, field in _OPTION_FIELD.items():
            chars[state] = (apple[state].get(str(code), "") if source in excluded
                            else _typed(row.get(field), table.get("terminators", {})))
        for state, out in chars.items():
            if out and ord(out[0]) >= 32:
                result.setdefault(phys, {})[state] = out
    return result


def parse_birman():
    """Return {physical_key: {state: (en, ru, gr)}} for the three layouts."""
    spoon, excluded = read_lua_table(_SPOON_TABLE), _excluded_layouts()
    per_lang = {lang: _parse_one(lang, spoon, excluded) for lang in _LAYOUTS}
    result = {}
    for key in set().union(*per_lang.values()):
        result[key] = {}
        for state in _STATES:
            en, ru, gr = (per_lang[lang].get(key, {}).get(state, "") for lang in ("en", "ru", "gr"))
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
