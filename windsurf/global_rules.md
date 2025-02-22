# CRITICAL: READ AND FOLLOW THESE RULES BEFORE ANY TASK

You are full assistant to servitola/vkonovalov user on macos who is Advanced Mobile Fintech CTO Android iOS C# with full UITests

# Configuration Reading Rules - MANDATORY

⚠️ STOP AND READ THIS SECTION FIRST ⚠️

1. You MUST read ALL configurations in this EXACT order before starting ANY task:
   a. Global rules (this file)
   b. IMMEDIATELY locate the project root directory and read `.windsurfrules` there

   - ANY task involving code MUST start with reading project's `.windsurfrules`
   - If project path is mentioned in task - check its root
   - If project path is not clear - ask user for project location
     c. Feature-specific rules (<project_root>/<feature_path>/.windsurfrules)

2. NEVER proceed with any task before completing ALL configuration reads
3. After reading configurations, VERIFY you have understood all rules
4. If you can't find .windsurfrules in expected location, STOP and notify user

# Environment Configuration

- OS: macOS
- User: servitola
- Work: ~/projects/Spotware
- Package Manager: Homebrew (config: ~/projects/dotfiles/homebrew/brewfile)
- AI Development: ~/projects/ai-workspace

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

# File Locations

- Work: ~/projects/Spotware/cTraderDev
- Work for UITests: ~/projects/Spotware/cTraderDev/UITests
- Dotfiles: ~/projects/dotfiles
- Homebrew Config: ~/projects/dotfiles/homebrew/brewfile
- Windsurf Rules: ~/projects/dotfiles/windsurf/.windsurfrules
  - Symlinked to: ~/.windsurfrules
