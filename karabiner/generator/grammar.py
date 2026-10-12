"""The glyph grammar of layers.toml values: `⇧⌃F13`, `↑`, `Vol↑`, `passthrough` ↔ Karabiner `to` entries."""
from keys import CONSUMER_SYM, HYPER, KEY_DISPLAY, KEY_SYM, MOD_DISPLAY, TO_PHYS

SLOT_BASES = [f"F{n}" for n in range(13, 21)]
TO_MODS = ("shift", "ctrl", "alt", "cmd")
FROM_MODS = ("tab_mod", "hyper") + TO_MODS


def _mods_text(mods):
    return "".join(MOD_DISPLAY[m] for m in FROM_MODS if m in mods)


def _split_mods(chord, allowed):
    """Leading modifier glyphs → frozenset of names, or None if out of order."""
    by_glyph = {MOD_DISPLAY[m]: m for m in allowed}
    i = 0
    while i < len(chord) and chord[i] in by_glyph:
        i += 1
    names = [by_glyph[c] for c in chord[:i]]
    if names != [m for m in allowed if m in names]:
        return None, chord[i:]
    return frozenset(names), chord[i:]


PASSTHROUGH = "passthrough"
# CONSUMER_SYM mixes both Karabiner fields and gives some glyphs two names; these
# are the ones rules 07–17 send, each in the field Karabiner expects it in.
_MEDIA_OUT = {
    "vk_consumer_previous": "key_code", "vk_consumer_next": "key_code",
    "illumination_increment": "key_code", "illumination_decrement": "key_code",
    "play_or_pause": "consumer_key_code",
    "volume_increment": "consumer_key_code", "volume_decrement": "consumer_key_code",
    "display_brightness_increment": "consumer_key_code", "display_brightness_decrement": "consumer_key_code",
    "rewind": "consumer_key_code", "fast_forward": "consumer_key_code", "mute": "consumer_key_code",
}
_LEFT = {"shift": "left_shift", "ctrl": "left_control", "alt": "left_option", "cmd": "left_command"}
_UNSIDED = {"shift": "shift", "control": "ctrl", "option": "alt", "command": "cmd"}


def _output_tokens():
    """Output token → (Karabiner field, name). Built once, checked for collisions."""
    if _output_tokens.cache is not None:
        return _output_tokens.cache
    table = {}

    def put(token, value):
        if table.setdefault(token, value) != value:
            raise AssertionError(f"output token `{token}` means both {table[token]} and {value}")

    for c in "abcdefghijklmnopqrstuvwxyz0123456789":
        put(c, ("key_code", c))
    for n in range(1, 21):
        put(f"F{n}", ("key_code", f"f{n}"))
    for n in range(10):
        put(f"num{n}", ("key_code", f"keypad_{n}"))
    # non_us_backslash shares the `~` key with grave_accent_and_tilde; rules only
    # ever send it back unchanged, which `passthrough` expresses unambiguously.
    for code, phys in TO_PHYS.items():
        if phys in KEY_DISPLAY and phys != "tilde":
            put(KEY_DISPLAY[phys], ("key_code", code))
    for code, glyph in KEY_SYM.items():
        if code != "non_us_backslash":
            put(glyph, ("key_code", code))
    for name, field in _MEDIA_OUT.items():
        put(CONSUMER_SYM[name].replace(" ", ""), (field, name))
    # The one key with no glyph of its own: it shares `~` with grave_accent_and_tilde.
    put("non_us_backslash", ("key_code", "non_us_backslash"))
    _output_tokens.cache = table
    return table


_output_tokens.cache = None


def parse_to(to):
    """`⇧⌃F13` → (frozenset({"shift", "ctrl"}), "F13").

    The key part is any output token (`↑`, `F1`, `a`, `Vol↑`, `passthrough`, …);
    `⇪` stands for the four right modifiers.
    """
    mods, base = _split_mods(to, FROM_MODS)
    if mods is None or (base not in _output_tokens() and base != PASSTHROUGH):
        raise ValueError(f"`{to}` is not ⇪⇧⌃⌥⌘ (in that order) plus one output key")
    return mods, base


def output_entry(to, from_key_code):
    """Glyph text → the Karabiner `to` entry; `passthrough` resends `from_key_code`."""
    mods, base = parse_to(to)
    field, name = ("key_code", from_key_code) if base == PASSTHROUGH else _output_tokens()[base]
    entry = {field: name}
    names = sorted((HYPER if "hyper" in mods else set()) | {_LEFT[m] for m in mods - {"hyper"}})
    if names:
        if field != "key_code":
            raise ValueError(f"`{to}`: {name} is a consumer key and takes no modifiers")
        entry["modifiers"] = names
    return entry


def render_output(entry, from_key_code):
    """Inverse of `output_entry`, or None when the entry is not one plain key."""
    if set(entry) - {"key_code", "consumer_key_code", "modifiers"}:
        return None
    raw = set(entry.get("modifiers", []))
    mods = set()
    if HYPER <= raw:
        mods.add("hyper")
        raw -= HYPER
    for m in raw:
        side, _, bare = m.rpartition("_")
        if side not in ("", "left") or bare not in _UNSIDED:
            return None
        mods.add(_UNSIDED[bare])
    if entry.get("key_code") == from_key_code:
        base = PASSTHROUGH
    else:
        field = "key_code" if "key_code" in entry else "consumer_key_code"
        by_value = {v: t for t, v in _output_tokens().items()}
        base = by_value.get((field, entry.get(field)))
        if base is None:
            return None
    return _mods_text(mods) + base
