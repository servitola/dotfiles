# Hammerspoon Configuration PRP

## Context
You are helping with Hammerspoon Lua configuration for macOS automation. The user has a complex setup with:
- Window management (ctrl+alt+arrow keys)
- URL dispatching (Hammerspoon as default browser)
- Language switching automation
- Custom Spoons and hotkeys

## Current Structure
- `hammerspoon/init.lua` - Main configuration entry point
- `hammerspoon/Spoons/` - Custom Spoons directory
- `hammerspoon/config_UrlDispatcher.sh` - URL routing configuration

## Requirements
When modifying Hammerspoon configurations:

1. **Safety First**
   - Always validate Lua syntax before suggesting changes
   - Preserve existing hotkey bindings unless explicitly changing them
   - Test configurations in small increments

2. **Coding Standards**
   - Follow existing Lua style in the project
   - Use descriptive variable names
   - Add comments for complex logic
   - Maintain consistency with existing Spoons

3. **Integration Points**
   - Respect existing hotkey mappings in `Spoons/HotKeys.spoon/`
   - Consider impact on URL dispatcher rules
   - Maintain compatibility with Karabiner-Elements

## Validation Checklist
- [ ] Lua syntax is valid
- [ ] No conflicting hotkey bindings
- [ ] Configuration follows project patterns
- [ ] Changes are backward compatible
- [ ] Documentation is updated if needed

## Common Gotchas
- Hammerspoon requires `hs.reload()` after config changes
- Modal bindings need proper enter/exit handling
- URL regex patterns must be properly escaped
- Window management should handle multi-monitor setups

## Implementation Strategy
1. First understand the current configuration
2. Make incremental changes
3. Test each change before proceeding
4. Update documentation as needed