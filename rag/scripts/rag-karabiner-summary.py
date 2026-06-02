#!/usr/bin/env python3
"""rag-karabiner-summary — regenerate karabiner/rules/SUMMARY.md from *.json.

The raw Karabiner rule JSON is repetitive and nearly impossible for a free
embed model to distinguish across files. This generator produces one readable
markdown file listing every mapping in the form:

    ## 07-hyper-only.json — Hyper Layer (only)
    - Hyper+V → f19
    - Hyper+R → f17

RAG ingest picks up the markdown naturally (.md is in DEFAULT_EXTENSIONS), and
retrieval on "what does Hyper+Z do?" finds the chunk where the mapping
literally appears.

Run:
    ./scripts/rag-karabiner-summary.py
    # writes ~/projects/dotfiles/karabiner/rules/SUMMARY.md
"""

from __future__ import annotations

import json
import sys
from pathlib import Path


HYPER = frozenset({"right_command", "right_control", "right_option", "right_shift"})

MOD_DISPLAY = {
    "left_shift": "Shift",
    "right_shift": "Shift",
    "left_command": "Cmd",
    "right_command": "Cmd",
    "left_control": "Ctrl",
    "right_control": "Ctrl",
    "left_option": "Opt",
    "right_option": "Opt",
    "caps_lock": "CapsLock",
    "fn": "Fn",
}

KEY_DISPLAY = {
    "grave_accent_and_tilde": "`",
    "non_us_backslash": "§",
    "delete_or_backspace": "Backspace",
    "delete_forward": "Delete",
    "return_or_enter": "Enter",
    "spacebar": "Space",
    "escape": "Esc",
    "tab": "Tab",
    "up_arrow": "↑",
    "down_arrow": "↓",
    "left_arrow": "←",
    "right_arrow": "→",
    "page_up": "PageUp",
    "page_down": "PageDown",
    "home": "Home",
    "end": "End",
    "open_bracket": "[",
    "close_bracket": "]",
    "semicolon": ";",
    "quote": "'",
    "comma": ",",
    "period": ".",
    "slash": "/",
    "backslash": "\\",
    "hyphen": "-",
    "equal_sign": "=",
}


def fmt_modifiers(mods: list[str]) -> list[str]:
    mod_set = set(mods)
    parts: list[str] = []
    if HYPER.issubset(mod_set):
        parts.append("Hyper")
        mod_set -= HYPER
    for name in sorted(mod_set):
        parts.append(MOD_DISPLAY.get(name, name))
    return parts


def fmt_key(key: str) -> str:
    return KEY_DISPLAY.get(key, key)


def fmt_from(frm: dict) -> str:
    key = frm.get("key_code") or frm.get("consumer_key_code") or frm.get("pointing_button") or "?"
    mods = frm.get("modifiers", {}).get("mandatory", [])
    chord = fmt_modifiers(mods)
    chord.append(fmt_key(key))
    return "+".join(chord)


def fmt_to(to_item: dict) -> str:
    if "key_code" in to_item:
        key = fmt_key(to_item["key_code"])
        mods = to_item.get("modifiers") or []
        if mods:
            mod_parts = fmt_modifiers(mods)
            return "+".join(mod_parts + [key])
        return key
    if "shell_command" in to_item:
        cmd = to_item["shell_command"]
        return f"shell: `{cmd[:80]}{'…' if len(cmd) > 80 else ''}`"
    if "set_variable" in to_item:
        v = to_item["set_variable"]
        return f"set var {v.get('name')}={v.get('value')}"
    if "consumer_key_code" in to_item:
        return to_item["consumer_key_code"]
    if "pointing_button" in to_item:
        return f"mouse {to_item['pointing_button']}"
    if "mouse_key" in to_item:
        return f"mouse {to_item['mouse_key']}"
    return "…"


def fmt_to_list(to_list: list[dict]) -> str:
    parts = [fmt_to(t) for t in to_list]
    return ", ".join(parts)


def summarize_manipulator(man: dict) -> str | None:
    frm = man.get("from")
    if not isinstance(frm, dict):
        return None
    left = fmt_from(frm)

    segments: list[str] = []

    to_list = man.get("to")
    if isinstance(to_list, list) and to_list:
        segments.append(fmt_to_list(to_list))

    alone = man.get("to_if_alone")
    if isinstance(alone, list) and alone:
        segments.append(f"tap: {fmt_to_list(alone)}")

    held = man.get("to_if_held_down")
    if isinstance(held, list) and held:
        segments.append(f"hold: {fmt_to_list(held)}")

    after_up = man.get("to_after_key_up")
    if isinstance(after_up, list) and after_up:
        segments.append(f"on-release: {fmt_to_list(after_up)}")

    if not segments:
        return None

    return f"- {left} → {' | '.join(segments)}"


def summarize_rule_file(path: Path) -> str:
    try:
        obj = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return f"## {path.name}\n\n_Parse error: {exc}_\n"
    description = obj.get("description") or path.stem
    mans = obj.get("manipulators")
    if not isinstance(mans, list):
        return f"## {path.name} — {description}\n\n_No manipulators._\n"

    lines = [f"## {path.name} — {description}", ""]
    for man in mans:
        if isinstance(man, dict):
            rendered = summarize_manipulator(man)
            if rendered:
                lines.append(rendered)
    lines.append("")
    return "\n".join(lines)


def main() -> int:
    rules_dir = Path.home() / "projects" / "dotfiles" / "karabiner" / "rules"
    if not rules_dir.is_dir():
        print(f"rag-karabiner-summary: {rules_dir} does not exist", file=sys.stderr)
        return 1

    rule_files = sorted(rules_dir.glob("*.json"))
    if not rule_files:
        print(f"rag-karabiner-summary: no JSON rules in {rules_dir}", file=sys.stderr)
        return 1

    out = [
        "# Karabiner Rule Summaries",
        "",
        "Human-readable index of every manipulator in every rule file.",
        "Auto-generated by `rag/scripts/rag-karabiner-summary.py` — do not edit by hand.",
        "Re-run after changing any file under `karabiner/rules/`.",
        "",
        "Modifier shorthand: `Hyper` = right_command+right_control+right_option+right_shift (Caps Lock remap).",
        "",
    ]
    for f in rule_files:
        out.append(summarize_rule_file(f))

    target = rules_dir / "SUMMARY.md"
    target.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {target}  ({len(rule_files)} rule files, {sum(1 for l in out if l.startswith('- '))} manipulators)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
