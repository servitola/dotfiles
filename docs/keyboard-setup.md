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
│ 🟢🟢🟢  │  ←  │  ↓  │  →  │  📁  │Fork🔄  │ Safari │      │  ←  │  ↓  │  →  │ 🔊  │     │   │
├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
│         │ AI  │home │ end │ 🌐  │ Warp │   📝    │      │home │ end │ 🔉  │              │
├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴——————┼—————┴┬————┴┬————┴——————————————╯
│        │     │      │           play/stop                │      │     │
╰————————┴—————┴——————┴————————————————————————————————————┴——————┴—————╯
```

**Key mappings:**
- **Applications**: R=Rider, T=Telegram, Y=IINA, F=Finder, G=Fork, H=Safari, P=Music, V=Yandex, B=iTerm2, N=VSCode
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

The shortcut system uses **30 different modifier combinations**, each with its own keyboard layout:

### Layout Organization
- **Base Layers (01-10)**: Single modifiers (English, Russian, Greek, Alt, Command, Control)
- **Hyper Layers (11-15)**: Hyper + optional additional modifiers
- **Complex Layers (16-30)**: Multi-modifier combinations (Command+Shift, Control+Alt, etc.)

### Layout File Structure
Each layout file contains:
- **Modifier definition**: Which key combination activates the layout
- **Visual layout**: ASCII art showing what each key does
- **Key definitions**: Specific chord mappings for applications and functions

### Lua File Format

Each layout file is a Lua table with the following structure:

```lua
return {
  modifier = {"modifier1", "modifier2"},  -- Array of modifier keys that activate this layer
  chords = {                             -- Array of key mappings
    { key = "a", app = "Application Name" },                    -- Launch app
    { key = "b", specific_function = "function_name" },         -- Run custom function
    { key = "c", app = "App", window_default_position = "left" } -- Launch with window positioning
  }
}
```

#### Attributes:

- **`modifier`**: Array of Hammerspoon modifier names (`"hyper"`, `"left_control"`, `"left_shift"`, `"left_option"`, `"left_command"`)
- **`chords`**: Array of chord definitions containing:
  - **`key`**: The key that triggers the action (single character or key name like `"escape"`, `"tab"`)
  - **`app`**: Application name to launch (must match macOS application name exactly)
  - **`specific_function`**: Name of a custom function defined in `HotKeys.spoon/init.lua` (e.g., `"window.left"`, `"audio.internal"`)
  - **`window_default_position`**: Optional window positioning (`"left"`, `"right"`, `"bottom"`)
### Available Layout Files

**These files serve dual purposes:**
- **Configuration**: Hammerspoon reads them on init and binds shortcuts to actions/apps
- **Documentation**: Comments show the complete user experience including programs used, macOS defaults, Karabiner remappings, and layout modifications

See @./hammerspoon/Spoons/Hotkeys.spoon/layouts/ for all 30 layout files.

### Layout File Descriptions

**Base Layers (01-10)**: Single modifier combinations for general app and system shortcuts
- `01. English.lua` - Base English layout. Mention  YouTube, Music, and Vimium browser shortcust of the layout
- `02. Russian.lua` - Base Russian layout with similar controls
- `03. Greek.lua` - Base Greek layout
- `04. English_Shift.lua` - English + Shift for uppercase/special characters
- `05. Russian_Shift.lua` - Russian + Shift for uppercase/special characters
- `06. Greek_Shift.lua` - Greek + Shift for uppercase/special characters
- `07. Alt.lua` - Option key for Ilya Birman layout symbols
- `08. Alt_Shift.lua` - Option + Shift for additional symbols
- `09. Command Left.lua` - Left Command for app switching and window management
- `09. Command Right.lua` - Right Command (duplicate of left)
- `10. Control.lua` - Control key for text editing and navigation

**Hyper Layers (11-15)**: Hyper key (Caps Lock) + optional additional modifiers
- `11. Hyper.lua` - Main Hyper layer: app launching, navigation, media controls
- `12. Hyper_Alt.lua` - empty almost or use for alt + arrows shortcuts explanation
- `13. Hyper_Command.lua` - empty almost or use for command + arrows shortcuts explanation
- `14. Hyper_Control.lua` - empty almost or use for control + arrows shortcuts explanation
- `15. Hyper_Shift.lua` - empty almost or use for shift + arrows shortcuts explanation
**Complex Layers (16-30)**: Multi-modifier combinations for specialized functions
- `16. Command_Shift.lua` - empty almost or use for command + shift shortcuts explanation
- `17. Command_Alt.lua` - mostly describes shortcuts from different
- `18. Command_Control.lua` - Cmd+Ctrl: System and app-specific controls
- `19. Control_Shift.lua` - Ctrl+Shift: Rider bookmarks, Activity Monitor, text selection
- `20. Control_Alt.lua` -
- `21. Hyper_Alt_Command.lua` -
- `22. Hyper_Alt_Control.lua` -
- `23. Hyper_Alt_Shift.lua` -
- `24. Hyper_Control_Command.lua` -
- `25. Hyper_Command_Shift.lua` - Hyper+Cmd+Shift: Keyboard brightness
- `26. Hyper_Shift_Control.lua` - Hyper+Alt+Ctrl: Advanced media controls
- `27. Control_Alt_Command.lua` -
- `28. Shift_Control_Alt.lua` - Shift+Ctrl+Alt: Complex text manipulation
- `29. Shift_Control_Command.lua` - Shift+Ctrl+Cmd: Advanced editing
- `30. Shift_Alt_Command.lua` -

## Customization

### Adding New Shortcuts
1. Edit layout files in @./hammerspoon/Spoons/Hotkeys.spoon/layouts/
2. Add new chord definitions following the existing pattern:

**Example - Adding Slack to Hyper layer:**
```lua
{ key="s", app="Slack" },
```

3. Hammerspoon configuration reloads itself (so don't make it non compilable during your work)

## Files Reference

- @./karabiner/karabiner.json - Karabiner configuration
- @./hammerspoon/init.lua - Main Hammerspoon configuration
- @./hammerspoon/Spoons/Hotkeys.spoon/ - Shortcut definitions
- @./hammerspoon/Spoons/Hotkeys.spoon/layouts/ - 30 keyboard layout files
- @./keyboard-layout/Birman.bundle/ - Custom keyboard layout (Ukelele bundle)
- @./keyboard-layout/Birman.bundle/Contents/Resources/*.keylayout - Ukelele XML source files
