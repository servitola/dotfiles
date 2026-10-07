# macOS window keys

macOS's own `🌐⌃` window keys, and how to hand them to PowerWindows.

## What macOS has

Since macOS Sequoia, in every app's Window menu ([Apple](https://support.apple.com/guide/mac-help/tile-app-windows-mchl9674d0b0/mac)). `🌐` is the Globe (`Fn`) key.

| Keys | macOS |
|---|---|
| `🌐⌃F` | Fill |
| `🌐⌃C` | Center |
| `🌐⌃←` `🌐⌃→` | left / right half |
| `🌐⌃↑` `🌐⌃↓` | top / bottom half |
| `🌐⌃R` | return to previous size |
| `🌐⌃⇧` + arrows | two windows |
| `🌐⌥⌃⇧` + arrows | one half + quarters |

## Default

`macosKeys = false`: macOS keeps them all.

## Take them

`macosKeys = { key = action }`. The focused window goes to PowerWindows' places, with its gaps.

```lua
spoon.PowerWindows:configure{
  macosKeys = { left = "left", right = "right", up = "top60", down = "bottom40", f = "fullscreen", c = "center" },
}:start()
```

| Keys | Action | Result |
|---|---|---|
| `🌐⌃←` | `left` | to `main`; with `cycle`, again: left half |
| `🌐⌃→` | `right` | to `side`; with `cycle`, again: right half |
| `🌐⌃↑` | `top60` | upper part, full width |
| `🌐⌃↓` | `bottom40` | lower part, full width |
| `🌐⌃F` | `fullscreen` | whole screen with gaps; with `cycle`, again: native fullscreen |
| `🌐⌃C` | `center` | centered, size kept |

Just some:

```lua
spoon.PowerWindows:configure{ macosKeys = { f = "fullscreen", c = "center" } }:start()
```

- Any of the twelve actions in [keys.md](keys.md), on any key: `macosKeys = { r = "arrangeAll" }`. An unknown key or action raises an error at `configure`.
- Only `🌐⌃` + key is taken; with `⇧`, `⌥` or `⌘` added it stays macOS's.
- Arrows and other named keys need the physical 🌐 held: `⌃←` alone stays Mission Control's; a synthetic 🌐⌃← is not caught.
- A second `configure` merges key by key; `false` for a key gives it back. `macosKeys = false` gives all back.

## Turn macOS tiling off instead

Dragging: System Settings › Desktop & Dock › Windows ([Apple](https://support.apple.com/guide/mac-help/mchl118087b0/mac)).

- Drag windows to left or right edge of screen to tile
- Drag windows to menu bar to fill screen
- Hold ⌥ key while dragging windows to tile
- Tiled windows have margins

The keys have no switch there. To free one: System Settings › Keyboard › Keyboard Shortcuts › App Shortcuts › All Applications, add the menu title (`Fill`) with another shortcut.
