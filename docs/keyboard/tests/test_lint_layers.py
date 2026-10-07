import json
import os
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "tools"))

import bridges
import gen_layers
import layers
import lint
import shortcuts
from shortcuts import App, Menu, System


def _codes(findings):
    return [(sev, code) for sev, _, _, code, _, _ in findings.items]


def _emitted():
    return set(bridges.slot_variants()) | set(bridges.EXCEPTIONS)


def test_b2_slot_variants_and_exceptions_pass():
    f = lint.Findings()
    lint.check_bridged_chords(_state("F16", "⌘F16", "⇧F17", "⌥⇧F13", "num8", "num9", "⌃⌥a"), f, _emitted())
    assert not f


@pytest.mark.parametrize("chord", ["⌘F15", "⌥F13", "num0", "⌃num9", "⇧⌃⌥F16"])
def test_b2_anything_else_is_an_error_naming_the_chord(chord):
    f = lint.Findings()
    lint.check_bridged_chords(_state(chord), f, _emitted())
    assert _codes(f) == [(lint.ERROR, "B2")]
    assert f"`{chord}`" in f.items[0][4]


PLAIN = {"from": {"key_code": "k", "modifiers": {"mandatory": layers.from_modifiers("hyper_shift_control")}},
         "to": [{"key_code": "up_arrow"}], "type": "basic"}


@pytest.mark.parametrize("manip, fires", [
    (PLAIN, True),
    ({**PLAIN, "to": [{"consumer_key_code": "play_or_pause"}]}, True),
    ({**PLAIN, "to_after_key_up": [{"key_code": "a"}]}, False),
    ({**PLAIN, "to": [{"shell_command": "true"}]}, False),
    ({**PLAIN, "to": [{"key_code": "a"}, {"key_code": "b"}]}, False),
    ({**PLAIN, "from": {"key_code": "k", "modifiers": {"mandatory": ["left_shift"]}}}, False),
])
def test_b4_raw_row_that_fits_the_table(tmp_path, monkeypatch, manip, fires):
    monkeypatch.setattr(layers, "RAW_DIR", str(tmp_path))
    (tmp_path / "14-hyper-shift-control.json").write_text(json.dumps([manip]), encoding="utf-8")
    f = lint.Findings()
    lint.check_layer_raw(f)
    assert _codes(f) == ([(lint.WARN, "B4")] if fires else [])


def test_b4_clean_on_the_real_files():
    f = lint.Findings()
    lint.check_layer_raw(f)
    assert not f


def test_g1_hand_edited_rule_file(tmp_path):
    for stem, text in gen_layers.render().items():
        (tmp_path / f"{stem}.json").write_text(text, encoding="utf-8")
    f = lint.Findings()
    lint.check_generated(f, str(tmp_path))
    assert not f
    path = tmp_path / "12-hyper-shift-command.json"
    path.write_text(path.read_text(encoding="utf-8") + " ", encoding="utf-8")
    lint.check_generated(f, str(tmp_path))
    assert _codes(f) == [(lint.ERROR, "G1")]
    assert f.items[0][1].endswith("12-hyper-shift-command.json")


def test_g1_reports_an_input_the_generator_rejects(monkeypatch):
    def broken():
        raise ValueError("layers.toml:3 layer hyper, key q: nope")
    monkeypatch.setattr(gen_layers, "render", broken)
    f = lint.Findings()
    lint.check_generated(f)
    assert _codes(f) == [(lint.ERROR, "G1")]
    assert "key q" in f.items[0][4]


MACHINE = {
    "system": [System(30, "screenshot.area", False, "⇧⌘4"), System(52, "dock.toggle_hiding", True, "⌥⌘d", line=7),
               System(60, "input_source.previous", True, "⌃␣", line=9), System(79, "spaces.left", True, "")],
    "app": [App("cc.ffitch.shottr", "area", "⇧⌘4", line=20), App("org.p0deje.Maccy", "delete", "none", line=24),
            App("org.p0deje.Maccy", "preview", "⌃␣", line=28)],
    "menu": [Menu("com.apple.Music", "Play", "⌘p", line=40), Menu("com.apple.finder", "Get Info", "⌘p", line=44),
             Menu("com.apple.Music", "Play Again", "⌘p", line=48)],
}


def _state(*chords):
    return {"path": "x.lua", "actives": [{"line": i + 1, "chord": c, "kind": "fn", "target": "t"}
                                         for i, c in enumerate(chords)]}


def test_s1_active_chord_on_an_enabled_system_shortcut():
    f = lint.Findings()
    lint.check_system_shortcuts(_state("⌥⌘d", "⇧⌘4", "⌥⌘e", "F19", "⇪b", "garbage!"), f, lint.enabled_system(MACHINE))
    assert _codes(f) == [(lint.ERROR, "S1")]
    assert f.items[0][2] == 1 and "dock.toggle_hiding" in f.items[0][4]


def test_s1_hyper_chord_is_four_modifiers():
    rows = {**MACHINE, "system": [System(99, "x", True, "⇧⌃⌥⌘b")]}
    f = lint.Findings()
    lint.check_system_shortcuts(_state("⇪b"), f, lint.enabled_system(rows))
    assert _codes(f) == [(lint.ERROR, "S1")]


def test_s2_s3_machine_rows():
    f = lint.Findings()
    lint.check_machine_shortcuts(f, MACHINE)
    found = sorted((code, line) for sev, _, line, code, _, _ in f.items if sev == lint.WARN)
    assert found == [("S2", 28), ("S3", 48)]


def test_s3_app_against_any_menu_and_global_menu_against_any_menu():
    rows = {"system": [], "app": [App("a", "x", "⌘p", line=3)],
            "menu": [Menu("com.apple.Music", "Play", "⌘p", line=5), Menu("NSGlobalDomain", "Print", "⌘k", line=7),
                     Menu("com.apple.finder", "Kill", "⌘k", line=9)]}
    f = lint.Findings()
    lint.check_machine_shortcuts(f, rows)
    assert sorted((code, line) for _, _, line, code, _, _ in f.items) == [("S3", 5), ("S3", 9)]


def test_s_rules_clean_enough_on_the_real_files():
    rows = shortcuts.load()
    f = lint.Findings()
    lint.check_machine_shortcuts(f, rows)
    assert not f.has_errors()
