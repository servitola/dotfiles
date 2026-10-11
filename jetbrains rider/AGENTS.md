# jetbrains rider — Rider's files the repo keeps

- `rider.vmoptions` — linked into `~/Library/Application Support/JetBrains/Rider/` by `install/07-config-links.sh`.
- `keymap.xml` — the active custom keymap, copied from the newest `~/Library/Application Support/JetBrains/Rider*/keymaps/`
  by `python3 docs/keyboard/rider.py capture` (`up` runs it). Rider is the source, this file follows it: change a
  shortcut in Rider ▸ Settings ▸ Keymap and the next `up` captures it; commit the diff. JetBrains stores only the
  differences from the parent keymap (`Mac OS X 10.5+`), so every `<action>` here is a customization and an empty
  one a removed default. `docs/keyboard/tools/normalize.py --project` writes them into the HotKeys key tables as
  `ℝ` lines; lint `S5` warns when a Hammerspoon chord shadows a Rider shortcut (`docs/keyboard-setup.md` →
  *Projection into the key tables*).
- `settings.zip` — a 2025 settings export, not consumed by anything here.
