import json
import os
import subprocess
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import gen_rules
import grammar
import layers

GEN = os.path.join(os.path.dirname(HERE), "gen_rules.py")


@pytest.mark.parametrize("name", list(layers.LAYERS))
def test_generated_is_table_then_formula_then_raw(name):
    stem = layers.LAYERS[name][0]
    rows = layers.load()
    slots = layers.load_slots()
    own = [r for r in rows if r.layer == name]
    left = grammar._mods_text(layers.layer_mods(name) - {"hyper"})
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


def test_fn_layer_keeps_other_modifiers_and_takes_no_slots():
    manips = layers.build()["30-fn-layer-mirror"]["manipulators"]
    assert manips[0] == {
        "from": {"key_code": "1", "modifiers": {"mandatory": ["fn"], "optional": ["any"]}},
        "to": [{"key_code": "7"}],
        "type": "basic",
    }
    assert not any(m["to"][0]["key_code"].startswith("f1") for m in manips)
    assert all(r.layer in layers.LAYERS for r in layers.load())


def test_tab_layer_is_a_condition_and_types_sequences():
    manips = layers.build()["01-tab-modifier"]["manipulators"]
    s = next(m for m in manips if m["from"] == {"key_code": "s"})
    assert s["conditions"] == [{"name": "tab_modifier", "type": "variable_if", "value": 1}]
    assert [e["key_code"] for e in s["to"]] == list("servitola")
    assert manips[-1]["from"] == {"key_code": "tab"} and manips[-1]["to_if_alone"] == [{"key_code": "tab"}]


def test_left_all_layer_carries_its_modifiers():
    w = layers.build()["27-left-all-hide"]["manipulators"][0]
    left = ["left_command", "left_control", "left_option", "left_shift"]
    assert w["from"] == {"key_code": "w", "modifiers": {"mandatory": left}}
    assert w["to"] == [{"key_code": "up_arrow", "modifiers": left}]


@pytest.mark.parametrize("chord, frm", [
    ("f1", {"key_code": "f1"}),
    ("⌥q", {"key_code": "q", "modifiers": {"mandatory": ["left_option"]}}),
    ("⌥(⇧)a", {"key_code": "a", "modifiers": {"mandatory": ["left_option"], "optional": ["left_shift"]}}),
    ("⇪⇧non_us_backslash", {"key_code": "non_us_backslash", "modifiers": {"mandatory": [
        "left_shift", "right_command", "right_control", "right_option", "right_shift"]}}),
])
def test_chord_from(chord, frm):
    assert layers.chord_from(chord) == frm


@pytest.mark.parametrize("chord", ["⌘⌥q", "⌥(⌘⇧)a", "⌥", "⌥Q", "(⇪)a", "⌥q w"])
def test_bad_chord(chord):
    with pytest.raises(ValueError, match="is not"):
        layers.chord_from(chord)


def test_shell_output_keeps_spaces_and_quotes():
    assert layers.outputs("sh: open -a 'Mission Control'", "f3") == [{"shell_command": "open -a 'Mission Control'"}]
    with pytest.raises(ValueError, match="needs a command"):
        layers.outputs("sh:", "f3")


def test_tables_sharing_a_rule_keep_their_order_and_conditions():
    manips = layers.build()["18-hyper-misc"]["manipulators"]
    first_f = next(i for i, m in enumerate(manips) if m["from"]["key_code"] == "f1")
    assert all("conditions" not in m for m in manips[:first_f])
    off = [{"name": "keyboard_disabled", "type": "variable_unless", "value": 1}]
    assert all(m["conditions"] == off for m in manips[first_f:])
    assert manips[first_f]["to"] == [{"shell_command": "$HOME/.local/bin/lunar displays 'Built-In' brightness 0"}]


def test_table_with_fixed_modifiers_refuses_a_chord_key(tmp_path):
    path = tmp_path / "layers.toml"
    path.write_text('[layer.fn]\nrule = "30-fn"\ntitle = "fn"\nmandatory = ["fn"]\n"⌥q" = "u"\n', encoding="utf-8")
    with pytest.raises(ValueError, match="layers.toml:5 layer fn, key ⌥q"):
        layers.load(str(path), hyper=False)


def test_raw_stays_last():
    manips = layers.build()["14-hyper-shift-control"]["manipulators"]
    assert [m["from"]["key_code"] for m in manips[-2:]] == ["x", "z"]
    assert "shell_command" in manips[-1]["to"][0]


def test_bad_value_names_layer_and_key(tmp_path):
    path = tmp_path / "layers.toml"
    path.write_text(HYPER + 'w = "↑"\nq = "⌘⇧x"\n', encoding="utf-8")
    with pytest.raises(ValueError, match=r"layers.toml:5 layer hyper, key q"):
        layers.load(str(path))


HYPER = '[layer.hyper]\nrule = "07-hyper-only"\ntitle = "Hyper"\n'


@pytest.mark.parametrize("body, needle", [
    ('[layer.hyper_meta]\nrule = "07-x"\ntitle = "x"\nw = "↑"\n', "hyper_meta"),
    (HYPER + 'wasd = "↑"\n', "wasd"),
    ('[slot]\nv = "F16"\n', "slot"),
    ('[layer.hyper]\nw = "↑"\n', r"\[layer.hyper\]: needs rule"),
    ('[layer.hyper]\nrule = "hyper"\ntitle = "x"\n', r"needs rule"),
    ('[layer.hyper]\nrule = "07-hyper-only"\nw = "↑"\n', "07-hyper-only has no title"),
    (HYPER + 'mandatory = ["fn"]\n', "drop"),
    (HYPER + '[layer.misc]\nrule = "07-hyper-only"\n', "cannot share rule"),
    ('[layer.a]\nrule = "18-misc"\ntitle = "one"\n[layer.b]\nrule = "18-misc"\ntitle = "two"\n', "another title"),
    ('[layer.a]\nrule = "18-misc"\ntitle = "x"\nmandatory = ["left_alt"]\n', "left_alt"),
    ('[layer.a]\nrule = "18-misc"\ntitle = "x"\nwhen = 1\n', "name of a Karabiner variable"),
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


def test_all_rules_are_generated_and_hand_written_in_stem_order():
    rules = layers.all_rules()
    stems = [stem for stem, _ in rules]
    assert stems == sorted(stems)
    assert set(layers.hand_rules()) < set(stems) and set(layers.build()) < set(stems)
    assert all(set(rule) == {"description", "manipulators"} for _, rule in rules)


def test_a_rule_both_generated_and_hand_written_is_refused(monkeypatch):
    monkeypatch.setattr(layers, "hand_rules", lambda: {"07-hyper-only": {"description": "", "manipulators": []}})
    with pytest.raises(ValueError, match="07-hyper-only"):
        layers.all_rules()


def test_config_is_the_template_with_the_rules_in_place():
    doc = layers.config()
    with open(layers.TEMPLATE_PATH, encoding="utf-8") as fh:
        template = json.load(fh)
    assert doc["profiles"][0]["complex_modifications"]["rules"] == [rule for _, rule in layers.all_rules()]
    doc["profiles"][0]["complex_modifications"]["rules"] = template["profiles"][0]["complex_modifications"]["rules"]
    assert doc == template


def test_check_writes_nothing_and_build_writes_only_the_output(tmp_path):
    out = tmp_path / "karabiner.json"
    proc = subprocess.run([sys.executable, GEN, "--check", "--output", str(out)], capture_output=True, text=True)
    assert proc.returncode == 0, proc.stderr
    assert list(tmp_path.iterdir()) == []
    subprocess.run([sys.executable, GEN, "--output", str(out)], check=True, capture_output=True)
    assert [p.name for p in tmp_path.iterdir()] == ["karabiner.json"]
    assert json.loads(out.read_text(encoding="utf-8")) == layers.config()


def test_dump_writes_one_file_per_rule(tmp_path):
    paths = gen_rules.dump(layers.all_rules(), str(tmp_path))
    assert [os.path.basename(p) for p in paths] == [f"{stem}.json" for stem, _ in layers.all_rules()]


def test_rule_order_comes_from_the_rule_names_in_the_tables(tmp_path, monkeypatch):
    path = tmp_path / "layers.toml"
    path.write_text('[layer.late]\nrule = "40-late"\ntitle = "late"\nq = "a"\n'
                    '[layer.early]\nrule = "03-early"\ntitle = "early"\nq = "b"\n'
                    '[layer.more]\nrule = "40-late"\nunless = "off"\nw = "c"\n', encoding="utf-8")
    monkeypatch.setattr(layers, "LAYERS_PATH", str(path))
    monkeypatch.setattr(layers.tables, "__defaults__", (str(path),))
    monkeypatch.setattr(layers.load, "__defaults__", (str(path), True))
    monkeypatch.setattr(layers.load_slots, "__defaults__", (str(path),))
    monkeypatch.setattr(layers, "raw_stems", lambda: [])
    monkeypatch.setattr(layers, "load_raw", lambda stem: [])
    stems = [stem for stem, _ in layers.all_rules()]
    assert stems.index("03-early") < stems.index("04-caps-lock-hyper") < stems.index("40-late")
    late = dict(layers.all_rules())["40-late"]
    assert late["description"] == "late"
    assert [m["from"]["key_code"] for m in late["manipulators"]] == ["q", "w"]
    assert "conditions" not in late["manipulators"][0] and late["manipulators"][1]["conditions"][0]["name"] == "off"
