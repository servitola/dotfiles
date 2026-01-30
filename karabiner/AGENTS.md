# Karabiner Configuration Rules

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

## Your Common Modifications
- Tab + number keys → Cmd + different keys (zoom, screenshot controls)
- Tab + letters → Cmd shortcuts (select all, browser navigation)
- Tab + C → Cmd+/ (comment toggle)
- Tab + S → Types "servitola" (text expansion)
- Alt + numbers → Various shortcuts (Cmd+N, Ctrl+Shift+Z)

## References
- Full keyboard system: @../docs/keyboard-setup.md
