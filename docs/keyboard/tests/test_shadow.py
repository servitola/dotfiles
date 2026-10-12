import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import bridges
import shadow

HYPER = ["right_command", "right_control", "right_option", "right_shift"]


def _rules(tmp_path, *files):
    for name, manips in files:
        (tmp_path / name).write_text(json.dumps({"description": name, "manipulators": manips}), encoding="utf-8")
    return str(tmp_path)


def _m(key, mandatory=(), optional=(), to="a", conditions=None):
    m = {"from": {"key_code": key, "modifiers": {"mandatory": list(mandatory), "optional": list(optional)}},
         "to": [{"key_code": to}], "type": "basic"}
    if conditions:
        m["conditions"] = conditions
    return m


def test_tracked_rules_have_no_dead_manipulator():
    assert [shadow.describe(*row) for row in shadow.dead(bridges.RULES_DIR)] == []


def test_optional_any_swallows_a_later_hyper_chord(tmp_path):
    lock = _m("delete_or_backspace", ["left_control", "right_option"], ["any"])
    hyper = _m("delete_or_backspace", ["left_control", *HYPER])
    rows = shadow.dead(_rules(tmp_path, ("00.json", [lock]), ("11.json", [hyper])))
    assert [(name, i, by) for name, i, _, by in rows] == [("11.json", 0, "00.json#1")]
    assert "never fires" in shadow.describe(*rows[0])


def test_same_chord_twice_kills_the_second_but_disjoint_chords_live(tmp_path):
    rows = shadow.dead(_rules(tmp_path, ("02.json", [_m("q", ["left_option", "left_shift"])]),
                              ("18.json", [_m("q", ["left_option"]), _m("q", ["left_option", "left_shift"])])))
    assert [(name, i) for name, i, _, _ in rows] == [("18.json", 1)]


def test_a_condition_keeps_the_later_one_alive(tmp_path):
    held = [{"name": "tab_modifier", "type": "variable_if", "value": 1}]
    assert shadow.dead(_rules(tmp_path, ("01.json", [_m("v", conditions=held), _m("v")]))) == []
    assert len(shadow.dead(_rules(tmp_path, ("01.json", [_m("v"), _m("v", conditions=held)])))) == 1


def test_two_earlier_rules_together_can_kill_a_third(tmp_path):
    rows = shadow.dead(_rules(tmp_path, ("a.json", [
        _m("a", ["left_option"]), _m("a", ["left_option", "left_shift"]), _m("a", ["left_option"], ["left_shift"])])))
    assert [i for _, i, _, _ in rows] == [2]
