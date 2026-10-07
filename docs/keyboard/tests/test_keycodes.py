import itertools
import os
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import keycodes
from config import KEY_DISPLAY, MOD_DISPLAY
from parse_karabiner import _KEY_SYM

PLAIN_MODS = ("shift", "ctrl", "alt", "cmd")
MOD_SETS = [c for n in range(5) for c in itertools.combinations(PLAIN_MODS, n)]
VOCAB = sorted(keycodes.KEYCODE)


def chords(keys, with_fn=False):
    for key in keys:
        for mods in MOD_SETS:
            yield keycodes.render(mods, key)
            if with_fn and key not in keycodes.IMPLICIT_FN:
                yield keycodes.render(("fn", *mods), key)


def test_modifier_glyphs_are_the_repo_ones():
    for m in PLAIN_MODS:
        assert keycodes.MOD_GLYPH[m] == MOD_DISPLAY[m]
    assert keycodes.HYPER == MOD_DISPLAY["hyper"]


def test_every_repo_key_glyph_has_a_key_code():
    glyphs = set(KEY_DISPLAY.values()) | {g for code, g in _KEY_SYM.items()}
    for g in glyphs:
        assert keycodes.canonical(g)


@pytest.mark.parametrize("keys", list(chords(VOCAB)))
def test_carbon_round_trip(keys):
    assert keycodes.carbon_to_chord(*keycodes.chord_to_carbon(keys)) == keys


@pytest.mark.parametrize("keys", list(chords(VOCAB, with_fn=True)))
def test_symbolic_round_trip(keys):
    assert keycodes.symbolic_to_chord(keycodes.chord_to_symbolic(keys)) == keys


@pytest.mark.parametrize("keys", list(chords(sorted(keycodes.MENU_CHAR))))
def test_menu_round_trip(keys):
    assert keycodes.menu_combo_to_chord(keycodes.chord_to_menu_combo(keys)) == keys


@pytest.mark.parametrize("keys, carbon", [
    ("⇧⌘4", (21, 768)), ("⇧⌃⌘4", (21, 4864)), ("⇧⌥1", (18, 2560)), ("⌥⌘1", (18, 2304)), ("⌥F19", (80, 2048)),
    ("⌃␣", (49, 4096)), ("⌘e", (14, 256)),
])
def test_carbon_known_values(keys, carbon):
    assert keycodes.chord_to_carbon(keys) == carbon


@pytest.mark.parametrize("params, keys", [
    ([52, 21, 1179648], "⇧⌘4"),
    ([51, 20, 1441792], "⇧⌃⌘3"),
    ([65535, 120, 8650752], "⌃F2"),
    ([65535, 107, 8388608], "F14"),
    ([32, 49, 786432], "⌃⌥␣"),
    ([47, 44, 1179648], "⇧⌘/"),
    ([113, 12, 8388608], "🌐q"),
    ([102, 3, 8650752], "🌐⌃f"),
    ([65535, 53, 1048576], "⌘⎋"),
    ([65535, 123, 10747904], "⌃←"),
    ([65535, 65535, 0], ""),
])
def test_symbolic_live_values(params, keys):
    assert keycodes.symbolic_to_chord(params) == keys


def test_symbolic_encoding_matches_what_macos_stores():
    assert keycodes.chord_to_symbolic("⇧⌘4") == [52, 21, 1179648]
    assert keycodes.chord_to_symbolic("⌃F2") == [65535, 120, 8650752]
    assert keycodes.chord_to_symbolic("⌃␣") == [32, 49, 262144]
    assert keycodes.chord_to_symbolic("") == [65535, 65535, 0]


@pytest.mark.parametrize("combo, keys", [
    ("~@e", "⌥⌘e"), ("@~a", "⌥⌘a"), ("@$p", "⇧⌘p"), ("^~@r", "⌃⌥⌘r"),
    ("@…", None), ("@\uf702", "⌘←"), ("@$\U00002190", "⇧⌘←"),
])
def test_menu_combo_decoding(combo, keys):
    if keys is None:
        with pytest.raises(ValueError):
            keycodes.menu_combo_to_chord(combo)
    else:
        assert keycodes.menu_combo_to_chord(combo) == keys


def test_hyper_and_alias_normalise():
    assert keycodes.canonical("⇪b") == "⇧⌃⌥⌘b"
    assert keycodes.canonical("⌥~") == "⌥`"


@pytest.mark.parametrize("bad, fn", [
    ("⌘Q", keycodes.parse), ("⌘⇧4", keycodes.parse), ("🌐F1", keycodes.parse),
    ("🌐q", keycodes.chord_to_carbon), ("🌐q", keycodes.chord_to_menu_combo),
    ("num1", keycodes.chord_to_menu_combo),
])
def test_hard_errors_name_the_glyph(bad, fn):
    with pytest.raises(ValueError, match="`"):
        fn(bad)


def test_unknown_carbon_code_is_an_error():
    with pytest.raises(ValueError):
        keycodes.carbon_to_chord(200, 256)
    with pytest.raises(ValueError):
        keycodes.carbon_to_chord(0, 1)


KVK = {
    "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9, "b": 11,
    "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19, "3": 20, "4": 21,
    "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28, "0": 29, "]": 30, "o": 31,
    "u": 32, "[": 33, "i": 34, "p": 35, "↩": 36, "l": 37, "j": 38, "'": 39, "k": 40, ";": 41,
    "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47, "⇥": 48, "␣": 49, "`": 50, "⌫": 51,
    "⎋": 53, "F1": 122, "F2": 120, "F3": 99, "F4": 118, "F5": 96, "F6": 97, "F7": 98, "F8": 100,
    "F9": 101, "F10": 109, "F11": 103, "F12": 111, "F13": 105, "F14": 107, "F15": 113,
    "F16": 106, "F17": 64, "F18": 79, "F19": 80, "F20": 90, "←": 123, "→": 124, "↓": 125,
    "↑": 126, "PgUp": 116, "PgDn": 121, "⌦": 117, "↖": 115, "↘": 119,
}


@pytest.mark.parametrize("glyph, code", KVK.items())
def test_key_code_is_the_carbon_kvk_constant(glyph, code):
    assert keycodes.KEYCODE[glyph] == code
