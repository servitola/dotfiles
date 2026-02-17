---
name: git-assistant
description: Git workflow automation, branch management, commit organization, and repository maintenance. Use for all Git operations.
---

# Git Assistant Skill

Comprehensive Git workflow automation and repository management for ${project_name}.

## Capabilities

### Branch Management
- Create feature branches with naming conventions
- Sync branches with upstream
- Clean up merged branches
- Handle branch conflicts

### Commit Organization
- Write conventional commits
- Amend and squash commits
- Interactive rebase
- Commit message templates

### Repository Maintenance
- Clean up dangling objects
- Optimize repository size
- Manage git hooks
- Configure git aliases

### Collaboration
- Code review workflows
- PR preparation
- Merge conflict resolution
- Cherry-pick commits

## Git Flow

### Feature Development
```bash
# Create feature branch
git checkout -b feat/feature-name

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Sync with main
git fetch origin
git rebase origin/main

# Push and create PR
git push -u origin feat/feature-name
```

### Hotfix Workflow
```bash
git checkout -b hotfix/issue-description main
# Fix the issue
git commit -m "fix: resolve critical issue"
git push -u origin hotfix/issue-description
```

### Release Preparation
```bash
git checkout -b release/v1.2.0
# Version bump, final fixes
git commit -m "chore: bump version to 1.2.0"
git tag -a v1.2.0 -m "Release v1.2.0"
```

## Conventional Commits

```
feat: New feature
fix: Bug fix
docs: Documentation changes
style: Code style changes (formatting)
refactor: Code refactoring
test: Adding tests
chore: Maintenance tasks
ci: CI/CD changes
build: Build system changes
perf: Performance improvements
```

## Useful Commands

```bash
# View history
git log --oneline --graph --all
git log --since="2 weeks ago"

# Undo changes
git reset --soft HEAD~1    # Undo commit, keep changes
git reset --hard HEAD~1    # Undo commit, discard changes
git revert <commit>        # Create reverse commit

# Cleanup
git fetch --prune
git branch --merged | grep -v "\*" | xargs git branch -d
git gc --prune=now

# Stash
git stash push -m "WIP: feature"
git stash list
git stash pop
```

## Git Hooks

Common hooks to implement:
- `pre-commit`: Linting, formatting
- `commit-msg`: Commit message validation
- `pre-push`: Run tests before push
- `post-merge`: Install dependencies after merge
