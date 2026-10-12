import os
import re
import sys

import pytest

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import grammar
import layers

UNSIDED = {"shift": "left_shift", "control": "left_control", "option": "left_option", "command": "left_command"}


def _normal_to(entry):
    entry = dict(entry)
    if "modifiers" in entry:
        entry["modifiers"] = sorted(UNSIDED.get(m, m) for m in entry["modifiers"])
    return entry


def _generated_outputs():
    import json
    pairs = {}
    built = layers.build()
    for stem, _ in layers.LAYERS.values():
        for m in built[stem]["manipulators"]:
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
    assert grammar.output_entry(to, "non_us_backslash") == expected


@pytest.mark.parametrize("to", ["", "⌘", "⌘⇧↑", "F21", "Vol ↑", "xy", "⇧⇧a", "passthrough⌘", "Ж"])
def test_output_entry_rejects(to):
    with pytest.raises(ValueError, match=re.escape(f"`{to}`")):
        grammar.output_entry(to, "a")


def test_every_generated_output_round_trips():
    outputs = _generated_outputs()
    assert len(outputs) > 200
    for from_key, to in outputs:
        text = grammar.render_output(to, from_key)
        assert text is not None, (from_key, to)
        assert grammar.output_entry(text, from_key) == _normal_to(to), (from_key, to, text)


def test_render_output_names_passthrough_and_hyper():
    assert grammar.render_output({"key_code": "non_us_backslash", "modifiers": ["left_shift"]},
                                 "non_us_backslash") == "⇧passthrough"
    assert grammar.render_output({"key_code": "p", "modifiers": [
        "right_command", "right_control", "right_option", "right_shift"]}, "q") == "⇪p"
    assert grammar.render_output({"key_code": "o", "modifiers": ["command"]}, "f") == "⌘o"
    assert grammar.render_output({"shell_command": "true"}, "x") is None
    assert grammar.render_output({"key_code": "a", "modifiers": ["right_shift"]}, "b") is None
