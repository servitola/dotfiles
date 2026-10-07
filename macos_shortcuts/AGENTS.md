# macos_shortcuts — the Mac's hotkeys that live outside this repo, as one file

Karabiner and Hammerspoon are configured in this repo. Everything else that grabs a
key combination stores it in macOS preferences: System Settings shortcuts, an app's
own global hotkey (Shottr, Maccy, Itsycal, ChatGPT, …), shortcuts on menu items.
`shortcuts.toml` lists all of them, one row each, so a new Mac gets the same keys and
the keyboard lint can see what macOS would swallow before Hammerspoon does.

| Command | Does |
| --- | --- |
| `python3 shortcuts.py capture --write` | rewrites `shortcuts.toml` from this Mac. `up` runs it on every pass |
| `python3 shortcuts.py check` | read-only diff, file vs Mac; exit 1 on any difference |
| `python3 shortcuts.py apply [--dry-run]` | writes the differing rows to the Mac. Install step 17 runs it |
| `python3 shortcuts.py taps` | who holds a CoreGraphics event tap on the keyboard |

- **The Mac is the source, the file follows it.** Change a hotkey where it lives
  (System Settings, the app), and the next `up` captures it; commit the diff. Editing
  the TOML and running `apply` works too.
- Because `up` captures, running it on a Mac whose hotkeys were never applied rewrites
  the file with that Mac's state. Run `apply` (install step 17) there first.
- Row kinds, chord grammar, app storage formats and what cannot be written (sandboxed
  apps, Ice, Day One) — the script's docstring and `docs/keyboard-setup.md` →
  *Machine shortcuts*. Chord ↔ keycode conversion is `docs/keyboard/keycodes.py`.
- The keyboard lint (`docs/keyboard/tools/lint.py`, pre-commit) reads this file:
  S1 — a layout chord is also an enabled system shortcut; S2/S3 — collisions inside
  the file.
- Tests: `uvx pytest macos_shortcuts/tests` — plist fixtures of real app stores, no live Mac needed.
