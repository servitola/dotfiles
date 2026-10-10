import os
import re
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import bridges
import layers
from bridges import Bridge

SLOTS = {"z": "F13", "r": "F14", "f": "F15", "v": "F16", "t": "F17", "g": "F18", "b": "F19", "h": "F20"}


def test_fkey_mapping_is_bare_slots_plus_single_key_exceptions():
    expected = {base: (key, frozenset({"hyper"})) for key, base in SLOTS.items()}
    expected["num9"] = ("space", frozenset({"alt"}))
    assert bridges.fkey_mapping() == expected


def test_config_exposes_derived_mapping():
    import config
    assert config.FKEY_MAPPING == bridges.fkey_mapping()


def test_slot_variants_follow_the_formula():
    import layers
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


UNSIDED = {"shift": "left_shift", "control": "left_control", "option": "left_option", "command": "left_command"}


def _normal_to(entry):
    entry = dict(entry)
    if "modifiers" in entry:
        entry["modifiers"] = sorted(UNSIDED.get(m, m) for m in entry["modifiers"])
    return entry


def _generated_outputs():
    import json
    pairs = {}
    for stem, _ in layers.LAYERS.values():
        with open(os.path.join(bridges.RULES_DIR, f"{stem}.json"), encoding="utf-8") as fh:
            for m in json.load(fh)["manipulators"]:
                if set(m) == {"from", "to", "type"} and len(m["to"]) == 1:
                    to = m["to"][0]
                    pairs[json.dumps([m["from"]["key_code"], to], sort_keys=True)] = (m["from"]["key_code"], to)
    return list(pairs.values())


@pytest.mark.parametrize("to, expected", [
    ("↑", {"key_code": "up_arrow"}),
    ("⌘⌫", {"key_code": "delete_or_backspace", "modifiers": ["left_command"]}),
    ("⇧⌃⌥⌘⌦", {"key_code": "delete_forward",
               "modifiers": ["left_command", "left_control", "left_option", "left_shift"]}),
    ("F1", {"key_code": "f1"}),
    ("⌃F20", {"key_code": "f20", "modifiers": ["left_control"]}),
    ("PgDn", {"key_code": "page_down"}),
    ("num2", {"key_code": "keypad_2"}),
    ("⌘o", {"key_code": "o", "modifiers": ["left_command"]}),
    ("/", {"key_code": "slash"}),
    ("`", {"key_code": "grave_accent_and_tilde"}),
    ("⎋", {"key_code": "escape"}),
    ("⏮", {"key_code": "vk_consumer_previous"}),
    ("⏭", {"key_code": "vk_consumer_next"}),
    ("🔆", {"key_code": "illumination_increment"}),
    ("🔅", {"key_code": "illumination_decrement"}),
    ("▶/⏸", {"consumer_key_code": "play_or_pause"}),
    ("Vol↑", {"consumer_key_code": "volume_increment"}),
    ("Vol↓", {"consumer_key_code": "volume_decrement"}),
    ("⇪p", {"key_code": "p", "modifiers": ["right_command", "right_control", "right_option", "right_shift"]}),
    ("passthrough", {"key_code": "non_us_backslash"}),
    ("⇧passthrough", {"key_code": "non_us_backslash", "modifiers": ["left_shift"]}),
])
def test_output_entry(to, expected):
    assert bridges.output_entry(to, "non_us_backslash") == expected


@pytest.mark.parametrize("to", ["", "⌘", "⌘⇧↑", "F21", "Vol ↑", "xy", "⇧⇧a", "passthrough⌘", "Ж"])
def test_output_entry_rejects(to):
    with pytest.raises(ValueError, match=re.escape(f"`{to}`")):
        bridges.output_entry(to, "a")


def test_every_generated_output_round_trips():
    outputs = _generated_outputs()
    assert len(outputs) > 200
    for from_key, to in outputs:
        text = bridges.render_output(to, from_key)
        assert text is not None, (from_key, to)
        assert bridges.output_entry(text, from_key) == _normal_to(to), (from_key, to, text)


def test_render_output_names_passthrough_and_hyper():
    assert bridges.render_output({"key_code": "non_us_backslash", "modifiers": ["left_shift"]},
                                 "non_us_backslash") == "⇧passthrough"
    assert bridges.render_output({"key_code": "p", "modifiers": [
        "right_command", "right_control", "right_option", "right_shift"]}, "q") == "⇪p"
    assert bridges.render_output({"key_code": "o", "modifiers": ["command"]}, "f") == "⌘o"
    assert bridges.render_output({"shell_command": "true"}, "x") is None
    assert bridges.render_output({"key_code": "a", "modifiers": ["right_shift"]}, "b") is None
