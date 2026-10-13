import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import bridges
import layers
from bridges import Bridge

SLOTS = {"z": "F13", "r": "F14", "f": "F15", "v": "F16", "t": "F17", "g": "F18", "b": "F19", "h": "F20"}


def test_fkey_mapping_is_bare_slots_plus_single_key_exceptions():
    expected = {base: (key, frozenset({"hyper"})) for key, base in SLOTS.items()}
    expected["num9"] = ("space", frozenset({"alt"}))
    expected.update({"num1": ("v", frozenset({"tab_mod"})), "num2": ("f", frozenset({"tab_mod"})),
                     "num3": ("t", frozenset({"tab_mod"})), "num4": ("4", frozenset({"alt"})), "num5": ("f5", frozenset())})
    assert bridges.fkey_mapping() == expected


def test_config_exposes_derived_mapping():
    import config
    assert config.FKEY_MAPPING == bridges.fkey_mapping()


def test_slot_variants_follow_the_formula():
    variants = bridges.slot_variants()
    assert variants["F16"] == "⇪v" and variants["⌘F16"] == "⇪⌘v"
    assert variants["⇧F17"] == "⇪⇧t" and variants["⇧⌥F13"] == "⇪⇧⌥z"
    assert "⌘F15" not in variants and "⌘F13" not in variants and "⌥F13" not in variants
    assert "⇧⌃F13" not in variants
    assert len(variants) == len(SLOTS) * len(layers.LAYERS) - 4


def test_every_code_the_rules_emit_is_a_slot_variant_or_an_exception():
    variants = bridges.slot_variants()
    for b in bridges.from_rules():
        if b.to in bridges.EXCEPTIONS:
            chords, rule = bridges.EXCEPTIONS[b.to]
            assert (b.from_chord, b.rule) in {(c, rule) for c in chords}, b
        elif b.from_chord.startswith("mouse."):
            assert b.to in variants, b
        else:
            assert variants.get(b.to) == b.from_chord, b


def test_from_rules_renders_irregular_manipulators():
    rows = set(bridges.from_rules())
    assert Bridge("⌃⌥ad", "num8", "32-swap-sides") in rows
    assert Bridge("⌃⌥←→", "num8", "32-swap-sides") in rows
    assert Bridge("⌥␣", "num9", "26-right-option-space-punto", "right") in rows
    assert Bridge("mouse.button5.hold", "F16", "29-mouse-ugreen-hold-to-browser") in rows
