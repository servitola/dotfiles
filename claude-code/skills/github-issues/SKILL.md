---
name: github-issues
description: |
  Create, search, triage, label, assign, comment on, and close GitHub issues via the gh CLI or the REST API.

  Use when: "создай issue", "заведи задачу на гитхабе", "разбери issues", "повесь лейбл на issue", "create a github issue", "triage issues", "label this issue", "close issue"
---

# GitHub Issues Management

Create, search, triage, and manage GitHub issues. Sections show the `gh` way; for machines without `gh`, equivalent `curl` commands live in `references/rest-fallbacks.md`. Load only the reference sections the task needs.

## What do you need?

```
Work with issues?
├─ View or search           → Section 1
├─ Create one               → Section 2 (body skeletons in assets/)
├─ Label / assign / comment / close / link to PR → Section 3
├─ Triage a backlog         → Section 4
└─ Batch-edit many at once  → Section 5
```

No `gh` on the machine? Run each step with the matching section of [rest-fallbacks.md](references/rest-fallbacks.md) — it mirrors Sections 1–5 with `curl` equivalents plus the token and owner/repo setup.

## Prerequisites

- The GitHub CLI (`gh`) installed and authenticated, or a `GITHUB_TOKEN` for the REST fallback.
- Inside a git repo with a GitHub remote, or specify the repo explicitly (`--repo owner/name`).

Install and authenticate `gh`:

```bash
brew install gh          # macOS; on Linux see https://github.com/cli/cli#installation
gh auth login            # interactive: pick GitHub.com, HTTPS, authenticate in browser
gh auth status           # verify
```

Without `gh`, export a token and extract `$OWNER`/`$REPO` following "Setup: Token and Owner/Repo" in [rest-fallbacks.md](references/rest-fallbacks.md).

## 1. Viewing and Searching Issues

```bash
gh issue list
gh issue list --state open --label "bug"
gh issue list --assignee @me
gh issue list --search "authentication error" --state all
gh issue view 42
```

Without `gh`, use "View, List, and Search Issues" in [rest-fallbacks.md](references/rest-fallbacks.md).

## 2. Creating Issues

Compose the body from the matching skeleton: bug → [assets/bug-report.md](assets/bug-report.md) (repro steps, expected/actual, environment, error output), feature → [assets/feature-request.md](assets/feature-request.md) (motivation, proposed solution, alternatives, scope). Write the filled body to a temp file and pass `--body-file` to keep real newlines:

```bash
gh issue create \
  --title "Login redirect ignores ?next= parameter" \
  --body-file /tmp/issue-body.md \
  --label "bug,backend" \
  --assignee "username"
```

Without `gh`, use "Create an Issue" in [rest-fallbacks.md](references/rest-fallbacks.md).

## 3. Managing Issues

### Labels

```bash
gh issue edit 42 --add-label "priority:high,bug"
gh issue edit 42 --remove-label "needs-triage"
gh label list                # available labels in the repo
```

### Assignment

```bash
gh issue edit 42 --add-assignee username
gh issue edit 42 --add-assignee @me
```

### Commenting

```bash
gh issue comment 42 --body "Investigated — root cause is in auth middleware. Working on a fix."
```

### Closing and Reopening

```bash
gh issue close 42
gh issue close 42 --reason "not planned"
gh issue reopen 42
```

Without `gh`, each subsection has a matching block in [rest-fallbacks.md](references/rest-fallbacks.md): Labels, Assignment, Commenting, Closing and Reopening.

### Linking Issues to PRs

Issues close automatically when a PR merges with the right keyword in the body: `Closes #42`, `Fixes #42`, or `Resolves #42`.

Create a working branch from an issue:

```bash
gh issue develop 42 --checkout

# git-only equivalent
git checkout main && git pull origin main
git checkout -b fix/issue-42-login-redirect
```

## 4. Issue Triage Workflow

When asked to triage issues:

1. List untriaged issues: `gh issue list --label "needs-triage" --state open` (without `gh`: "Triage" in [rest-fallbacks.md](references/rest-fallbacks.md))
2. Read and categorize each one: `gh issue view N` — understand the bug/feature
3. Apply labels and priority (Section 3)
4. Assign if the owner is clear
5. Comment with triage notes if needed

## 5. Bulk Operations

For batch operations, combine list output with shell scripting:

```bash
# Close all issues with a specific label
gh issue list --label "wontfix" --json number --jq '.[].number' | \
  xargs -I {} gh issue close {} --reason "not planned"
```

Without `gh`, use "Bulk Operations" in [rest-fallbacks.md](references/rest-fallbacks.md).

## Quick Reference Table

| Action | gh | curl endpoint |
|--------|-----|--------------|
| List issues | `gh issue list` | `GET /repos/{o}/{r}/issues` |
| View issue | `gh issue view N` | `GET /repos/{o}/{r}/issues/N` |
| Create issue | `gh issue create ...` | `POST /repos/{o}/{r}/issues` |
| Add labels | `gh issue edit N --add-label ...` | `POST /repos/{o}/{r}/issues/N/labels` |
| Assign | `gh issue edit N --add-assignee ...` | `POST /repos/{o}/{r}/issues/N/assignees` |
| Comment | `gh issue comment N --body ...` | `POST /repos/{o}/{r}/issues/N/comments` |
| Close | `gh issue close N` | `PATCH /repos/{o}/{r}/issues/N` |
| Search | `gh issue list --search "..."` | `GET /search/issues?q=...` |
