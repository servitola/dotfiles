#!/usr/bin/env python3
"""Exercises the rule engine, not the shipped policy.

Every RULES entry is "allow" today, so the engine is verified against a locally
patched table: flipping actions here proves that a rule *would* fire, without
asserting anything about what is currently enabled.
"""

import importlib.util
import pathlib
import sys

spec = importlib.util.spec_from_file_location(
    "guard", pathlib.Path(__file__).with_name("guard-desktop-control.py"))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)

DOTFILES = "/Users/servitola/projects/dotfiles"
ELSEWHERE = "/Users/servitola/projects/serho"

SHIPPED_IS_INERT = [
    ("cliclick c:400,300", DOTFILES),
    ("osascript -e 'tell app \"System Events\" to keystroke \"a\"'", DOTFILES),
    ("displayplacer list", DOTFILES),
    ("yabai -m window --move abs:0:0", DOTFILES),
]

# (command, cwd, expected decision or None) against the patched table below.
CASES = [
    ("cliclick c:400,300", DOTFILES, "deny"),
    ("sudo cliclick c:400,300", DOTFILES, "deny"),
    ("FOO=1 rtk cliclick c:400,300", DOTFILES, "deny"),
    ("osascript -e 'tell app \"System Events\" to keystroke \"a\"'", DOTFILES, "deny"),
    ("osascript -e 'set bounds of window 1 to {0,0,100,100}'", DOTFILES, "ask"),
    ("yabai -m window --move abs:0:0", DOTFILES, "ask"),
    ("yabai -m query --windows", DOTFILES, None),
    ("defaults write com.apple.dock autohide -bool true", DOTFILES, "ask"),

    ("hs -c 'hs.reload()'", DOTFILES, None),
    ("hs -c 'os.execute(\"rm -rf /\")'", DOTFILES, "deny"),
    ("hs -c 'os.execute(\"rm -rf /\")'", ELSEWHERE, "deny"),

    ("grep -rn 'set bounds of' hammerspoon/", DOTFILES, None),
    ("cat hammerspoon/Spoons/HotKeys.spoon/layout/60%/v.lua", DOTFILES, None),
    ("echo 'cliclick c:400,300' > notes.txt", DOTFILES, None),
    ("git commit -m 'guard cliclick and keystroke'", DOTFILES, None),

    ("ls && cliclick c:1,1", DOTFILES, "deny"),
    ("unbalanced 'quote", DOTFILES, None),
]

ACTIONS = {
    "hammerspoon-reload": "allow",
    "hammerspoon-arbitrary-lua": "deny",
    "synthetic-input": "deny",
    "applescript-synthetic-input": "deny",
    "applescript-window-geometry": "ask",
    "yabai-window-ops": "ask",
    "display-arrangement": "ask",
    "spaces-and-dock-defaults": "ask",
    "hammerspoon-config-writes-outside-dotfiles": "allow",
}


def run():
    failures = []

    for command, cwd in SHIPPED_IS_INERT:
        got = guard.verdict(command, cwd)
        if got is not None:
            failures.append(f"shipped table is not inert: {command!r} -> {got}")

    for rule in guard.RULES:
        rule["action"] = ACTIONS[rule["name"]]

    for command, cwd, expected in CASES:
        got = guard.verdict(command, cwd)
        decision = got[0] if got else None
        if decision != expected:
            failures.append(
                f"{command!r} in {cwd}: expected {expected}, got {decision}")

    for failure in failures:
        print(f"FAIL {failure}")
    print(f"{len(SHIPPED_IS_INERT) + len(CASES) - len(failures)}"
          f"/{len(SHIPPED_IS_INERT) + len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(run())
