# Karabiner-Elements Configuration PRP

## Context
You are helping configure Karabiner-Elements for advanced keyboard customization on macOS. This includes complex key mappings, modifiers, and application-specific bindings.

## Configuration Structure
- `karabiner/karabiner.json` - Main configuration file
- Complex rules for caps lock as hyper key
- Application-specific key mappings
- Modifier key combinations

## Key Configuration Principles

### 1. Hyper Key Setup
- Caps Lock → Hyper (cmd+ctrl+opt+shift)
- Used extensively with Hammerspoon hotkeys
- Must not conflict with system shortcuts

### 2. JSON Structure Validation
```json
{
  "global": { "check_for_updates_on_startup": true },
  "profiles": [{
    "name": "Default profile",
    "complex_modifications": {
      "rules": [/* rule objects */]
    }
  }]
}
```

### 3. Rule Design Patterns
- Use descriptive rule names
- Group related modifications
- Consider application context
- Test for modifier key conflicts

## Safety Considerations
- **Always validate JSON syntax** before applying changes
- **Test new rules incrementally** to avoid system lockup
- **Backup working configurations** before major changes
- **Provide escape mechanisms** for complex modal states

## Common Use Cases
1. **Caps Lock as Hyper Key**
2. **Application-specific shortcuts**
3. **Modifier key remapping**
4. **International keyboard layouts**
5. **Gaming/development mode toggles**

## Validation Process
```bash
# Validate JSON syntax
jq . karabiner/karabiner.json

# Check file permissions
ls -la ~/.config/karabiner/karabiner.json

# Verify symlink integrity
readlink ~/.config/karabiner/karabiner.json
```

## Integration Points
- Works alongside Hammerspoon for complete automation
- Must consider existing hotkey bindings
- Respects language switching automation
- Coordinates with system accessibility settings

## Troubleshooting Guide
- **Rule not working**: Check JSON syntax and rule structure
- **System lag**: Review complex rule performance impact
- **Conflicts**: Audit all modifier combinations for overlaps
- **App-specific issues**: Verify bundle identifiers are correct