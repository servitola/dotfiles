# Karabiner Configuration Rules

## Build System
`karabiner.json` is **generated** — do NOT edit it directly!

- **Edit**: Individual rule files in `rules/*.json`
- **Build**: Run `./build.sh` to regenerate `karabiner.json`
- **Template**: `karabiner-template.json` has global settings, profiles, and empty rules array

The build script uses `jq` to merge the template with all rule files in sorted order.

## Rule Files (rules/)
```
01-tab-modifier.json         — Tab as modifier layer (hold Tab + key)
02-alt-shift-delete.json     — Alt+Shift+Q = Shift+Delete Forward
03-right-option-symbols.json — Right Option + C/E/D/A/R = ©/€/°/≈/®
04-caps-lock-hyper.json      — Caps Lock → all 4 right modifiers (Hyper)
05-grave-to-escape.json      — Grave/Tilde → Escape (pass-through with Hyper)
06-hyper-layer-fkeys.json    — Hyper+letter → F13-F19 (caught by Hammerspoon)
07-hyper-only.json           — Hyper + key (no additional modifiers)
08-hyper-shift.json          — Hyper + Shift + key
09-hyper-command.json        — Hyper + Command + key
10-hyper-option.json         — Hyper + Option + key
11-hyper-control.json        — Hyper + Control + key
12-hyper-shift-command.json  — Hyper + Shift + Command + key
13-hyper-shift-option.json   — Hyper + Shift + Option + key
14-hyper-shift-control.json  — Hyper + Shift + Control + key
15-hyper-command-option.json — Hyper + Command + Option + key
16-hyper-command-control.json— Hyper + Command + Control + key
17-hyper-option-control.json — Hyper + Option + Control + key
18-hyper-misc.json           — Non-hyper modifiers (Alt, Shift, etc.)
19-brightness-control.json   — Cmd+Shift+Arrow = brightness
20-alt-shortcuts-2.json      — Alt+2 = Ctrl+Shift+Z
21-alt-shortcuts-3.json      — Alt+3 = Cmd+N
22-custom-right-cmd.json     — Right Command remappings
23-left-hand-delete.json     — Ctrl+Shift+A/D for delete/backspace
25-music-control.json        — Hyper+Shift+Space → Keypad 0
26-right-option-space-punto.json — Right Option + Space → Ctrl+F14 (Punto reconversion)
27-left-all-hide.json        — All left modifiers + arrows → focus modes
28-ctrl-opt-cmd-h-hide-current.json — Ctrl+Alt+Cmd+H → F13 (hide current window)
29-mouse-ugreen-hold-to-browser.json — UGREEN mouse forward button held → browser
30-fn-layer-mirror.json      — fn + left half of a row → right half of that row
31-alt-shortcuts-4.json      — Alt+4 = Cmd+H (hide front app; focus falls to the one behind)
32-swap-sides.json           — Ctrl+Alt + both arrows at once → Ctrl+Alt+F14 (swap two top windows)
```

## Core Remappings (Don't Break These)
- **Caps Lock → Hyper**: Maps to all 4 right modifiers (right_command, right_control, right_option, right_shift)
- **Tab as modifier layer**: Hold Tab + key for shortcuts, tap alone sends Tab
- **`fn` is left alone**: it used to be remapped to Left Control so the bottom-left key matched
  the 60% keyboard, and briefly it was swapped with Control. Both are gone — `fn` is the layer
  key now (see below) and has to stay a real `fn` on its own key. Cost of that: on the built-in
  keyboard `⌃` sits one key further right than on the 60% board.
- **Grave/Tilde → Escape**: Except when Hyper is held

## fn Layer (Mirror the Left Half onto the Right)
`30-fn-layer-mirror.json`: holding `fn`, the i-th key of a row's left half sends the i-th key
of that row's right half, so the right hand's territory is typeable from the home position.

```json
"from": {"key_code": "1", "modifiers": {"mandatory": ["fn"], "optional": ["any"]}},
"to":   [{"key_code": "7"}]
```

`mandatory` consumes the `fn` so it never reaches the app; `optional: ["any"]` is what keeps
`fn`+`⌘`+`1` working as `⌘7`.

Not a uniform shift — the rows are different lengths, and they do not balance row by row:
number row 12 keys (6→6), bottom row 10 (5→5), but the top row has 13 (`qwerty` → `uiop[]\`,
seven targets for six sources) and the home row 11 (`asdfgh` → `jkl;'`, six sources for five
targets). The home row's spare `h` covers the top row's orphan, so `fn`+`h` sends `backslash`.
That is what makes the layer complete: every letter and symbol of the right-hand block is
reachable from the left hand.

All four rows are live. This deliberately eats the macOS 🌐-combos that land on mapped letters
(🌐+E emoji, 🌐+F fullscreen, 🌐+C Control Center, 🌐+Q Quick Note, 🌐+A, 🌐+D) — the owner
tried them and uses none. Do not "restore" them without asking. `fn`+`h`, arrows, delete and
the F-row stay untouched, as do 🌐+N and 🌐+M (right half, never mapped).

## Tab Modifier Pattern (Variable-Based Layer)
```json
"from": {"key_code": "tab"},
"to": [{"set_variable": {"name": "tab_modifier", "value": 1}}],
"to_after_key_up": [{"set_variable": {"name": "tab_modifier", "value": 0}}],
"to_if_alone": [{"key_code": "tab"}]
```
Then use conditions: `{"name": "tab_modifier", "type": "variable_if", "value": 1}`

## Hyper Layer Pattern (Remap to F-keys)
- Hyper + letter keys remap to F13-F19
- Hammerspoon catches F-keys and launches apps/functions
- Example: Hyper+V → F19 → Hammerspoon launches Vivaldi

## References
- Full keyboard system: @../docs/keyboard-setup.md
