# Claude Code Configuration

This directory contains comprehensive configuration files for Claude Code, optimized for advanced development workflows.

## Overview

Claude Code doesn't use `CLAUDE_ENV_CONFIG` as an environment variable. Instead, it uses a hierarchical configuration system with multiple files and environment variables.

## Files Included

### `settings.json`
Global Claude Code configuration that includes:
- **Environment variables**: Telemetry disabled, extended timeouts, debug settings
- **Permissions**: Comprehensive allow/deny rules for security
- **Model settings**: Default to Claude Sonnet 4
- **Hooks**: Pre/post command execution hooks
- **Cleanup settings**: 90-day retention period

### `project-settings.json`
Template for project-specific configurations:
- Development environment variables
- Project-specific permissions
- Customizable per project needs

### `CLAUDE.md`
Comprehensive project memory template covering:
- Development environment guidelines
- Code style and standards
- Git workflow practices
- Testing guidelines
- Security best practices
- Documentation standards

### `setup.sh`
Automated setup script that:
- Backs up existing configurations
- Installs global settings
- Sets environment variables in shell profile
- Provides usage instructions

## Installation

1. **Automatic Setup (Recommended):**
   ```bash
   cd ~/projects/dotfiles/claude-code-config
   ./setup.sh
   ```

2. **Manual Setup:**
   ```bash
   # Copy global settings
   cp settings.json ~/.claude/settings.json
   
   # Add environment variables to your shell profile
   echo 'export CLAUDE_CODE_ENABLE_TELEMETRY=0' >> ~/.zshrc
   echo 'export DISABLE_ERROR_REPORTING=1' >> ~/.zshrc
   echo 'export DISABLE_TELEMETRY=1' >> ~/.zshrc
   source ~/.zshrc
   ```

## Project Setup

For each project where you want custom Claude Code behavior:

1. **Create project configuration:**
   ```bash
   mkdir -p .claude
   cp ~/projects/dotfiles/claude-code-config/project-settings.json .claude/settings.json
   ```

2. **Add project memory:**
   ```bash
   cp ~/projects/dotfiles/claude-code-config/CLAUDE.md ./CLAUDE.md
   ```

3. **Customize as needed** for your specific project requirements.

## Configuration Hierarchy

Claude Code uses this priority order:
1. **Enterprise settings** (if applicable)
2. **Project settings** (`.claude/settings.json`)
3. **Local settings** (`.claude/settings.local.json`)
4. **Global settings** (`~/.claude/settings.json`)

## Environment Variables

Key environment variables configured:

| Variable | Value | Purpose |
|----------|-------|---------|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `0` | Disable telemetry |
| `DISABLE_ERROR_REPORTING` | `1` | Disable error reporting |
| `DISABLE_TELEMETRY` | `1` | Additional telemetry disable |
| `BASH_DEFAULT_TIMEOUT_MS` | `480000` | 8-minute timeout for long commands |
| `CLAUDE_CODE_MAX_OUTPUT_TOKENS` | `16384` | Increased output token limit |
| `ANTHROPIC_LOG` | `info` | Logging level |

## Security Features

- **File exclusions**: Automatically excludes sensitive files (`.env`, secrets, etc.)
- **Permission controls**: Fine-grained read/write permissions
- **Safe defaults**: Conservative permissions that can be expanded as needed

## Usage Tips

1. **Check current configuration:**
   ```bash
   claude config get --global
   ```

2. **Switch models during session:**
   ```bash
   /model
   ```

3. **Check status:**
   ```bash
   /status
   ```

4. **Manage permissions interactively:**
   ```bash
   /permissions
   ```

## Customization

Modify the configurations based on your needs:

- **For more permissive settings**: Add tools to the `allow` list
- **For stricter security**: Add patterns to the `deny` list  
- **For different models**: Change the default `model` setting
- **For team settings**: Check project configurations into version control

## Troubleshooting

1. **Configuration not loading**: Check file permissions and JSON syntax
2. **Environment variables not set**: Restart terminal or source shell profile
3. **Permissions issues**: Use `/permissions` command to debug
4. **Model access issues**: Verify your Anthropic account and billing

## Advanced Features

- **Hooks**: Custom commands before/after tool execution
- **MCP servers**: Configure additional AI capabilities
- **Multi-directory access**: Use `--add-dir` for cross-project work
- **Custom API helpers**: For enterprise authentication scenarios

## Updates

This configuration is designed to be forward-compatible with Claude Code updates. The setup script preserves existing configurations and can be re-run safely.

For the latest Claude Code features and configuration options, see the [official documentation](https://docs.anthropic.com/en/docs/claude-code).
