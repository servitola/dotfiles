import os
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import rider

KEYMAP = """<keymap version="1" name="IntelliJ copy" parent="Mac OS X 10.5+">
  <action id="FindUsages">
    <keyboard-shortcut first-keystroke="alt f7" />
    <keyboard-shortcut first-keystroke="ctrl meta b" />
  </action>
  <action id="Macro.Save With CleanUp">
    <keyboard-shortcut first-keystroke="shift ctrl s" />
  </action>
  <action id="EditorScrollDown">
    <keyboard-shortcut first-keystroke="ctrl quote" second-keystroke="l" />
  </action>
  <action id="ExpandAllToLevel3">
    <keyboard-shortcut first-keystroke="meta alt multiply" />
  </action>
  <action id="$Undo" />
</keymap>
"""


@pytest.mark.parametrize("text, chord", [
    ("shift ctrl s", "⇧⌃s"), ("alt f7", "⌥F7"), ("ctrl meta b", "⌃⌘b"), ("meta s", "⌘s"),
    ("ctrl quote", "⌃'"), ("shift ctrl alt close_bracket", "⇧⌃⌥]"), ("alt BACK_SPACE", "⌥⌫"),
    ("ctrl numpad3", "⌃num3"), ("meta alt multiply", None), ("ctrl", None),
])
def test_keystroke_to_chord(text, chord):
    assert rider.keystroke_to_chord(text) == chord


def test_overrides_keep_removed_actions_as_empty(tmp_path):
    path = tmp_path / "keymap.xml"
    path.write_text(KEYMAP, encoding="utf-8")
    parent, actions = rider.overrides(str(path))
    assert parent == "Mac OS X 10.5+"
    assert actions["$Undo"] == []
    assert actions["FindUsages"] == [("⌥F7", None), ("⌃⌘b", None)]
    assert actions["EditorScrollDown"] == [("⌃'", "l")]


def test_expected_labels_from_bundle_or_humanized(tmp_path):
    path = tmp_path / "keymap.xml"
    path.write_text(KEYMAP, encoding="utf-8")
    out = rider.expected(str(path), names={"FindUsages": "Find Usages"})
    assert out["⌥F7"] == ["Rider — Find Usages"]
    assert out["⇧⌃s"] == ["Rider — Save With Clean Up"]
    assert out["⌃'"] == ["Rider — Editor Scroll Down (then l)"]
    assert "⌘⌥*" not in out
    assert rider.skipped(str(path)) == [("ExpandAllToLevel3", "meta alt multiply")]


def test_humanize_ids():
    assert rider._humanize("ReSharperGotoImplementation") == "Re Sharper Goto Implementation"
    assert rider._humanize("$Redo") == "Redo"
    assert rider._humanize("Vcs.ShowHistoryForBlock") == "Show History For Block"


@pytest.mark.skipif(not os.path.exists(rider.PLATFORM_JAR), reason="Rider.app is not on this Mac")
def test_effective_keymap_merges_parents(tmp_path):
    path = tmp_path / "keymap.xml"
    path.write_text(KEYMAP, encoding="utf-8")
    effective = rider.effective(str(path))
    assert "FindUsages" in effective["⌥F7"]
    assert all("$Undo" not in ids for ids in effective.values())
    assert any("EditorEnter" in ids for ids in effective.values())


@pytest.mark.skipif(not os.path.exists(rider.PLATFORM_JAR), reason="Rider.app is not on this Mac")
def test_action_names_strip_mnemonics():
    names = rider.action_names()
    assert names["FindUsages"] == "Find Usages"
    assert names["SaveAll"] == "Save All"


def test_repo_keymap_is_captured():
    assert os.path.exists(rider.KEYMAP), "run docs/keyboard/rider.py capture"
