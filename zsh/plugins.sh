# =============================================================================
# Oh My Zsh Plugins Configuration
# =============================================================================
# Plugins add completions, aliases, and functionality
# Keep this minimal for fast shell startup
# =============================================================================

plugins=(
  # VCS Integration
  git              # Git aliases and completions

  # Navigation
  z                # Jump to frecent directories (autojump alternative)
  
  # Development Tools (with Homebrew completions)
  brew             # Brew aliases and completions enhancement
  docker           # Docker completions and aliases
  docker-compose   # Docker Compose completions
  npm              # npm completions and aliases
  yarn             # Yarn completions
  node             # Node.js utilities
  
  # macOS Integration
  macos            # macOS-specific aliases (e.g., 'ofd' for Finder)
  
  # Productivity
  aliases          # List and search aliases with 'acs'
  colored-man-pages # Colored man pages for better readability
  copypath         # Copy current path to clipboard
  copyfile         # Copy file contents to clipboard
  
  # Optional: Uncomment if needed
  # python         # Python virtualenv helpers
  # pip            # pip completions
  # kubectl        # Kubernetes completions
  # terraform      # Terraform completions
)

# =============================================================================
# Plugin Notes
# =============================================================================
# 
# brew plugin benefits:
#   - Aliases: 'bubo' (brew update && brew outdated), 'bubc' (brew upgrade && brew cleanup)
#   - Already have full completions from Homebrew itself
#
# docker/docker-compose plugins:
#   - Add helpful aliases and completion enhancements
#   - Work with Homebrew-installed Docker
#
# npm/yarn/node plugins:
#   - Completions for common tasks
#   - Aliases like 'npmg' (npm list -g --depth=0)
#
# macos plugin:
#   - 'ofd' - Open current directory in Finder
#   - 'pfd' - Print Finder directory
#   - 'cdf' - cd to Finder directory
#   - Many more macOS-specific helpers
#
# Performance note:
#   - Each plugin adds ~5-20ms to startup time
#   - Current config: ~100-150ms total plugin load time
#   - Still maintains instant prompt with p10k
# =============================================================================
