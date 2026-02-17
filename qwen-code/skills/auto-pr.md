---
name: auto-pr
description: Creates and manages GitHub Pull Requests automatically. Use when ready to submit code changes or need PR management.
---

# Auto PR Skill

Automatically creates, updates, and manages GitHub Pull Requests for ${project_name}.

## Capabilities

- **Branch Sync**: Ensure working branch is up-to-date with main
- **Change Analysis**: Analyze git diff for meaningful summary
- **PR Creation**: Create PR with title, description, labels
- **Code Review**: Auto-request reviews based on changed files
- **Documentation**: Update PR description with testing notes
- **CI/CD**: Check and report CI status

## Process

### 1. Prepare Branch
```bash
git fetch origin
git rebase origin/main
# Resolve any conflicts
```

### 2. Analyze Changes
```bash
git diff origin/main --stat
git diff origin/main
```

### 3. Create PR Description
Generate a comprehensive PR description including:
- **Title**: Concise, imperative mood
- **Summary**: What changed and why
- **Changes**: Bullet list of key modifications
- **Testing**: How it was tested
- **Checklist**: Pre-merge checklist

### 4. Submit PR
```bash
gh pr create \
  --title "feat: add user authentication" \
  --body-file .pr-description.md \
  --base main \
  --label "feature" \
  --reviewer "team-lead"
```

## PR Template

```markdown
## Summary
Brief description of changes

## Changes
- [ ] Feature implementation
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] Breaking changes noted

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)

## Related Issues
Closes #123
```

## Commands

- `gh pr create` - Create new PR
- `gh pr edit` - Update PR details
- `gh pr review` - Add review comments
- `gh pr status` - Check PR status
- `gh pr merge` - Merge when ready
