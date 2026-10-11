import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "tools"))

import lint
import normalize
import projection
import shortcuts


def test_place_puts_a_chord_on_its_key_file():
    assert projection.place("⇧⌘4") == ("4", "⇧⌘4")
    assert projection.place("⌃␣") == ("space", "⌃␣")
    assert projection.place("⌥⌘e") == ("e", "⌥⌘e")


def test_place_traces_a_bridged_code_to_the_pressed_chord():
    assert projection.place("⌥F16") == ("v", "⇪⌥v")


def test_place_spells_four_modifiers_as_hyper_when_the_layer_passes_the_key():
    assert projection.place("⇧⌃⌥⌘j") == ("j", "⇪j")


def test_place_skips_what_the_tables_cannot_hold():
    assert projection.place("🌐⌃f")[0] is None
    assert projection.place("⌃F1")[0] is None


def test_describe_each_row_kind():
    assert projection.describe(shortcuts.System(52, "dock.toggle_hiding", True, "⌥⌘d")) == "— system 52 dock.toggle_hiding"
    assert projection.describe(shortcuts.App("cc.ffitch.shottr", "area", "⇧⌘4")) == "Shottr — area"
    svc = shortcuts.App("pbs", "com.apple.finder - Finder/Reveal - reveal", "⇧⌃h", "services")
    assert projection.describe(svc) == "Services — Finder/Reveal (Finder)"
    assert projection.describe(shortcuts.Menu("com.apple.Music", "Play", "⌘p")) == "Music — Play"
    assert projection.describe(shortcuts.Menu(shortcuts.GLOBAL, "Copy", "⌘c")) == "— Copy"


TABLE = (
    normalize.build_header()
    + normalize.build_chord_row("4", birman="4")
    + normalize.build_sep_row()
    + normalize.build_chord_row("⇧4", birman="$    ;    $")
    + normalize.build_chord_row("⌘4", desc="Rider — focus build window")
    + normalize.build_continuation_row(desc="Browser — Open 4th tab")
    + normalize.build_sep_row()
    + normalize.build_chord_row("⇧⌘4", desc="Shotr — start getting screenshot")
    + normalize.build_chord_row("⌃⌥4", desc="Audio Ext")
    + '{ chord = "⌃⌥4", fn = "audio.external" },\n'
    + normalize.build_footer()
)
EXPECTED = {"⇧⌘4": [("◆", "Shottr — area")], "⌘4": [("◆", "Music — Play")],
            "⌥4": [("⚙", "— system 1 x")], "⌥⌘4": [("◆", "Telegram — chat 4")]}


def _project(text, expected):
    return "".join(normalize.project_lines(text.splitlines(keepends=True), expected))


def test_project_appends_under_the_chord_after_hand_continuations():
    out = _project(TABLE, EXPECTED).splitlines()
    i = next(n for n, l in enumerate(out) if l.startswith("--" + "⌘4".rjust(12)))
    assert "Browser — Open 4th tab" in out[i + 1]
    assert out[i + 2].split("│")[3].strip() == "◆" and out[i + 2].endswith("Music — Play")


def test_project_inserts_a_missing_row_in_modifier_order():
    out = _project(TABLE, EXPECTED).splitlines()
    chords = [normalize._chord_of(l + "\n") for l in out]
    chords = [c for c in chords if c]
    assert chords.index("⇧4") < chords.index("⌥4") < chords.index("⌘4")
    assert chords.index("⌃⌥4") < chords.index("⌥⌘4")
    sep_before_group3 = max(n for n, l in enumerate(out) if normalize.SEP_ROW_RE.match(l))
    row = next(n for n, l in enumerate(out) if normalize._chord_of(l + "\n") == "⌥⌘4")
    assert row > sep_before_group3


def test_project_is_idempotent_and_removable():
    once = _project(TABLE, EXPECTED)
    assert _project(once, EXPECTED) == once
    assert _project(once, {}) == TABLE


def test_clearing_keeps_a_hand_line_written_under_a_projected_row():
    once = _project(TABLE, EXPECTED)
    lines = once.splitlines(keepends=True)
    i = next(n for n, l in enumerate(lines) if normalize._chord_of(l) == "⌥4")
    lines.insert(i + 1, normalize.build_continuation_row(desc="VSCode — mine"))
    cleared = "".join(normalize.project_lines(lines, {})).splitlines()
    kept = [l for l in cleared if "VSCode — mine" in l]
    assert len(kept) == 1 and normalize._chord_of(kept[0] + "\n") == "⌥4"


def test_marked_lines_carry_the_chord_of_their_row():
    lines = _project(TABLE, EXPECTED).splitlines(keepends=True)
    marked = {(c, g, d) for _, c, g, d in projection.marked_lines(lines)}
    assert marked == {(c, g, d) for c, descs in EXPECTED.items() for g, d in descs}


def test_lint_p1_reports_stale_and_missing_lines(tmp_path):
    path = tmp_path / "4.lua"
    path.write_text(_project(TABLE, EXPECTED), encoding="utf-8")
    state = lint.parse_file(str(path))
    findings = lint.Findings()
    want = dict(EXPECTED)
    del want["⌘4"]
    want["⇧4"] = [("◆", "New — thing")]
    lint.check_projection(state, findings, want)
    codes = sorted((sev, code, "Music — Play" in msg or "New — thing" in msg)
                   for sev, _, _, code, msg, _ in findings.items)
    assert codes == [("ERROR", "P1", True), ("ERROR", "P1", True)]


def test_lint_s4_flags_a_global_hotkey_on_an_active_chord(tmp_path):
    path = tmp_path / "4.lua"
    path.write_text(TABLE, encoding="utf-8")
    state = lint.parse_file(str(path))
    rows = {"system": [], "menu": [shortcuts.Menu("com.apple.Music", "Four", "⌃⌥4")],
            "app": [shortcuts.App("cc.ffitch.shottr", "x", "⌃⌥4")]}
    findings = lint.Findings()
    lint.check_app_shortcuts(state, findings, rows)
    assert sorted(sev for sev, *_ in findings.items) == ["ERROR", "WARN"]


def test_live_tables_match_the_machine():
    """What normalize.py --project would write is on disk."""
    expected = projection.expected()
    for stem, chords in expected.items():
        path = os.path.join(lint.LAYOUT_DIR, stem + ".lua")
        with open(path, encoding="utf-8") as fh:
            have = {(c, g, d) for _, c, g, d in projection.marked_lines(fh.readlines())}
        assert have == {(c, g, d) for c, descs in chords.items() for g, d in descs}, stem
