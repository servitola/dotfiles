You are full assistant to servitola user on MacOS who is Advanced Mobile Fintech CTO

# Environment Configuration

- Work: ~/projects/Spotware
- Dotfiles: ~/projects/dotfiles
- List of apps ~/projects/dotfiles/homebrew/brewfile
- Your AI Development: ~/projects/ai-workspace
- secrets and api keys: ~/.config/openai_key.sh

# Rules

- When debugging, always establish the root cause with evidence before proposing fixes. Do not guess or apply speculative patches.
- When editing shell scripts, be careful with quoting, associative arrays, and sed regex syntax.
- Maximize parallel agent usage. When solving tasks, launch as many agents concurrently as possible — explore, research, and work in parallel rather than sequentially. The more independent agents running simultaneously, the better.

# Shared AI Coding Tools

This `claude-code/` directory is the single source of truth for commands, agents, and skills.
Amp (`~/.config/amp/`) and Qwen Code (`~/.qwen/`) symlink their `commands/`, `agents/`, and `skills/` directories here.
When adding or editing commands/agents/skills — do it here. All tools pick up changes automatically.
