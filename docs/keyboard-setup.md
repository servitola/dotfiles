# Keyboard Setup Guide

Complete documentation of the keyboard customization system including Karabiner-Elements, Hammerspoon, custom layouts, and shortcuts.

## Overview

The keyboard setup consists of three main components:
- **Karabiner-Elements**: Remaps original keyboard to my set of keycodes. Including Caps Lock (Hyper) as all 4 right modifiers at once
- **Custom Layout**: Birman keyboard layout in keyboard-layout directory is installed and used as the default layout in OS
- **Hammerspoon**: Catches key events and runs the apps and specific functions

## Key Concepts

- **External 60% keyboard compatibility**: Same behavior on both internal and 60% external keyboards
- **60% keyboard usage**: Fn key bound to left Control, media keys remain media keys
- **Same topic actions on same keys**: Related functionality uses consistent keys across different contexts (e.g., Hyper+G = Git client, Rider Ctrl+G = Git window, Rider Ctrl+Shift+G = file history)
- **Not changing macOS default shortcuts**: Respect system shortcuts to avoid conflicts
- **Left-hand focus**: Left hand can access all needed work shortcuts for ergonomic efficiency
- **Shortcut accessibility hierarchy**: Easy-to-reach shortcuts for frequent actions, harder combinations (Ctrl+Shift+Hyper) for less frequent but important functions

## Karabiner-Elements Configuration

### Caps Lock Remapping
Caps Lock is remapped to Hyper (Right Shift + Right Command + Right Control + Right Option) with karabiner

## Hammerspoon Configuration

#### Hyper Layer Layout (Caps Lock + Key)
The Hyper layer provides quick access to applications, navigation, and media controls using Caps Lock (remapped to Hyper) + key combinations:

```
╭—————╮__11.HYPER_______╭—————┬————————┬————————┬——————┬—————┬—————┬—————┬—————┬—————┬——————╮
│  ⎋  │ F1  │ F2  │ F3  │ F4  │   F5   │   F6   │  F7  │ F8  │ F9  │ F10 │ F11 │ F12 │    ⌦ │
├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┴—┬——————┴—┬————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
│  ↩    │PgUp │  ↑  │PgDn │  ℝ  │Telegram│  IINA  │      │     │  ↑  │Music│ ⏮  │  ⏭  │    │
├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
│ 🟢🟢🟢  │  ←  │  ↓  │  →  │  📁  │Fork🔄  │Firefox │      │  ←  │  ↓  │  →  │ 🔊  │     │   │
├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
│         │ AI  │home │ end │ 🌐  │ Warp │   📝    │      │home │ end │ 🔉  │              │
├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴——————┼—————┴┬————┴┬————┴——————————————╯
│        │     │      │           play/stop                │      │     │
╰————————┴—————┴——————┴————————————————————————————————————┴——————┴—————╯
```

**Key mappings:**
- **Applications**: R=Rider, T=Telegram, Y=IINA, F=Finder, G=Fork, H=Firefox, P=Music, V=Yandex, B=Warp, N=VSCode
- **Navigation**: Tab=Enter, Q/E=PageUp/Down, W/A/S/D=Arrows, X/C=Home/End
- **Media**: [/]=Previous/Next, '=Volume Up, /=Volume Down
- **Special**: Z=Opcode (AI), Space=Play/Pause

## Extended Layers

**Ctrl + Shift + Hyper**: Media player controls (harder to press, for less frequent but important functions)

## Custom Keyboard Layout

### Ilya Birman Layout
The system uses Ilya Birman's custom keyboard layout with:
- **English**: Optimized for programming with additional symbols
- **Russian**: Cyrillic layout optimized for typing

### Layout Creation (Ukelele)
- **Tool**: Ukelele keyboard layout editor
- **Source Files**: XML `.keylayout` files in `Birman.bundle/Contents/Resources/`
- **Editable**:

## Layout System

The shortcut system uses a **per-key architecture** in `layout/60%/`. Each physical key has its own `.lua` file containing all modifier combinations for that key.

### Per-Key Layout Architecture (Current)

Each key file (e.g., `a.lua`, `w.lua`, `space.lua`) returns an array of chord entries. The `HotKeys.spoon/init.lua` loads all key files, collects chord entries, and binds them based on type (`app`, `fn`, or `sendKey`).

### Key File Format

Each key file returns an array of chord definitions:

```lua
return {
  { chord = "⇪a", app = "Finder" },                          -- Hyper+A launches Finder
  { chord = "⌃⌥a", fn = "window.left" },                     -- Ctrl+Alt+A triggers window function
  { chord = "⇪a", app = "Fork", window_default_position = "left" },  -- With window positioning
}
```

#### Chord Syntax:
- `⇪` = Hyper (Caps Lock)
- `⌃` = Control
- `⌥` = Option/Alt
- `⇧` = Shift
- `⌘` = Command

#### Entry Types:
- **`app`**: Application name to launch/focus/hide toggle
- **`fn`**: Custom function name from `init.lua` dispatch (e.g., `"window.left"`, `"audio.internal"`)
- **`sendKey`**: Key to send (for remapping, e.g., arrow keys)
- **`window_default_position`**: Optional positioning (`"left"`, `"right"`, `"bottom"`)

### Key File Documentation

Each key file also contains extensive ASCII art comments documenting ALL modifier combinations for that physical key, including:
- macOS defaults
- Karabiner remappings
- App-specific shortcuts (Rider, VSCode, Fork, etc.)
- Birman layout special characters

### Legacy Layout Files

The old 30 numbered layout files (`01. English.lua` through `30. Shift_Alt_Command.lua`) are preserved in `Hotkeys.spoon/old/` for reference but are NOT loaded.

## Customization

### Adding New Shortcuts
1. Edit the key file in @./hammerspoon/Spoons/Hotkeys.spoon/layout/60%/
2. Add a new chord entry to the returned array:

**Example - Adding Slack to Hyper+S:**
```lua
-- in s.lua
{ chord = "⇪s", app = "Slack" },
```

3. Hammerspoon auto-reloads on file save (ensure valid Lua syntax)

## Visual Reference

See **@./keyboard/** for auto-generated SVG diagrams of all 24 shortcut layers with app icons, category colors, and modifier highlighting.

Regenerate: `python3 docs/keyboard/generate.py`

## Files Reference

- @./karabiner/rules/ - Karabiner rule files (source of truth, `karabiner.json` is generated via `build.sh`)
- @./hammerspoon/init.lua - Main Hammerspoon configuration
- @./hammerspoon/Spoons/Hotkeys.spoon/ - Shortcut definitions
- @./hammerspoon/Spoons/Hotkeys.spoon/layout/60%/ - Per-key layout files (current system)
- @./hammerspoon/Spoons/Hotkeys.spoon/old/ - Legacy 30 numbered layout files (reference only)
- @./keyboard-layout/Birman.bundle/ - Custom keyboard layout (Ukelele bundle)
- @./keyboard-layout/Birman.bundle/Contents/Resources/*.keylayout - Ukelele XML source files
- @./keyboard/ - Auto-generated SVG keyboard shortcut diagrams
