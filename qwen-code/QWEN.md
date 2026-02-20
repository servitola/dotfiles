# Global Development Context

## General Instructions

- Follow existing project conventions and coding styles
- Write clean, maintainable, and well-documented code
- Prefer simplicity and clarity over cleverness
- Always consider security implications in code changes
- Test changes thoroughly before considering them complete

## Coding Standards

### Code Style
- Use consistent formatting matching the existing codebase
- Add meaningful comments explaining *why*, not *what*
- Keep functions focused and single-purpose
- Use descriptive variable and function names

### Git & Commits
- Write clear, concise commit messages
- Focus on "why" rather than "what" in commit messages
- Keep commits atomic and logically grouped
- Add `Co-authored-by` trailers for AI-assisted commits

### Documentation
- Update README and relevant docs when adding features
- Document complex logic with inline comments
- Keep API documentation up to date

## Tool Preferences

### Terminal & Shell
- Shell: zsh
- Editor: VSCode / Cursor / Windsurf
- Package Manager: Homebrew (macOS)

### Development
- Use type checking where available (TypeScript, mypy, etc.)
- Run linters and formatters as configured per project
- Follow test-driven development when appropriate

## Common Patterns

### Error Handling
- Use proper error handling (try/catch, Result types, etc.)
- Fail fast and provide meaningful error messages
- Log errors appropriately for debugging

### Testing
- Write tests for new features and bug fixes
- Maintain good test coverage on critical paths
- Use descriptive test names that explain the scenario

## Qwen Code Features

### Approval Mode
- **Default**: `auto-edit` for daily development (auto-approve file edits, require shell command approval)
- **Plan Mode**: For exploring unfamiliar codebases
- **YOLO Mode**: Only in trusted personal projects with full automation

### Subagents
- Enable subagents for specialized tasks (testing, documentation, code review)
- Create single-responsibility agents with clear descriptions
- Use automatic delegation based on task expertise
- Store project-specific agents in `.qwen/agents/`

### Skills
- Discover and use skills from `.qwen/skills/` directory
- Support skill composition for complex workflows
- Create reusable skills for common patterns

### MCP (Model Context Protocol)
- Enable MCP servers for extended tool capabilities
- Configure trusted MCP servers in settings

### Tools & Automation
- Use ripgrep for fast file content search
- Enable tool output truncation for large outputs
- Allow common safe commands without confirmation: `git status`, `git diff`, `npm test`, `make`

## Project-Specific Notes

- Check for `.qwen/QWEN.md` in project root for project-specific context
- Respect project-specific configurations and overrides
- Follow framework-specific conventions (React, Django, etc.)
- Load context from included directories when configured

---

## Quick Reference

### Available Subagents

| Agent | When to Use |
|-------|-------------|
| `testing-expert` | Writing unit/integration tests, TDD |
| `code-reviewer` | Before merging, security reviews, refactoring |
| `documentation-writer` | API docs, READMEs, user guides |
| `python-expert` | Python development, FastAPI, Django, data science |
| `typescript-expert` | TypeScript, React, Next.js, Node.js |
| `debugger` | Root cause analysis, error investigation |

### Available Skills

| Skill | When to Use |
|-------|-------------|
| `auto-pr` | Create/update GitHub pull requests |
| `dashboard-builder` | Build React/Next.js dashboards with charts |
| `git-assistant` | Git workflows, branch management, commits |
| `security-scanner` | Pre-commit/deployment security checks |

### MCP Servers

| Server | Purpose |
|--------|---------|
| `github` | Repository, PR, issue management |
| `filesystem` | Secure file operations |
| `sequential-thinking` | Structured problem-solving |
| `memory-bank` | Persistent session memory |
| `fetch` | Web content retrieval |
| `git` | Git operations |

### Commands

```bash
# Start Qwen Code
qwen

# With prompt
qwen -p "explain this codebase"

# Approval modes
qwen --approval-mode auto-edit  # Auto-approve edits
qwen --approval-mode yolo       # Auto-approve everything
qwen --approval-mode plan       # Read-only analysis

# Resume conversation
qwen --continue
qwen --resume

# Headless mode
qwen -p "summarize changes" --output-format json
```

### Slash Commands

```
/agents          - Manage subagents
/skills          - List available skills
/memory refresh  - Reload context files
/memory show     - Show loaded context
/approval-mode   - Change approval mode
```

### File Structure

```
qwen-code/
├── QWEN.md           # This file - global context
├── settings.json     # Configuration
├── agents/           # Subagent definitions
│   ├── testing-expert.md
│   ├── code-reviewer.md
│   └── ...
├── skills/           # Skill definitions
│   ├── auto-pr.md
│   ├── dashboard-builder.md
│   └── ...
└── mcp/              # MCP server configs
    └── servers.json
```

### Environment Variables

```bash
# Required for MCP servers
export GITHUB_TOKEN="ghp_..."      # GitHub MCP
export BRAVE_API_KEY="..."         # Brave Search MCP
export DATABASE_URL="postgresql://..."  # PostgreSQL MCP

# Optional
export QWEN_CODE_SYSTEM_SETTINGS_PATH="~/.qwen/settings.json"
export TAVILY_API_KEY="tvly-..."   # Web search
```
