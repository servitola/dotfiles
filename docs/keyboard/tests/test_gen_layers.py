import os
import subprocess
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "tools"))

import bridges
import gen_layers
import layers

GEN = os.path.join(os.path.dirname(HERE), "tools", "gen_layers.py")
STEMS = [stem for stem, _ in layers.LAYERS.values()]


def test_generated_equals_tracked_rules():
    assert gen_layers.drift() == []


@pytest.mark.parametrize("name", list(layers.LAYERS))
def test_generated_is_table_then_formula_then_raw(name):
    stem = layers.LAYERS[name][0]
    rows = layers.load()
    slots = layers.load_slots()
    own = [r for r in rows if r.layer == name]
    left = bridges._mods_text(layers.layer_mods(name) - {"hyper"})
    expected = [layers.manipulator(name, r.key, r.to) for r in own]
    raw = layers.load_raw(stem)
    taken = {r.key for r in own} | {m["from"]["key_code"] for m in raw}
    expected += [layers.manipulator(name, key, left + base) for key, base in slots.items() if key not in taken]
    expected += raw
    assert layers.build()[stem]["manipulators"] == expected


def test_hyper_layer_ends_with_the_eight_slots_in_column_order():
    hyper = layers.build()["07-hyper-only"]["manipulators"]
    assert [(m["from"]["key_code"], m["to"][0]["key_code"]) for m in hyper[-8:]] == [
        ("z", "f13"), ("r", "f14"), ("f", "f15"), ("v", "f16"),
        ("t", "f17"), ("g", "f18"), ("b", "f19"), ("h", "f20")]
    assert all("modifiers" not in m["to"][0] for m in hyper[-8:])


def test_slot_variant_keeps_the_layer_modifiers():
    manips = layers.build()["13-hyper-shift-option"]["manipulators"]
    z = [m for m in manips if m["from"]["key_code"] == "z"]
    assert z == [layers.manipulator("hyper_shift_option", "z", "⇧⌥F13")]
    assert z[0]["to"] == [{"key_code": "f13", "modifiers": ["left_option", "left_shift"]}]


def test_explicit_entry_wins_over_the_slot():
    command = layers.build()["09-hyper-command"]["manipulators"]
    f = [m["to"][0] for m in command if m["from"]["key_code"] == "f"]
    assert f == [{"key_code": "o", "modifiers": ["left_command"]}]
    rows = layers.load() + [layers.Row("hyper", "v", "↑", 99)]
    hyper = layers.build(rows=rows)["07-hyper-only"]["manipulators"]
    assert [m["to"][0] for m in hyper if m["from"]["key_code"] == "v"] == [{"key_code": "up_arrow"}]


def test_raw_entry_wins_over_the_slot():
    manips = layers.build()["14-hyper-shift-control"]["manipulators"]
    z = [m for m in manips if m["from"]["key_code"] == "z"]
    assert len(z) == 1 and "shell_command" in z[0]["to"][0]


def test_same_from_in_another_modifier_order_is_refused():
    raw_z = layers.load_raw("14-hyper-shift-control")[1]
    with pytest.raises(ValueError, match="`z` is mapped more than once"):
        layers._refuse_shadowed("14", [layers.manipulator("hyper_shift_control", "z", "⇧⌃F13"), raw_z])


def test_manipulator_shape():
    m = layers.manipulator("hyper_shift", "w", "⇧↑")
    assert m == {
        "from": {"key_code": "w", "modifiers": {"mandatory": [
            "left_shift", "right_command", "right_control", "right_option", "right_shift"]}},
        "to": [{"key_code": "up_arrow", "modifiers": ["left_shift"]}],
        "type": "basic",
    }
    assert "modifiers" not in layers.manipulator("hyper", "w", "↑")["to"][0]


def test_raw_stays_last():
    manips = layers.build()["14-hyper-shift-control"]["manipulators"]
    assert [m["from"]["key_code"] for m in manips[-2:]] == ["x", "z"]
    assert "shell_command" in manips[-1]["to"][0]


def test_bad_value_names_layer_and_key(tmp_path):
    path = tmp_path / "layers.toml"
    path.write_text('[layer.hyper]\nw = "↑"\nq = "⌘⇧x"\n', encoding="utf-8")
    with pytest.raises(ValueError, match=r"layers.toml:3 layer hyper, key q"):
        layers.load(str(path))


@pytest.mark.parametrize("body, needle", [
    ('[layer.hyper_meta]\nw = "↑"\n', "hyper_meta"),
    ('[layer.hyper]\nwasd = "↑"\n', "wasd"),
    ('[slot]\nv = "F16"\n', "slot"),
])
def test_unknown_layer_or_key(tmp_path, body, needle):
    path = tmp_path / "layers.toml"
    path.write_text(body, encoding="utf-8")
    with pytest.raises(ValueError, match=needle):
        layers.load(str(path))


@pytest.mark.parametrize("body, needle", [
    ('[slots]\nspacebar = "F13"\n', "spacebar"),
    ('[slots]\n"1" = "F13"\n', "`1`"),
    ('[slots]\nv = "F12"\n', "F12"),
    ('[slots]\nv = "num8"\n', "num8"),
    ('[slots]\nv = "F16"\nb = "F16"\n', "more than one"),
])
def test_bad_slots(tmp_path, body, needle):
    path = tmp_path / "layers.toml"
    path.write_text(body, encoding="utf-8")
    with pytest.raises(ValueError, match=needle):
        layers.load_slots(str(path))


def test_check_detects_hand_edit(tmp_path):
    rules = tmp_path / "rules"
    rules.mkdir()
    for stem, text in gen_layers.render().items():
        (rules / f"{stem}.json").write_text(text, encoding="utf-8")
    assert gen_layers.drift(str(rules)) == []
    path = rules / "07-hyper-only.json"
    path.write_text(path.read_text(encoding="utf-8").replace('"up_arrow"', '"down_arrow"', 1), encoding="utf-8")
    assert gen_layers.drift(str(rules)) == ["07-hyper-only"]
    proc = subprocess.run([sys.executable, GEN, "--check", "--rules-dir", str(rules)],
                          capture_output=True, text=True)
    assert proc.returncode == 1
    assert "07-hyper-only" in proc.stdout


def test_write_then_check_is_clean(tmp_path):
    rules = tmp_path / "rules"
    rules.mkdir()
    subprocess.run([sys.executable, GEN, "--rules-dir", str(rules), "--no-karabiner-lint"], check=True,
                   capture_output=True)
    proc = subprocess.run([sys.executable, GEN, "--check", "--rules-dir", str(rules)], capture_output=True, text=True)
    assert proc.returncode == 0, proc.stdout
