# Development Environment Documentation

Comprehensive documentation for my macOS development environment, covering all tools, configurations, and workflows.

## Overview

This dotfiles repository contains a complete development environment optimized for productivity, automation, and consistency across multiple Macs. The setup includes shell configuration, keyboard shortcuts, editors, and development tools.

## Architecture

### Core Components

- **Shell**: [Zsh](shell-zsh.md) with extensive customization
- **Automation**: [Hammerspoon](hammerspoon.md) for desktop automation
- **Keyboard**: [Karabiner-Elements](karabiner-elements.md) for advanced key remapping
- **Editors**: [VSCode](editors.md), [Cursor](editors.md), [Windsurf](editors.md)
- **Package Management**: [Homebrew](homebrew.md) with 200+ packages
- **Terminal**: [iTerm2](terminal-emulators.md) and [Ghostty](terminal-emulators.md)
- **Version Control**: [Git](git.md) with advanced configuration

### Design Principles

- **Ergonomic**: Left-hand focused shortcuts
- **Consistent**: Same tools and themes across environments
- **Automated**: Extensive scripting for setup and maintenance
- **Performant**: Optimized for speed and efficiency

## Tool Documentation

### Core System

- **[Shell (Zsh)](shell-zsh.md)** - Main shell configuration with plugins and aliases
- **[Homebrew](homebrew.md)** - Package management with 200+ tools
- **[Git](git.md)** - Version control with advanced configuration

### Automation & Keyboard

- **[Hammerspoon](hammerspoon.md)** - Desktop automation and window management
- **[Karabiner-Elements](karabiner-elements.md)** - Keyboard remapping and shortcuts
- **[Keyboard Setup](keyboard-setup.md)** - Complete keyboard customization guide

### Editors & Development

- **[Editors](editors.md)** - VSCode, Cursor, and Windsurf configuration
- **[Terminal Emulators](terminal-emulators.md)** - iTerm2 and Ghostty setup

### Tools & Utilities

- **[CLI Tools](cli-tools.md)** - Essential command-line utilities

### Specialized Documentation

- **[App Integration](app-integration.md)** - Adding new applications to dotfiles
- **[AI Development Best Practices](ai-development-best-practices.md)** - AI-assisted development guidelines
- **[LLM Cost Reduction](llm-cost-reduction.md)** - Optimizing AI tool usage
- **[Mobile Fintech AI Workflows](mobile-fintech-ai-workflows.md)** - Specialized workflows

## Quick Start

### Installation

1. **Clone repository:**
   ```bash
   mkdir ~/projects
   cd ~/projects
   git clone https://github.com/servitola/dotfiles.git
   ```

2. **Run setup:**
   ```bash
   cd ~/projects/dotfiles
   make
   ```

3. **Update system:**
   ```bash
   up
   ```

### Key Features

#### Hyper Key System
- **Caps Lock** remapped to Hyper (⌘⌃⌥⇧)
- **30 keyboard layers** for different contexts
- **Application launcher** with single keystrokes

#### Development Workflow
- **Multi-editor setup** (VSCode primary, Cursor for AI, Windsurf experimental)
- **Comprehensive Git integration** with advanced tools
- **Automated updates** and maintenance

#### System Automation
- **Window management** with keyboard shortcuts
- **URL routing** based on domain patterns
- **Language switching** per application

## Keyboard Shortcuts

### Hyper Layer (Caps Lock)

| Key | Action | Key | Action | Key | Action |
|-----|--------|-----|--------|-----|--------|
| R   | Rider IDE | T   | Telegram | Y   | IINA |
| F   | Finder | G   | Fork | H   | Safari |
| B   | iTerm2 | N   | VSCode | Z   | AI Assistant |
| Space | Play/Pause | ←→↑↓ | Navigation | Home/End | Jump |

### Other Layers

- **English/Russian**: Standard typing with custom shortcuts
- **Command/Control**: Application and text navigation
- **Alt/Shift**: Specialized functions

## Maintenance

### Regular Updates

```bash
up  # Update everything and clean up
```

This command:
- Updates Homebrew packages
- Upgrades macOS App Store apps
- Updates Python and Node packages
- Cleans caches and logs
- Performs system maintenance

### Backup Strategy

- **Git-based**: All configurations version controlled
- **Symlinked**: System files linked to repository
- **Automated**: Regular commits for change tracking

### Health Checks

- **Pre-commit hooks**: Code quality and security
- **Shellcheck**: Shell script validation
- **Dependency checks**: Missing tool detection

## Customization

### Adding New Tools

1. **Add to Homebrew:**
   ```bash
   brew install <tool>
   brew bundle dump --force
   ```

2. **Create configuration:**
   ```bash
   mkdir ~/projects/dotfiles/<tool>
   # Add config files
   ```

3. **Update Makefile:**
   ```makefile
   @echo "setup <tool>"
   @$(LINK) ~/projects/dotfiles/<tool>/config ~/.config/<tool>/config
   ```

### Modifying Shortcuts

1. **Edit Hammerspoon layouts:**
   ```lua
   -- In hammerspoon/Spoons/Hotkeys.spoon/layouts/
   { key="x", app="New App" }
   ```

2. **Update documentation:**
   - Add to keyboard layout diagrams
   - Update shortcut tables

## Security & Privacy

### Privacy Features

- **Minimal telemetry**: Disabled where possible
- **Local processing**: AI tools run locally when available
- **Secure defaults**: macOS privacy settings configured

### Security Measures

- **Pre-commit hooks**: Secret detection with gitleaks
- **Regular updates**: Security patches applied automatically
- **Access controls**: Proper permissions on sensitive files

## Performance

### Optimization Features

- **Lazy loading**: Tools loaded on demand
- **Async operations**: Non-blocking shell operations
- **Resource monitoring**: Built-in performance tracking

### Benchmarks

- **Shell startup**: < 200ms
- **Editor launch**: < 2 seconds
- **System updates**: Automated, background processing

## Troubleshooting

### Common Issues

1. **Shortcuts not working**: Check Hammerspoon/Karabiner permissions
2. **Tools not found**: Run `up` to install missing packages
3. **Configuration issues**: Check symlinks with `ls -la ~/.config/`

### Recovery

1. **Reset to defaults:**
   ```bash
   cd ~/projects/dotfiles && git reset --hard
   make
   ```

2. **Clean reinstall:**
   ```bash
   make clean && make
   ```

## Compatibility

### macOS Versions

Tested on:
- macOS Sonoma (14.x)
- macOS Ventura (13.x)
- macOS Monterey (12.x)

### Hardware

Optimized for:
- Mac Studio M1 Pro
- MacBook Pro 16" M3 Pro
- MacBook Pro 16" Intel i9

## Contributing

### Guidelines

- **Test changes**: Verify on clean system
- **Document updates**: Update relevant documentation
- **Follow conventions**: Match existing patterns

### Development Workflow

1. **Make changes** in feature branch
2. **Test locally** with `make`
3. **Update docs** as needed
4. **Commit and push**

## Related Projects

- **Inspired by**: [sapegin/dotfiles](https://github.com/sapegin/dotfiles/wiki)
- **Tools**: Various open source projects
- **Community**: macOS development community

## License

This project is open source and available under the MIT License. Feel free to adapt it for your own use, but please respect the original attributions and licenses of included tools.

---

For questions or issues, check the individual tool documentation or create an issue in the repository.
