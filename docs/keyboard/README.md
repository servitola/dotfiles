# Keyboard Shortcuts — All Layers

Complete visual reference of all keyboard shortcut layers. Auto-generated from [Hammerspoon Lua config](../../hammerspoon/Spoons/Hotkeys.spoon/layout/60%/) and Karabiner rules.

**Legend**: Each key shows its binding with a colored accent bar. Category icons indicate the type:
-  **Apps** (blue) — launch/focus/hide applications
-  **Window Management** (green) — window positioning and sizing
-  **Media / Audio** (orange) — playback, volume, audio source switching
-  **Navigation** (teal) — arrows, page up/down, home/end
-  **Browser / Translate** (purple) — open browser tabs, translate text
-  **System** (red) — reload, VPN, wallpaper
-  **Karabiner** (brown, remap icon) — Karabiner-Elements key remappings (F-keys, navigation, media)
-  **macOS** (gray, Apple icon) — standard macOS shortcuts
-  **Birman Layout** (gray, Б icon) — Ilya Birman keyboard layout characters

Modifier keys participating in each layer are highlighted in blue. Non-participating modifiers are hidden for clarity.

---

## Primary Layers

### Hyper — Apps + Navigation
Caps Lock (remapped to Hyper via Karabiner) + key. The main shortcut layer for launching apps and WASD navigation.

![Hyper](hyper.svg)

### Ctrl + Alt — Window Management
Window positioning: left/right/fullscreen/reset. Also audio source switching (keys 1-4).

![Ctrl + Alt](ctrl-alt.svg)

### Cmd — macOS Standard
Standard macOS shortcuts: copy, paste, cut, undo, quit, find, etc.

![Cmd](cmd.svg)

### Tab — Quick Actions
Tab held as modifier (Karabiner variable-based layer). Browser zoom, navigation, speed control.

![Tab](tab_mod.svg)

---

## Hyper Combo Layers

### Hyper + Shift — Extended Apps
Secondary app assignments and extended navigation (select text, shift-arrows).

![Hyper + Shift](hyper-shift.svg)

### Hyper + Ctrl — Workspaces + Scroll
Workspace switching, scroll without moving caret, terminal panel toggling.

![Hyper + Ctrl](hyper-ctrl.svg)

### Hyper + Alt — Word Operations
Word-level navigation: jump/delete/select by word. Also IDE extend/shrink selection.

![Hyper + Alt](hyper-alt.svg)

### Hyper + Cmd — Line Operations
Line-level operations: home/end of line, delete line, open file dialog.

![Hyper + Cmd](hyper-cmd.svg)

### Shift + Ctrl + Alt — Half-Window
Half-window positioning: left/right halves, top 60%, bottom 40%.

![Shift + Ctrl + Alt](shift-ctrl-alt.svg)

---

## Character Layers

### Base
Default key outputs without any modifiers.

![Base](base.svg)

### Shift
Uppercase letters and shifted symbols.

![Shift](shift.svg)

### Alt — Special Characters + Apps
Birman keyboard layout special characters + app shortcuts.

![Alt](alt.svg)

### Shift + Alt
Birman layout extended characters (uppercase specials).

![Shift + Alt](shift-alt.svg)

---

## Additional Layers

### Ctrl
Control key combinations.

![Ctrl](ctrl.svg)

### Shift + Ctrl
Shift + Control combinations.

![Shift + Ctrl](shift-ctrl.svg)

### Shift + Cmd
Shift + Command combinations.

![Shift + Cmd](shift-cmd.svg)

### Ctrl + Cmd
Control + Command combinations.

![Ctrl + Cmd](ctrl-cmd.svg)

### Alt + Cmd
Option + Command combinations.

![Alt + Cmd](alt-cmd.svg)

---

## Triple Modifier Layers

### Hyper + Shift + Ctrl
Media controls: volume, brightness, track navigation.

![Hyper + Shift + Ctrl](hyper-shift-ctrl.svg)

### Hyper + Shift + Alt
Extended selection operations.

![Hyper + Shift + Alt](hyper-shift-alt.svg)

### Hyper + Shift + Cmd
Extended line operations with selection.

![Hyper + Shift + Cmd](hyper-shift-cmd.svg)

### Hyper + Ctrl + Alt
Additional navigation combinations.

![Hyper + Ctrl + Alt](hyper-ctrl-alt.svg)

### Hyper + Ctrl + Cmd
IDE-specific navigation (navigate to method, move editor groups).

![Hyper + Ctrl + Cmd](hyper-ctrl-cmd.svg)

### Hyper + Alt + Cmd
Tab/pane navigation in IDEs and terminals.

![Hyper + Alt + Cmd](hyper-alt-cmd.svg)

---

*To regenerate all diagrams: `python3 docs/keyboard/generate.py`*
