# HotKeys Spoon Rules

## Layout File Structure
- Each file in `layout/60%/` returns a flat array of chord entries: `return { {chord=…}, … }`
- Files named after physical keys: `a.lua`, `space.lua`, `return.lua`, etc.
- All button files loaded via `buttonFiles` array in `init.lua`
- Canonical ASCII format enforced by `docs/keyboard/tools/lint.py` (pre-commit hook)
- Auto-fix format and insert missing rows: `python3 docs/keyboard/tools/normalize.py --insert-missing`

## Chord Definition Format
```lua
{ chord = "⇪v", app = "@APP_BROWSER" }
{ chord = "⌃F19", fn = "vpn.toggle_globalprotect" }
```

## Valid Chord Attributes
- `chord` - Required: Key combination (emoji symbols or Fn key)
- `app` - Launch/focus application (must match macOS name exactly, case-sensitive), or `"@APP_BROWSER"` / `"@APP_TERMINAL"` — a key from `constants.env`, resolved at load. Use the constant when the chord means a role ("my browser") rather than one specific app; lint rule C2 fails on an unknown key.
- `fn` - Custom function name (must be defined in init.lua:232-365)
- `window_default_position` - Optional: "left", "right", or "bottom"
- `sendKey` - Type text string when pressed

## Modifier Symbols
- `⇪` = Hyper (Caps Lock remapped in Karabiner)
- `⌘` = Command, `⌥` = Option, `⌃` = Control, `⇧` = Shift
- Karabiner remaps keys to F-keys (e.g., `⇪v` → `F19`)

## Documentation Format (canonical 5-column)
```
-- chord │ karabiner │ en | ru | el │ G │ app — function
-- ⇪w    │     ↑     │              │   │         — up
```
Column geometry: `│` at positions [17, 32, 47, 51]. See `a.lua` for the reference.
- **Chord column**: pressed combination, right-aligned (last char at position 13)
- **Karabiner column**: what Karabiner sends (mirrors `karabiner/rules/*.json`)
- **Birman column**: layout characters in `en  ru  el` order (mirrors `Birman.bundle/*.keylayout`)
- **G column**: `✓` if global macOS default, blank otherwise
- **Description**: `App — function` or `— function` for global; optional `B:`/`ⓘ:` tags

Validate: `python3 docs/keyboard/tools/lint.py`
Auto-fix format + insert missing rows: `python3 docs/keyboard/tools/normalize.py --insert-missing`

## Critical Rules
- ASCII art comments must match actual chord definitions
- App names are case-sensitive: "Visual Studio Code" not "vscode"
- **Always reload after changes**: `hs -c "hs.reload()"`
- Hammerspoon auto-reloads on save, but if config breaks it won't reload
- Check for errors: `open -a "Hammerspoon Console"` or check notification
- If adding new `fn`, must implement handler in init.lua:232-365

## Anti-Patterns
- Don't use generic key names like "v" - use mapped F-key from Karabiner
- Don't create chords without ASCII art documentation
- Don't reference non-existent apps or functions

## References
- Main logic: @./init.lua
- Keyboard guide: @../../../docs/keyboard-setup.md
