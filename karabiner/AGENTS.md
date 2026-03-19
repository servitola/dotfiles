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
24-fn-to-control.json        — Fn → Left Control (internal keyboard)
25-music-control.json        — Hyper+Shift+Space → Keypad 0
```

## Core Remappings (Don't Break These)
- **Caps Lock → Hyper**: Maps to all 4 right modifiers (right_command, right_control, right_option, right_shift)
- **Tab as modifier layer**: Hold Tab + key for shortcuts, tap alone sends Tab
- **Fn → Left Control**: On internal keyboard only (for 60% keyboard compatibility)
- **Grave/Tilde → Escape**: Except when Hyper is held

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
- Example: Hyper+V → F19 → Hammerspoon launches Yandex

## References
- Full keyboard system: @../docs/keyboard-setup.md
