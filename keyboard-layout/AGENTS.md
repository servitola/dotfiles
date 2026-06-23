# keyboard-layout — the Ilya Birman custom OS keyboard layout (Core)

The custom macOS keyboard layout the whole keyboard system assumes. Without it
the Birman columns in the Hammerspoon layout tables and the characters keys type
don't match.

- `Birman.bundle/` — a Ukelele keyboard-layout bundle. `Contents/Resources/*.keylayout`
  are the XML source files (en / ru / el "Birman" variants), editable in the
  Ukelele app.
- Installed to `~/Library/Keyboard Layouts/` and selected as the default input
  source in macOS (en + ru Birman); `hammerspoon/set_language_on_app_focused.lua`
  switches between these per active app.
- **Source of truth for the `birman` column** in `hammerspoon/Spoons/HotKeys.spoon/layout/60%/*.lua`
  ASCII tables: `docs/keyboard/parse_birman.py` reads these `.keylayout` files and
  `docs/keyboard/tools/lint.py` (D2 check) verifies the lua tables match.
- Pipeline position: **karabiner → birman → hammerspoon**. Karabiner remaps
  physical keys; this layout decides which character those keys type; Hammerspoon
  binds chords on top. See `docs/keyboard-setup.md`.
- Edit in Ukelele → re-export `.keylayout` → re-install → re-run the keyboard
  lint / SVG regen so the docs stay in sync.
