---
name: github-repo-management
description: |
  Clone, create, fork, configure GitHub repos and manage remotes, branch protection, secrets, releases, workflows, and gists via the gh CLI or REST API.

  Use when: "склонируй репозиторий", "создай репозиторий на гитхабе", "сделай форк", "выпусти релиз", "настрой защиту ветки", "clone a repo", "create a github repo", "fork this repo", "cut a release", "set a repo secret"
---

# GitHub Repository Management

Create, clone, fork, configure, and manage GitHub repositories. Sections below show the `gh` way; for machines without `gh`, the equivalent `git` + `curl` commands live in [rest-fallbacks.md](references/rest-fallbacks.md) under the same heading names.

## Prerequisites

The GitHub CLI (`gh`) installed and authenticated, or a `GITHUB_TOKEN` for the REST fallback.

```bash
brew install gh          # macOS; on Linux see https://github.com/cli/cli#installation
gh auth login            # interactive: pick GitHub.com, HTTPS, authenticate in browser
gh auth status           # verify
```

No `gh`? Before any `curl` command, run the auth-detection and variable block (`GITHUB_TOKEN`, `GH_USER`, `OWNER`, `REPO`) from [rest-fallbacks.md § Setup](references/rest-fallbacks.md#setup).

## What do you need?

Work with a repo?
- Clone it → [Section 1](#1-cloning) (pure git)
- Create one (blank, from local dir, from template) → [Section 2](#2-creating)
- Fork it / sync a fork → [Section 3](#3-forking)
- Inspect or search repos → [Section 4](#4-repository-information)
- Change settings / topics / visibility → [Section 5](#5-repository-settings)

Configure, protect, or publish?
- Branch protection → REST-only; apply the payloads in [rest-fallbacks.md § Branch Protection](references/rest-fallbacks.md#branch-protection)
- Actions secrets → [Section 6](#6-secrets-github-actions)
- Releases → [Section 7](#7-releases)
- Workflow runs / CI → [Section 8](#8-workflows-github-actions)
- Gists → [Section 9](#9-gists)

Working without `gh`? Each section's `curl` equivalent lives in [rest-fallbacks.md](references/rest-fallbacks.md) (table of contents at top). For raw endpoint/method lookup, pagination, and rate limits, use [github-api-cheatsheet.md](references/github-api-cheatsheet.md). Load the smallest set of references that fits the task.

## 1. Cloning

Pure `git` — works identically with or without `gh`:

```bash
git clone https://github.com/owner/repo-name.git                  # HTTPS
git clone https://github.com/owner/repo-name.git ./my-local-dir   # into a specific directory
git clone --depth 1 https://github.com/owner/repo-name.git        # shallow (faster for large repos)
git clone --branch develop https://github.com/owner/repo-name.git # specific branch
git clone git@github.com:owner/repo-name.git                      # SSH (if configured)

# gh shorthand
gh repo clone owner/repo-name
gh repo clone owner/repo-name -- --depth 1
```

## 2. Creating

```bash
gh repo create my-new-project --public --clone
gh repo create my-new-project --private --description "A useful tool" --license MIT --clone
gh repo create my-org/my-new-project --public --clone   # under an organization

# From an existing local directory
cd /path/to/existing/project
gh repo create my-project --source . --public --push

# From a template
gh repo create my-new-app --template owner/template-repo --public --clone
```

## 3. Forking

```bash
gh repo fork owner/repo-name --clone    # fork + clone + upstream remote
gh repo sync $GH_USER/repo-name         # keep the fork in sync (shortcut)
```

Sync a fork with pure git (works everywhere):

```bash
git fetch upstream
git checkout main
git merge upstream/main
git push origin main
```

## 4. Repository Information

```bash
gh repo view owner/repo-name
gh repo list --limit 20
gh search repos "machine learning" --language python --sort stars
```

## 5. Repository Settings

```bash
gh repo edit --description "Updated description" --visibility public
gh repo edit --enable-wiki=false --enable-issues=true
gh repo edit --default-branch main
gh repo edit --add-topic "machine-learning,python"
gh repo edit --enable-auto-merge
```

## 6. Secrets (GitHub Actions)

```bash
gh secret set API_KEY --body "your-secret-value"
gh secret set SSH_KEY < ~/.ssh/id_rsa
gh secret list
gh secret delete API_KEY
```

`gh secret set` handles encryption for you; the `curl` path seals the value with the repo public key via PyNaCl — steps in [rest-fallbacks.md § Secrets](references/rest-fallbacks.md#secrets). If a secret needs setting and `gh` isn't available, recommend installing it for just that operation.

## 7. Releases

```bash
gh release create v1.0.0 --title "v1.0.0" --generate-notes
gh release create v2.0.0-rc1 --draft --prerelease --generate-notes
gh release create v1.0.0 ./dist/binary --title "v1.0.0" --notes "Release notes"   # with asset
gh release list
gh release download v1.0.0 --dir ./downloads
```

## 8. Workflows (GitHub Actions)

```bash
gh workflow list
gh run list --limit 10
gh run view <RUN_ID>
gh run view <RUN_ID> --log-failed
gh run rerun <RUN_ID>
gh run rerun <RUN_ID> --failed
gh workflow run ci.yml --ref main
gh workflow run deploy.yml -f environment=staging
```

## 9. Gists

```bash
gh gist create script.py --public --desc "Useful script"
gh gist list
```

## Quick Reference Table

| Action | gh | git + curl |
|--------|-----|-----------|
| Clone | `gh repo clone o/r` | `git clone https://github.com/o/r.git` |
| Create repo | `gh repo create name --public` | `curl POST /user/repos` |
| Fork | `gh repo fork o/r --clone` | `curl POST /repos/o/r/forks` + `git clone` |
| Repo info | `gh repo view o/r` | `curl GET /repos/o/r` |
| Edit settings | `gh repo edit --...` | `curl PATCH /repos/o/r` |
| Create release | `gh release create v1.0` | `curl POST /repos/o/r/releases` |
| List workflows | `gh workflow list` | `curl GET /repos/o/r/actions/workflows` |
| Rerun CI | `gh run rerun ID` | `curl POST /repos/o/r/actions/runs/ID/rerun` |
| Set secret | `gh secret set KEY` | `curl PUT /repos/o/r/actions/secrets/KEY` (+ encryption) |
