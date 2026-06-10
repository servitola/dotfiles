---
name: github-pr-workflow
description: |
  Drive the full GitHub pull-request lifecycle: branch, commit, push, open a PR, monitor and auto-fix CI, address review comments, then merge.

  Use when: "открой PR", "создай пулреквест", "проверь CI на пулреквесте", "разбери комментарии ревью", "ответь на комментарии в PR", "смержи PR", "open a pull request", "create a PR", "fix failing CI", "address review comments", "merge this PR"
---

# GitHub Pull Request Workflow

Complete guide for managing the PR lifecycle. Sections show the `gh` way; for machines without `gh`, equivalent `git` + `curl` commands live in `references/rest-fallbacks.md`.

## Prerequisites

- The GitHub CLI (`gh`) installed and authenticated, or a `GITHUB_TOKEN` for the REST fallback.
- Inside a git repository with a GitHub remote.

Install and authenticate `gh`:

```bash
brew install gh          # macOS; on Linux see https://github.com/cli/cli#installation
gh auth login            # interactive: pick GitHub.com, HTTPS, authenticate in browser
gh auth status           # verify
```

For the `curl` fallback, export a personal access token (with `repo` scope) as `GITHUB_TOKEN`.

### Quick Auth Detection

```bash
# Determine which method to use throughout this workflow
if command -v gh &>/dev/null && gh auth status &>/dev/null; then
  AUTH="gh"
else
  AUTH="git"
  # Ensure we have a token for API calls
  if [ -z "$GITHUB_TOKEN" ]; then
    if grep -q "github.com" ~/.git-credentials 2>/dev/null; then
      GITHUB_TOKEN=$(grep "github.com" ~/.git-credentials 2>/dev/null | head -1 | sed 's|https://[^:]*:\([^@]*\)@.*|\1|')
    fi
  fi
fi
echo "Using: $AUTH"
```

### Extracting Owner/Repo from the Git Remote

Many `curl` commands need `owner/repo`. Extract it from the git remote:

```bash
# Works for both HTTPS and SSH remote URLs
REMOTE_URL=$(git remote get-url origin)
OWNER_REPO=$(echo "$REMOTE_URL" | sed -E 's|.*github\.com[:/]||; s|\.git$||')
OWNER=$(echo "$OWNER_REPO" | cut -d/ -f1)
REPO=$(echo "$OWNER_REPO" | cut -d/ -f2)
echo "Owner: $OWNER, Repo: $REPO"
```

---

## 1. Branch Creation

This part is pure `git` — identical either way:

```bash
# Make sure you're up to date
git fetch origin
git checkout main && git pull origin main

# Create and switch to a new branch
git checkout -b feat/add-user-authentication
```

Branch naming conventions:
- `feat/description` — new features
- `fix/description` — bug fixes
- `refactor/description` — code restructuring
- `docs/description` — documentation
- `ci/description` — CI/CD changes

## 2. Making Commits

Use the file tools (Write, Edit) to make changes, then commit:

```bash
# Stage specific files
git add src/auth.py src/models/user.py tests/test_auth.py

# Commit with a conventional commit message
git commit -m "feat: add JWT-based user authentication

- Add login/register endpoints
- Add User model with password hashing
- Add auth middleware for protected routes
- Add unit tests for auth flow"
```

Write messages in Conventional Commits format: `type(scope): short description`, body wrapped at 72 characters. Pick the type, breaking-change marker, and issue-linking syntax from `references/conventional-commits.md`.

## 3. Pushing and Creating a PR

### Push the Branch (same either way)

```bash
git push -u origin HEAD
```

### Check for an Existing PR First

A branch can only have one open PR. Before creating anything, check whether one already exists:

```bash
# With gh — returns PR info if the current branch already has one
gh pr view "$(git branch --show-current)" --json number,isDraft,url 2>/dev/null

# With git + curl
BRANCH=$(git branch --show-current)
curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$OWNER/$REPO/pulls?head=$OWNER:$BRANCH&state=open"
```

If a PR already exists:
- **Update it in place** (`gh pr edit` / `PATCH .../pulls/N`) — never create a second PR for the same branch.
- Preserve the existing review state — don't convert a ready-for-review PR back to draft. Only brand-new PRs created by this workflow may start as draft.
- When rewriting the body, preserve key existing content — especially **images and manually added notes** (the author may have no way to recover a removed image).

### PR Template Discovery

Before composing the PR body, check whether the repo defines its own template. Candidates, in order:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
ls "$REPO_ROOT/.github/pull_request_template.md" \
   "$REPO_ROOT/.github/PULL_REQUEST_TEMPLATE.md" \
   "$REPO_ROOT"/.github/pull_request_template/*.md \
   "$REPO_ROOT"/.github/PULL_REQUEST_TEMPLATE/*.md 2>/dev/null
```

- **Exactly one template** → read it and shape the PR body around it: keep its headings, required checklists, and repo-specific prompts; replace placeholder text with diff-specific content (or `N/A` where a section genuinely doesn't apply). Don't discard template sections just because the default body shape is shorter.
- **Multiple templates** → stop and ask the user which one to use.
- **No template** → fall back to the default body shape: a `## Summary` / `## Motivation`-style body, or the fuller skeletons in `assets/pr-body-feature.md` and `assets/pr-body-bugfix.md`.

### PR Body Content Rules

- Explain **why** first, then **what** changed. If the conversation discussed the motivation, capture it in the body.
- Describe the **net change** only — don't narrate approaches that were attempted and undone during development.
- Avoid absolute local paths (`/Users/you/...`); use repo-relative paths in backticks.
- Include verification claims **only when actually evidenced**: a reproduced bug, a before/after check, a targeted test of the changed behavior, or a manual scenario with observed output. Don't pad with generic linter/CI/"tests pass" filler; if a template requires a verification section and nothing was run, write `Not run` with a reason.
- Write the body to a temp file with real newlines and pass it via `--body-file` (avoids `\n`-escaped markdown):

```bash
gh pr create --title "..." --body-file /tmp/pr-body.md
gh pr edit --body-file /tmp/pr-body.md     # when updating an existing PR
```

### Create the PR

**With gh:**

```bash
gh pr create \
  --title "feat: add JWT-based user authentication" \
  --body "## Summary
- Adds login and register API endpoints
- JWT token generation and validation

## Test Plan
- [ ] Unit tests pass

Closes #42"
```

Options: `--draft`, `--reviewer user1,user2`, `--label "enhancement"`, `--base develop`

No `gh` available? Use the "Create the PR" section in `references/rest-fallbacks.md`.

## 4. Monitoring CI Status

### Check CI Status

**With gh:**

```bash
# One-shot check
gh pr checks

# Watch until all checks finish (polls every 10s)
gh pr checks --watch
```

No `gh` available? Use the "Check CI Status" section (including the polling loop) in `references/rest-fallbacks.md`.

## 5. Auto-Fixing CI Failures

When CI fails, diagnose and fix. This loop works with either auth method.

### Fast Path: Bundled Inspection Script (gh)

One command that does the whole diagnosis: lists failing checks, fetches the GitHub Actions run/job logs (with fallback to per-job logs when the run log is still pending), and extracts the failure snippet — it searches backwards from the end of the log for failure markers (`error`, `traceback`, `assert`, `panic`, …) and prints the surrounding context:

```bash
python3 ~/projects/dotfiles/claude-code/skills/github-pr-workflow/scripts/inspect_pr_checks.py --repo . --pr <number-or-url>

# Useful flags
#   --pr           PR number or URL (defaults to the current branch's PR)
#   --json         machine-friendly output for summarization
#   --max-lines N  cap snippet/tail length (default 160)
#   --context N    lines of context around the failure marker (default 30)
```

Checks whose `detailsUrl` is not a GitHub Actions run (e.g. Buildkite) are labeled `external` — only the URL is reported; don't try to scrape other providers. Exits non-zero while failing checks remain, so it can drive automation loops. Requires `gh`; with `curl`-only auth use the manual steps below.

For common failure patterns and fixes see `references/ci-troubleshooting.md`.

### Step 1: Get Failure Details

**With gh:**

```bash
# List recent workflow runs on this branch
gh run list --branch $(git branch --show-current) --limit 5

# View failed logs
gh run view <RUN_ID> --log-failed
```

No `gh` available? Use the "Get CI Failure Details" section in `references/rest-fallbacks.md`.

### Step 2: Fix and Push

After identifying the issue, use the file tools (Edit, Write) to fix it:

```bash
git add <fixed_files>
git commit -m "fix: resolve CI failure in <check_name>"
git push
```

### Step 3: Verify

Re-check CI status using the commands from Section 4 above.

### Auto-Fix Loop Pattern

When asked to auto-fix CI, follow this loop:

1. Check CI status → identify failures
2. Read failure logs → understand the error
3. Use Read + Edit/Write → fix the code
4. `git add . && git commit -m "fix: ..." && git push`
5. Wait for CI → re-check status
6. Repeat if still failing (up to 3 attempts, then ask the user)

## 6. Addressing Review Comments

When a PR comes back with feedback, address all three comment types — not just the conversation tab. A PR has three kinds of feedback: conversation comments, review submissions (Approve / Request changes / Comment), and inline review threads on specific lines. Plain `gh pr view --comments` misses inline threads; fetch everything via the GraphQL API.

### Step 1: Fetch All Comments

```bash
# Bundled script (requires gh): conversation comments + reviews + inline
# threads (with resolved/outdated state and file:line), cursor-paginated
# so nothing is dropped on busy PRs. Resolves the current branch's PR.
python3 ~/projects/dotfiles/claude-code/skills/github-pr-workflow/scripts/fetch_comments.py > /tmp/pr_comments.json
```

For the raw GraphQL query and the `curl` fallback see `references/review-comments.md`.

### Step 2: Present Grouped, Let the User Pick

Number every actionable item and group: conversation comments, review summaries, then **unresolved** inline threads (show `path:line`, author, and a one-line summary of what the fix would take). Skip threads that are already resolved; mark outdated ones. Then ask the user which numbered items to address — don't silently fix everything.

### Step 3: Fix, Reply, Resolve

For each selected item: fix the code, commit, push, then close the loop on GitHub:

```bash
# Reply inside an inline thread (COMMENT_ID = numeric databaseId of the thread's first comment)
gh api "repos/$OWNER/$REPO/pulls/$PR_NUMBER/comments/$COMMENT_ID/replies" \
  -f body="Fixed in $(git rev-parse --short HEAD)"

# Resolve the thread (THREAD_ID = GraphQL node id from the fetch output)
gh api graphql -f query='
  mutation { resolveReviewThread(input: {threadId: "<THREAD_ID>"}) {
    thread { isResolved } } }'
```

Only resolve threads you actually addressed; leave questions for the reviewer unresolved with a reply.

## 7. Merging

**With gh:**

```bash
# Squash merge + delete branch (cleanest for feature branches)
gh pr merge --squash --delete-branch

# Enable auto-merge (merges when all checks pass)
gh pr merge --auto --squash --delete-branch
```

No `gh` available? Use the "Merge the PR" section (including auto-merge) in `references/rest-fallbacks.md`.

## 8. Complete Workflow Example

```bash
# 1. Start from clean main
git checkout main && git pull origin main

# 2. Branch
git checkout -b fix/login-redirect-bug

# 3. (Agent makes code changes with file tools)

# 4. Commit
git add src/auth/login.py tests/test_login.py
git commit -m "fix: correct redirect URL after login

Preserves the ?next= parameter instead of always redirecting to /dashboard."

# 5. Push
git push -u origin HEAD

# 6. Create PR — check for an existing one and discover the repo template first
# ... (see Section 3)

# 7. Monitor CI (see Section 4); if red, auto-fix (see Section 5)

# 8. Address review comments if any (see Section 6)

# 9. Merge when green (see Section 7)
```

## Useful PR Commands Reference

| Action | gh | git + curl |
|--------|-----|-----------|
| List my PRs | `gh pr list --author @me` | `curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$OWNER/$REPO/pulls?state=open"` |
| View PR diff | `gh pr diff` | `git diff main...HEAD` (local) or `curl -H "Accept: application/vnd.github.diff" ...` |
| Add comment | `gh pr comment N --body "..."` | `curl -X POST .../issues/N/comments -d '{"body":"..."}'` |
| Request review | `gh pr edit N --add-reviewer user` | `curl -X POST .../pulls/N/requested_reviewers -d '{"reviewers":["user"]}'` |
| Close PR | `gh pr close N` | `curl -X PATCH .../pulls/N -d '{"state":"closed"}'` |
| Check out someone's PR | `gh pr checkout N` | `git fetch origin pull/N/head:pr-N && git checkout pr-N` |
