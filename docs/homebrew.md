# Homebrew

My package management system for macOS, handling both command-line tools and GUI applications.

## Maintenance

### Update Process

Automated via `up` alias

### Health Checks

```bash
brew doctor          # General health check
brew missing         # Check for missing dependencies
```

## Integration with Dotfiles

### Automated Installation

The Makefile handles Homebrew setup

### Configuration Files

- `homebrew/brewfile` - Complete package list
- `homebrew/minimum_brewfile` - Essential packages only
- `homebrew/install.sh` - Installation script
- `homebrew/install_all_homebrew_packages.sh` - Full installation
- `homebrew/install_minimum_homebrew_packages.sh` - Minimal installation

## Related Files

- `homebrew/brewfile` - Main package list
- `homebrew/minimum_brewfile` - Essential packages
- `homebrew/install.sh` - Installation script
- `macos/update_all_and_cleanup_all.sh` - Update automation
