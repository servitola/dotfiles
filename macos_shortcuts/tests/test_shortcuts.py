import copy
import json
import os
import plistlib
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import shortcuts
from shortcuts import App, Menu, System

FIXTURES = os.path.join(HERE, "fixtures", "shortcuts")
FIXTURE_NAME = {shortcuts.DAY_ONE: os.path.basename(shortcuts.DAY_ONE)}


class FakeMachine:
    def __init__(self, sandboxed=(), write_ok=True):
        self.prefs = {}
        for name in os.listdir(FIXTURES):
            with open(os.path.join(FIXTURES, name), "rb") as fh:
                self.prefs[name.removesuffix(".plist")] = plistlib.load(fh)
        self._sandboxed = set(sandboxed)
        self.write_ok = write_ok
        self.writes, self.runs = [], []

    def export(self, domain):
        return copy.deepcopy(self.prefs.get(FIXTURE_NAME.get(domain, domain), {}))

    def find(self, word):
        return sorted(d for d, p in self.prefs.items() if any(word in k for k in p))

    def sandboxed(self, domain):
        return domain in self._sandboxed or "/Group Containers/" in domain

    def write(self, args):
        self.writes.append(args)
        return self.write_ok

    def run(self, argv):
        self.runs.append(argv)


ICE_NAMES = ("EnableIceBar", "SearchMenuBarItems", "ShowSectionDividers", "ToggleAlwaysHiddenSection",
             "ToggleApplicationMenus", "ToggleHiddenSection")
SHORTCUT_J = "(null) - 98E57310-1031-4D81-A905-6EBF846D38C5 - runShortcutAsService"
TERMINAL_TAB = "com.apple.Terminal - New Terminal Tab at Folder - newTerminalAtFolder"
DECLARED = {
    "system": [System(30, "screenshot.area", False, "⇧⌘4"), System(79, "spaces.left", True, "")],
    "app": [App("cc.ffitch.shottr", "area", "⇧⌘4"), App("cc.ffitch.shottr", "fullscreen", "none"),
            *(App("com.jordanbaird.Ice", name, "none", "ice") for name in ICE_NAMES),
            App("com.mowglii.ItsycalApp", "GlobalShortcut", "⌃⌥c", "masshortcut"),
            App("pbs", SHORTCUT_J, "⇧⌃⌥j", "services"),
            App("pbs", "(null) - E0609E39-D34B-4E18-BA91-994451AF81CE - runShortcutAsService", "⇧⌃⌥k",
                "services"),
            App("pbs", TERMINAL_TAB, "⇧⌃b", "services"),
            App("pbs", "com.apple.finder - Finder/Reveal - reveal", "⇧⌃h", "services"),
            App("pbs", "com.googlecode.iterm2 - New iTerm2 Tab Here - openTab", "⇧⌃b", "services"),
            App(shortcuts.DAY_ONE, "DOMenuEntryGlobalShortcut", "⇧⌃⌥⌘j", "carbon-dict")],
    "menu": [Menu("com.apple.finder", "Enclosing Folder in New Window", "⌥⌘e")],
}


def _statuses(rows, machine):
    results, _ = shortcuts.check(rows, machine)
    return [(shortcuts.ident(r.row), r.status, r.live) for r in results]


def _with(kind, index, **change):
    rows = copy.deepcopy(DECLARED)
    rows[kind][index] = rows[kind][index].__class__(**{**rows[kind][index].__dict__, **change})
    return rows


def test_capture_reads_every_store():
    assert shortcuts.capture(FakeMachine()) == DECLARED


def test_render_then_load_round_trips(tmp_path):
    path = tmp_path / "shortcuts.toml"
    path.write_text(shortcuts.render(DECLARED), encoding="utf-8")
    loaded = shortcuts.load(str(path))
    assert loaded == DECLARED
    assert [r.line for r in loaded["system"]] == [10, 16]


def test_check_ok_on_matching_machine():
    assert {s for _, s, _ in _statuses(DECLARED, FakeMachine())} == {"ok"}


def test_menu_combo_order_does_not_matter():
    m = FakeMachine()
    m.prefs["com.apple.finder"]["NSUserKeyEquivalents"]["Enclosing Folder in New Window"] = "@~e"
    assert {s for _, s, _ in _statuses(DECLARED, m)} == {"ok"}


@pytest.mark.parametrize("rows, expected", [
    (_with("system", 0, enabled=True), ("differs", "disabled ⇧⌘4")),
    (_with("system", 0, keys="⇧⌘5"), ("differs", "disabled ⇧⌘4")),
    (_with("app", 0, keys="⇧⌘5"), ("differs", "⇧⌘4")),
    (_with("app", 1, keys="⌘1"), ("differs", "none")),
    (_with("app", 0, name="gone"), ("missing", None)),
    (_with("menu", 0, item="Nope"), ("missing", None)),
    (_with("menu", 0, domain="org.absent"), ("missing", None)),
    (_with("system", 0, id=999), ("missing", None)),
])
def test_check_reports_the_one_changed_row(rows, expected):
    bad = [(s, live) for _, s, live in _statuses(rows, FakeMachine()) if s != "ok"]
    assert bad == [expected]


def test_sandboxed_domain_is_unwritable_only_when_it_differs():
    m = FakeMachine(sandboxed={"cc.ffitch.shottr"})
    assert {s for _, s, _ in _statuses(DECLARED, m)} == {"ok"}
    statuses = [s for _, s, _ in _statuses(_with("app", 0, keys="⇧⌘5"), m)]
    assert "unwritable" in statuses


def test_undeclared_symbolic_id_is_reported():
    rows = {**DECLARED, "system": DECLARED["system"][:1]}
    assert shortcuts.check(rows, FakeMachine())[1] == [79]


def test_apply_nothing_to_do():
    m, said = FakeMachine(), []
    assert shortcuts.apply(DECLARED, m, say=said.append)
    assert said == ["nothing to do"] and m.writes == [] and m.runs == []


def test_apply_system_keeps_live_parameters_when_the_chord_is_unchanged():
    m = FakeMachine()
    live = m.prefs["com.apple.symbolichotkeys"]["AppleSymbolicHotKeys"]["30"]
    live["value"]["parameters"] = [52, 21, 1179648 | 2097152]
    shortcuts.apply(_with("system", 0, enabled=True), m, say=lambda _: None)
    [args] = m.writes
    assert args[:4] == ["com.apple.symbolichotkeys", "AppleSymbolicHotKeys", "-dict-add", "30"]
    assert plistlib.loads(_wrap(args[4])) == {
        "enabled": True, "value": {"parameters": [52, 21, 3276800], "type": "standard"}}
    assert m.runs == [[shortcuts.ACTIVATE_SETTINGS, "-u"]]


def test_apply_system_encodes_a_new_chord():
    m = FakeMachine()
    shortcuts.apply(_with("system", 0, keys="⌃F2"), m, say=lambda _: None)
    assert plistlib.loads(_wrap(m.writes[0][4]))["value"] == {
        "parameters": [65535, 120, 8650752], "type": "standard"}


def test_apply_system_without_keys_writes_no_value():
    m = FakeMachine()
    shortcuts.apply(_with("system", 1, enabled=False), m, say=lambda _: None)
    assert plistlib.loads(_wrap(m.writes[0][4])) == {"enabled": False}


def test_apply_disables_a_bare_modifier_hotkey():
    m = FakeMachine()
    m.prefs["com.apple.symbolichotkeys"]["AppleSymbolicHotKeys"]["79"] = {
        "enabled": True, "value": {"parameters": [262144, 9223372036854775807], "type": "modifier"}}
    assert _statuses(DECLARED, m)[1][1:] == ("differs", "enabled ⌃")
    shortcuts.apply(_with("system", 1, enabled=False), m, say=lambda _: None)
    assert plistlib.loads(_wrap(m.writes[0][4])) == {"enabled": False}


def test_apply_app_and_menu():
    m, said = FakeMachine(), []
    rows = _with("app", 0, keys="⇧⌥1")
    rows = {**rows, "app": [rows["app"][0], App("cc.ffitch.shottr", "fullscreen", "none")],
            "menu": [Menu("com.apple.finder", "Enclosing Folder in New Window", "⌃⌥⌘e")]}
    rows["app"].append(App("cc.ffitch.shottr", "ocr", "none"))
    shortcuts.apply(rows, m, say=said.append)
    assert m.writes == [
        ["cc.ffitch.shottr", "KeyboardShortcuts_area", "-string", '{"carbonKeyCode":18,"carbonModifiers":2560}'],
        ["cc.ffitch.shottr", "KeyboardShortcuts_ocr", "-bool", "false"],
        ["com.apple.finder", "NSUserKeyEquivalents", "-dict-add", "Enclosing Folder in New Window", "^~@e"],
        ["com.apple.universalaccess", "com.apple.custommenu.apps", "-array-add", "com.apple.finder"],
    ]
    assert m.runs == [["killall", "cfprefsd"]]
    assert said[-1] == "Relaunch these apps to pick up changes: cc.ffitch.shottr com.apple.finder"


def test_apply_skips_sandboxed_and_dry_run_writes_nothing():
    m, said = FakeMachine(sandboxed={"cc.ffitch.shottr"}), []
    rows = _with("app", 0, keys="⇧⌥1")
    rows = {**rows, "menu": [Menu("com.apple.finder", "Enclosing Folder in New Window", "⌃⌥⌘e")]}
    assert shortcuts.apply(rows, m, dry_run=True, say=said.append)
    assert m.writes == [] and m.runs == []
    assert said[0].startswith("skip") and "set it by hand" in said[0]
    assert said[1].startswith("would run  defaults write com.apple.finder")


def test_apply_reports_a_failed_write():
    m, said = FakeMachine(write_ok=False), []
    assert not shortcuts.apply(_with("menu", 0, keys="⌃⌥⌘e"), m, say=said.append)
    assert "set it by hand" in said[0]


@pytest.mark.parametrize("body, match", [
    ('[[app]]\ndomain = "d"\nname = "n"\nkeys = "⌘⇧4"\n', "order"),
    ('[[app]]\ndomain = "d"\nname = "n"\nkeys = "⌥~"\n', "canonical"),
    ('[[app]]\ndomain = "d"\nname = "n"\nkeys = "🌐q"\n', "fn"),
    ('[[menu]]\ndomain = "d"\nitem = "i"\nkeys = "num1"\n', "menu"),
    ('[[menu]]\ndomain = "d"\nitem = "i"\n', "exactly"),
    ('[[other]]\nx = 1\n', "unknown tables"),
    ('[[app]]\ndomain = "d"\nname = "n"\nkeys = "none"\n' * 2, "twice"),
])
def test_load_rejects(tmp_path, body, match):
    path = tmp_path / "s.toml"
    path.write_text(body, encoding="utf-8")
    with pytest.raises(ValueError, match=match):
        shortcuts.load(str(path))


def _wrap(fragment):
    return ('<?xml version="1.0" encoding="UTF-8"?><plist version="1.0">' + fragment + "</plist>").encode()


@pytest.mark.parametrize("stored", [False, 0])
def test_app_none_reads_from_false_and_zero(stored):
    assert shortcuts._app_keys(stored) == "none"


def test_app_true_is_not_none():
    with pytest.raises(ValueError):
        shortcuts._app_keys(True)


def test_apply_global_menu_write_restarts_cfprefsd():
    m = FakeMachine()
    rows = {"system": [], "app": [], "menu": [Menu("NSGlobalDomain", "Zoom", "⌃⌥⌘z")]}
    assert shortcuts.apply(rows, m, say=lambda _: None)
    assert ["killall", "cfprefsd"] in m.runs


def test_unreadable_domain_is_skipped_with_a_warning(monkeypatch, capsys):
    monkeypatch.setattr(shortcuts.subprocess, "run", lambda *a, **k: shortcuts.subprocess.CompletedProcess(
        a[0], 0, stdout=b"<plist><dict><key>x</key>", stderr=b""))
    assert shortcuts.Machine().export("com.example.broken") == {}
    assert "com.example.broken" in capsys.readouterr().err


def _app(domain, name):
    return next(r for r in DECLARED["app"] if (r.domain, r.name) == (domain, name))


def _only(*apps):
    return {"system": [], "app": list(apps), "menu": []}


def test_load_defaults_format_to_keyboardshortcuts(tmp_path):
    path = tmp_path / "s.toml"
    path.write_text('[[app]]\ndomain = "d"\nname = "n"\nkeys = "⌘1"\n', encoding="utf-8")
    assert shortcuts.load(str(path))["app"] == [App("d", "n", "⌘1", "keyboardshortcuts")]


@pytest.mark.parametrize("body, match", [
    ('[[app]]\ndomain = "d"\nname = "n"\nformat = "morse"\nkeys = "⌘1"\n', "not one of"),
    ('[[app]]\ndomain = "d"\nname = "n"\nformat = "ice"\nkeys = "⌘1"\n', "REGISTRY"),
    ('[[app]]\ndomain = "pbs"\nname = "n"\nformat = "services"\nkeys = "num1"\n', "menu"),
])
def test_load_rejects_bad_formats(tmp_path, body, match):
    path = tmp_path / "s.toml"
    path.write_text(body, encoding="utf-8")
    with pytest.raises(ValueError, match=match):
        shortcuts.load(str(path))


@pytest.mark.parametrize("fmt, raw, chord", [
    ("masshortcut", {"keyCode": 8, "modifierFlags": 786432}, "⌃⌥c"),
    ("masshortcut", {"keyCode": 120, "modifierFlags": 8650752}, "⌃F2"),
    ("carbon-dict", {"keyCode": 38, "modifierFlags": 6912}, "⇧⌃⌥⌘j"),
    ("ice", b"null", "none"),
    ("ice", b"[37,9]", "⌃⌘l"),
    ("services", {"key_equivalent": "~^$J"}, "⇧⌃⌥j"),
    ("services", {"key_equivalent": "^J"}, "⇧⌃j"),
    ("services", {"key_equivalent": "@$k"}, "⇧⌘k"),
    ("services", {"enabled_context_menu": False}, "none"),
])
def test_format_decodes(fmt, raw, chord):
    assert shortcuts.FORMATS[fmt].decode(raw) == chord


@pytest.mark.parametrize("fmt", ["keyboardshortcuts", "masshortcut", "carbon-dict", "services"])
@pytest.mark.parametrize("chord", ["⇧⌘4", "⌃⌥c", "⇧⌃⌥⌘j", "⌥F19"])
def test_writable_formats_round_trip(fmt, chord):
    f = shortcuts.FORMATS[fmt]
    assert f.decode(f.encode(chord, None)) == chord


@pytest.mark.parametrize("row, live", [
    (App("com.mowglii.ItsycalApp", "GlobalShortcut", "⌃⌥d", "masshortcut"), "⌃⌥c"),
    (App("com.jordanbaird.Ice", "EnableIceBar", "⌃⌘l", "ice"), "none"),
    (App("pbs", SHORTCUT_J, "none", "services"), "⇧⌃⌥j"),
    (App("pbs", "com.apple.Terminal - New Terminal at Folder - newTerminalAtFolder", "⇧⌃t", "services"), "none"),
])
def test_check_differs_per_format(row, live):
    assert _statuses(_only(row), FakeMachine()) == [(shortcuts.ident(row), "differs", live)]


def test_absent_dict_hotkey_is_none():
    row = App("com.mowglii.ItsycalApp", "GlobalShortcut", "none", "masshortcut")
    m = FakeMachine()
    del m.prefs["com.mowglii.ItsycalApp"]["GlobalShortcut"]
    assert _statuses(_only(row), m) == [(shortcuts.ident(row), "ok", "none")]


def test_group_container_is_unwritable():
    row = App(shortcuts.DAY_ONE, "DOMenuEntryGlobalShortcut", "⌃⌥j", "carbon-dict")
    [(_, status, live)] = _statuses(_only(row), FakeMachine())
    assert (status, live) == ("unwritable", "⇧⌃⌥⌘j")


def test_apply_masshortcut_writes_a_dict():
    m = FakeMachine()
    shortcuts.apply(_only(App("com.mowglii.ItsycalApp", "GlobalShortcut", "⌃⌥d", "masshortcut")), m,
                    say=lambda _: None)
    [args] = m.writes
    assert args[:2] == ["com.mowglii.ItsycalApp", "GlobalShortcut"]
    assert plistlib.loads(_wrap(args[2])) == {"keyCode": 2, "modifierFlags": 786432}
    assert m.runs == [["killall", "cfprefsd"]]


def test_apply_services_keeps_the_other_fields_and_updates_pbs():
    m, said = FakeMachine(), []
    shortcuts.apply(_only(App("pbs", TERMINAL_TAB, "⇧⌃t", "services")), m, say=said.append)
    [args] = m.writes
    assert args[:4] == ["pbs", "NSServicesStatus", "-dict-add", TERMINAL_TAB]
    entry = plistlib.loads(_wrap(args[4]))
    assert entry["key_equivalent"] == "^$t" and entry["presentation_modes"] == {
        "ContextMenu": False, "ServicesMenu": False}
    assert m.runs == [["killall", "cfprefsd"], list(shortcuts.PBS_UPDATE)]
    assert not any("Relaunch" in line for line in said)


def test_apply_services_none_drops_the_key():
    m = FakeMachine()
    shortcuts.apply(_only(App("pbs", "com.apple.finder - Finder/Reveal - reveal", "none", "services")), m,
                    say=lambda _: None)
    assert "key_equivalent" not in plistlib.loads(_wrap(m.writes[0][4]))


@pytest.mark.parametrize("row, words", [
    (App("com.jordanbaird.Ice", "EnableIceBar", "⌃⌘l", "ice"), ("Ice", "read-only", "Ice ▸ Settings ▸ Hotkeys")),
    (App("com.mowglii.ItsycalApp", "GlobalShortcut", "none", "masshortcut"), ("Itsycal", "deleting the key")),
])
def test_apply_refuses_what_it_cannot_write(row, words):
    m, said = FakeMachine(), []
    assert shortcuts.apply(_only(row), m, say=said.append)
    assert m.writes == [] and said[0].startswith("refuse")
    assert all(w in said[0] for w in words)


def _taps_fixture():
    with open(os.path.join(HERE, "fixtures", "taps.json"), encoding="utf-8") as fh:
        data = json.load(fh)
    return data["taps"], data["names"]


@pytest.mark.parametrize("mask, names", [
    (1 << 10, ["keyDown"]),
    ((1 << 10) | (1 << 11) | (1 << 12), ["keyDown", "keyUp", "flagsChanged"]),
    (1 << 14, ["systemDefined"]),
    (1 << 28, ["type28"]),
    (shortcuts.ALL_EVENTS, ["all"]),
])
def test_event_names(mask, names):
    assert shortcuts.event_names(mask) == names


def test_decode_taps_flags_twins_and_disabled_active_taps():
    rows = shortcuts.decode_taps(*_taps_fixture())
    assert len(rows) == 26
    notch = [r for r in rows if r["process"] == "Boring Notch"]
    assert len(notch) == 3 and all(r["events"] == ["systemDefined"] and r["active"] for r in notch)
    assert all(r["warnings"] == ["3 active taps with this mask in one process"] for r in notch)
    raycast = next(r for r in rows if r["process"] == "Raycast")
    assert (raycast["point"], raycast["events"], raycast["warnings"]) == ("hid", ["keyDown"], [])
    alttab_keys = next(r for r in rows if r["process"] == "AltTab" and r["events"] == ["keyDown"])
    assert not alttab_keys["enabled"] and "disabled" in alttab_keys["warnings"][0]
    listen_off = next(r for r in rows if r["process"] == "universalaccessd" and not r["enabled"])
    assert not listen_off["active"] and listen_off["warnings"] == []
    targeted = next(r for r in rows if r["process"] == "Forkgram")
    assert targeted["point"] == "pid 3860 (Forkgram)"


def test_taps_command_prints_warnings(capsys):
    class TapMachine:
        def taps(self):
            return _taps_fixture()
    assert shortcuts.main(["taps"], machine=TapMachine()) == 0
    out = capsys.readouterr().out
    assert "Boring Notch" in out and "! 3 active taps with this mask in one process" in out
    assert shortcuts.main(["taps", "--json"], machine=TapMachine()) == 0
    assert len(json.loads(capsys.readouterr().out)) == 26
