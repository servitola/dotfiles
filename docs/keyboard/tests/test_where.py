import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "tools"))

import where


def test_pressed_hyper_letter_traces_to_its_slot():
    info = where.resolve("⇪g")
    assert info["emitted"] == "F18"
    assert [k["rule"] for k in info["karabiner"]] == ["07-hyper-only"]
    binds = info["hammerspoon"]
    assert len(binds) == 1 and binds[0]["file"] == "g.lua" and binds[0]["kind"] == "app"
    assert binds[0]["target"].startswith("Fork (@APP_GIT_GUI)")
    assert info["types"]["state"] is None


def test_emitted_code_traces_back_to_the_press():
    info = where.resolve("⌘F16")
    assert info["pressed"] == "⇪⌘v"
    assert info["karabiner"][0]["rule"] == "09-hyper-command"
    assert "⌘F16" in info["macos"]["as_received"]


def test_system_and_app_rows_on_the_same_chord():
    rows = where.resolve("⇧⌘4")["macos"]["rows"]
    assert {"system", "app"} <= {r["kind"] for r in rows}
    assert any(r["kind"] == "system" and r["id"] == 30 and not r["enabled"] for r in rows)
    assert any(r["kind"] == "app" and r["domain"] == "cc.ffitch.shottr" for r in rows)


def test_simultaneous_partner_does_not_rewrite_a_single_key():
    info = where.resolve("⌃⌥a")
    assert info["emitted"] == "⌃⌥a"
    swap = [k for k in info["karabiner"] if k["rule"] == "32-swap-sides"]
    assert swap and swap[0]["with"] == ["d"] and swap[0]["to"] == "num8"


def test_keypad_exception_names_its_gesture():
    info = where.resolve("num8")
    assert "⌃⌥ad" in info["pressed"]
    assert any(h["target"] == "window.swap_sides" for h in info["hammerspoon"])
    assert "32-swap-sides" in where.render(info)


def test_right_option_shows_the_birman_character():
    t = where.resolve("⌥c")["types"]
    assert t["state"] == "option"
    assert t["layers"]["option"][0] == "©"


def test_left_only_rule_leaves_right_option_to_the_layer():
    info = where.resolve("⌥4")
    assert info["karabiner"][0]["side"] == "left"
    assert info["emitted"] == "num4"
    assert info["types"]["state"] == "option"


def test_modifier_order_is_forgiven():
    assert where.resolve("⌘⇪v")["emitted"] == "⌘F16"


def test_render_mentions_every_section():
    text = where.render(where.resolve("⇪g"))
    for section in ("Karabiner", "Hammerspoon", "macOS and apps", "Types"):
        assert section in text
