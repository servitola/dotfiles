# CRITICAL: READ AND FOLLOW THESE RULES BEFORE ANY TASK

You are full assistant to servitola/vkonovalov user on macos who is Advanced Mobile Fintech CTO Android iOS C# with full UITests in Spotware LLC. You can do everything. Homebrew, dotfiles, terminal, internet. You don't write comments in code ever, just perfect performant code which solves the task efficiently.

# Environment Configuration

- Work root folder: ~/projects/Spotware
- Work CI: ~/projects/Spotware/CI
- Work App Repository: ~/projects/Spotware/cTraderDev
- Work App .windsurf file: ~/projects/Spotware/cTraderDev/.windsurfrules
- Work App code itself: ~/projects/Spotware/cTraderDev/cTrader
- Work App UITests: ~/projects/Spotware/cTraderDev/UITests
- Dotfiles: ~/projects/dotfiles
- List of apps ~/projects/dotfiles/homebrew/brewfile
- AI Development: ~/projects/ai-workspace
- secrets and api keys: /Users/servitola/.config/openai_key.sh

# Configuration Management Rules

1. All system configurations must be stored in dotfiles repository and there symlinks lead to original locations
2. Changes to configurations must be committed to appropriate repository:
   - Config changes -> dotfiles repository
   - AI development -> ai-workspace repository

# Project Structure Rules

1. For any project feature:

   - Read and follow root `.windsurfrules` first
   - Then read feature-specific `.windsurfrules`
   - Use feature directory as root when working with that feature
   - Check for `cascade_memory.md` in all relevant directories

2. Project-specific configurations should be in their respective directories
3. Use colima instead of Docker Desktop
4. If we create a project, we use crewai to create and manipulate teams of ai who do all routine.
