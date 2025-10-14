# n8n Auto-Start

Launch agent to start n8n automatically on macOS boot.

## Install

```bash
./install.sh
```

This will:
1. Call the main `n8n-service.sh` management script
2. Copy the plist to `~/Library/LaunchAgents/`
3. Load the service

## Management

Use the main service script for all operations:

```bash
~/projects/dotfiles/scripts/n8n-service.sh status     # Check status
~/projects/dotfiles/scripts/n8n-service.sh restart    # Restart service
~/projects/dotfiles/scripts/n8n-service.sh logs       # View logs
~/projects/dotfiles/scripts/n8n-service.sh fix        # Fix issues
~/projects/dotfiles/scripts/n8n-service.sh uninstall  # Remove service
```

## Files

- `com.servitola.n8n.plist` - Launch agent definition
- `install.sh` - Installation wrapper that calls main service script

## Logs

- stdout: `~/projects/services/n8n/n8n.log`
- stderr: `~/projects/services/n8n/n8n-error.log`
