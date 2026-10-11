# HotKeys Spoon Rules

## Layout File Structure
- Each file in `layout/60%/` returns a flat array of chord entries: `return { {chord=…}, … }`
- Files named after physical keys: `a.lua`, `space.lua`, `return.lua`, etc.
- All button files loaded via `buttonFiles` array in `init.lua`
- Canonical ASCII format enforced by `docs/keyboard/tools/lint.py` (pre-commit hook)
- Auto-fix format and insert missing rows: `python3 docs/keyboard/tools/normalize.py --insert-missing`
- Lifecycle: `hs.loadSpoon("HotKeys")` runs `init()` (loads chords, registers built-ins). `hammerspoon/init.lua` then does `require "actions"` and `spoon.HotKeys:start()`, which binds. Anything calling `register` must run between the two.
- Tests: `hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/HotKeys.spoon/tests/test_actions.lua")'` and `tests/test_bind.lua`; each returns `PASS n`.

## Chord Definition Format
```lua
{ chord = "⇪v", app = "@APP_BROWSER" }
{ chord = "⌃F16", fn = "vpn.toggle_globalprotect" }
```

## Valid Chord Attributes
- `chord` - Required: Key combination (emoji symbols or Fn key)
- `app` - Launch/focus application (must match macOS name exactly, case-sensitive), or `"@APP_<ROLE>"` — a key from `constants.env`, resolved at load. Use the constant when the chord means a role ("my browser") rather than one specific app; lint rule C2 fails on an unknown key. Roles in use: `APP_BROWSER`, `APP_BROWSER_ALT`, `APP_BROWSER_WORK`, `APP_TERMINAL`, `APP_TERMINAL_ALT`, `APP_TELEGRAM`, `APP_EDITOR`, `APP_IDE`, `APP_GIT_GUI`, `APP_FILES`, `APP_MUSIC`, `APP_VIDEO`. A literal name is for apps without a role (Finder, Simulator, zoom.us…).
- `fn` - Action name. Must be registered: generic ones in `init.lua` (`registerBuiltins`), personal ones in `hammerspoon/actions/*.lua`. Lint rule A1 fails on an unregistered name; at runtime `start()` shows a red notification listing them.
- `window_default_position` - Optional: `"right"` (PowerWindows side slot) or `"bottom"` (corner); anything else fails the assert in `bindChords`
- `sendKey` - Type text string when pressed

## Modifier Symbols
- `⇪` = Hyper (Caps Lock remapped in Karabiner)
- `⌘` = Command, `⌥` = Option, `⌃` = Control, `⇧` = Shift
- Karabiner renames the eight Hyper slot letters to F-keys by keyboard column (`z r f v t g b h` → `F13`…`F20`), keeping the modifiers: `⇪v` → `F16`, `⇪⌘v` → `⌘F16`. Bind the F-key, not `⇪v`. Table: `karabiner/AGENTS.md` → *Bridge Slots*; `docs/keyboard/tools/bridge.py` lists every code
- `num8` / `num9` are the swap-windows gesture and Punto (Punto binds `pad9` in `hammerspoon/punto_switcher.lua`); `␣` is Space

## Documentation Format (canonical 5-column)
```
-- chord │ karabiner │ en | ru | el │ G │ app — function
-- ⇪w    │     ↑     │              │   │         — up
```
Column geometry: `│` at positions [17, 32, 47, 51]. See `a.lua` for the reference.
- **Chord column**: pressed combination, right-aligned (last char at position 13)
- **Karabiner column**: what Karabiner sends (mirrors `karabiner/rules/*.json`)
- **Birman column**: layout characters in `en  ru  el` order (mirrors `docs/keyboard/parse_birman.py`: Apple's layouts + BirmanLayer.spoon, Apple's ⌥ for `excludedLayouts`; lint D2)
- **G column**: `✓` if global macOS default (hand-written), blank otherwise; `⚙` / `◆` / `ℝ` mark lines that `docs/keyboard/tools/normalize.py --project` writes from `macos_shortcuts/shortcuts.toml` (system hotkey / app hotkey or menu item) and `jetbrains rider/keymap.xml` (Rider customization) — never edit those by hand, they are rewritten on every `up`; lint P1 fails when they drift
- **Description**: `App — function` or `— function` for global; optional `B:`/`ⓘ:` tags

Validate: `python3 docs/keyboard/tools/lint.py`
Auto-fix format + insert missing rows: `python3 docs/keyboard/tools/normalize.py --insert-missing`

## Critical Rules
- ASCII art comments must match actual chord definitions
- App names are case-sensitive: "Visual Studio Code" not "vscode"
- **Always reload after changes**: `hs -c "hs.reload()"`
- Hammerspoon auto-reloads on save, but if config breaks it won't reload
- Check for errors: `open -a "Hammerspoon Console"` or check notification
- New `fn`: add `register("your.name", function() … end)` to the matching file in `hammerspoon/actions/` (or a new file listed in `actions/init.lua`), then the chord entry. Never add dispatch code to `init.lua`.

## Anti-Patterns
- Don't bind `⇪` + a slot letter — Karabiner never lets it through; bind the slot F-key
- Don't create chords without ASCII art documentation
- Don't reference non-existent apps or functions

## References
- Main logic: @./init.lua
- Keyboard guide: @../../../docs/keyboard-setup.md
