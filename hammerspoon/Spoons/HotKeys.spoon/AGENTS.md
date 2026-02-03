# HotKeys Spoon Rules

## Layout File Structure
- Each layout file in `layout/60%/` returns `{modifier = {...}, chords = {...}}`
- Files named after keys: `a.lua`, `space.lua`, `return.lua`, etc.
- All button files loaded via `buttonFiles` array in init.lua

## Chord Definition Format
```lua
{ chord = "⇪v", app = "Yandex" }
{ chord = "⌃F19", fn = "vpn.toggle_globalprotect" }
```

## Valid Chord Attributes
- `chord` - Required: Key combination (emoji symbols or Fn key)
- `app` - Launch/focus application (must match macOS name exactly, case-sensitive)
- `fn` - Custom function name (must be defined in init.lua:232-365)
- `window_default_position` - Optional: "left", "right", or "bottom"
- `sendKey` - Type text string when pressed

## Modifier Symbols
- `⇪` = Hyper (Caps Lock remapped in Karabiner)
- `⌘` = Command, `⌥` = Option, `⌃` = Control, `⇧` = Shift
- Karabiner remaps keys to F-keys (e.g., `⇪v` → `F19`)

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
