# Dotfiles Maintenance PRP

## Context
You are helping maintain a comprehensive macOS dotfiles repository with symlinks, automation, and multiple tool integrations.

## System Architecture
- **Symlink Strategy**: Repository files linked to system locations
- **Package Management**: Homebrew with Brewfile for apps
- **Automation**: Makefile for installation, `up` command for updates
- **Key Tools**: Hammerspoon, Karabiner-Elements, Zsh, n8n

## Critical Maintenance Areas

### 1. Symlink Integrity
- Verify all symlinks point to correct repository files
- Check for broken symlinks after system updates
- Ensure new configuration files are properly linked

### 2. Homebrew Management
- Keep Brewfile synchronized with installed applications
- Remove deprecated packages and casks
- Update formulae and maintain compatibility

### 3. Configuration Validation
- Karabiner JSON syntax validation
- Hammerspoon Lua syntax checking
- Zsh configuration testing
- Git configuration verification

### 4. System Integration
- LaunchAgents for auto-starting services (n8n)
- Default application associations
- Keyboard layout and language switching

## Pre-commit Validation Strategy
```bash
# Syntax validation commands
hammerspoon -c "hs.loadSpoon('HotKeys')"  # Test Hammerspoon config
jq . karabiner/karabiner.json >/dev/null  # Validate JSON
zsh -n zsh/zshrc  # Check Zsh syntax
```

## Risk Areas
- **System Updates**: May break symlinks or require reconfiguration
- **Application Updates**: May change configuration file formats
- **New Machine Setup**: Installation process needs thorough testing

## Implementation Approach
1. Always backup current configurations before changes
2. Test changes on non-critical systems first
3. Validate all syntax before committing
4. Update documentation when adding new features
5. Run full `make` installation test periodically

## Troubleshooting Checklist
- [ ] All symlinks are valid and pointing correctly
- [ ] Homebrew packages install without conflicts
- [ ] Karabiner-Elements loads configuration successfully
- [ ] Hammerspoon reloads without errors
- [ ] Zsh loads with all plugins functioning
- [ ] Git operations work with proper identity