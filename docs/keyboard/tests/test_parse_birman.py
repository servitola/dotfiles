import os
import sys

import pytest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import parse_birman as pb


def lua(tmp_path, text):
    path = tmp_path / "t.lua"
    path.write_text(text, encoding="utf-8")
    return pb.read_lua_table(str(path))


def test_reader_takes_the_shapes_the_generated_files_use(tmp_path):
    assert lua(tmp_path, '-- c\nreturn {\n  keys = { [5] = { opt = "©", shift_opt = false } },\n  ["*"] = { x = true; },\n}\n') == {
        "keys": {5: {"opt": "©", "shift_opt": False}}, "*": {"x": True}}


@pytest.mark.parametrize("literal, text", [
    (r'"a\"b\\c"', 'a"b\\c'), (r'"\0015"', "\x015"), (r'"\u{302}"', "̂"), (r"'\''", "'"), (r'"\n"', "\n")])
def test_reader_unescapes_lua_strings(tmp_path, literal, text):
    assert lua(tmp_path, f"return {{ v = {literal} }}") == {"v": text}


@pytest.mark.parametrize("text", ["return { 1, 2 }", "local t = {} return t", "return { a = b }"])
def test_reader_refuses_anything_but_a_literal_table(tmp_path, text):
    with pytest.raises((ValueError, KeyError)):
        lua(tmp_path, text)


def test_merge_replaces_leaves_and_merges_rows():
    into = {"keys": {5: {"opt": False, "shift_opt": {"dead": "acute"}}}}
    pb._merge(into, {"keys": {5: {"opt": "©"}, 6: {"opt": {"pass": True}}}})
    assert into == {"keys": {5: {"opt": "©", "shift_opt": {"dead": "acute"}}, 6: {"opt": {"pass": True}}}}


def test_layers_on_this_machine():
    keys = pb.parse_birman()
    assert keys["g"]["option"] == ("", "", "©"), "Birman leaves ⌥g empty; Greek is excluded, so Apple's ⌥g"
    assert keys["c"]["option"] == ("©", "©", "ç")
    assert keys["tilde"]["base"][:2] == ("`", "ё")
    assert keys["semicolon"]["option"] == ("‘", "‘", "΅"), "Greek is excluded: Apple's own ⌥; is the dialytika-tonos"
    assert keys["slash"]["shift_option"][0] == "´"
