# Skills Extraction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move `claude-code/{skills,detached_skills,commands}` plus the skill data (`skill-presets.json`, `skill-tests/`, `shared/skills-repos/`) into the private repository `~/projects/skills`, leaving dotfiles with the harness and three git-ignored symlinks that `install/08` creates from `$DIR_SKILLS`.

**Architecture:** `~/.claude` stays a symlink to `claude-code/`; inside it the three content directories become symlinks into `$DIR_SKILLS`, so every path of the form `~/.claude/skills/<name>` keeps working. Consumers that name the dotfiles path by hand are retargeted at `$DIR_SKILLS` (or its absolute value where nothing expands variables). History travels with `git subtree split`.

**Tech Stack:** zsh, git subtree, perl in-place edits, pre-commit.

Spec: `docs/superpowers/specs/2026-10-10-skills-extraction-design.md`.

## Global Constraints

- New repository: `~/projects/skills`, private on Gitea. Constant `DIR_SKILLS=$HOME/projects/skills`.
- Layout inside it: `skills/`, `detached_skills/`, `commands/`, `skill-presets.json`, `skill-tests/`, `shared/skills-repos/` (clones git-ignored, scripts tracked).
- `agents/`, `hooks/`, `scripts/`, `settings.json`, `CLAUDE.md`, `AGENTS.md` stay in dotfiles.
- Absolute paths stay absolute where nothing expands variables: launchd plists, Claude Code `settings.json` permissions. Everywhere else `$DIR_SKILLS`.
- `rm` is aliased to `trash`; use `/bin/rm` for a real delete. Never push dotfiles; push `~/projects/skills` (the owner asked for it on Gitea).
- Commit in dotfiles with `PATH=/opt/homebrew/opt/python@3/libexec/bin:$PATH` in front so the constants hook finds python 3.14.
- Comments and docs in English.

---

### Task 1: Create `~/projects/skills` with history and every file

**Files:**
- Create: `~/projects/skills/` (repository), `~/projects/skills/.gitignore`, `~/projects/skills/.pre-commit-config.yaml`, `~/projects/skills/.git-hooks/lint-skill-frontmatter.sh`

- [ ] **Step 1: Baseline counts**

```bash
ls ~/.claude/skills | wc -l; ls ~/.claude/detached_skills | wc -l; ls ~/.claude/commands | wc -l
```
Expected: `87`, `23`, `12`.

- [ ] **Step 2: Split history and create the repository**

```bash
cd ~/projects/dotfiles
git subtree split --prefix=claude-code -b skills-history
mkdir ~/projects/skills && cd ~/projects/skills && git init -q -b master
git pull -q ~/projects/dotfiles skills-history
git -C ~/projects/dotfiles branch -D skills-history
git rm -rq --quiet $(git ls-files | grep -vE '^(skills|detached_skills|commands|skill-tests|shared/skills-repos)/|^skill-presets\.json$')
git commit -q -m "Keep only the skills, commands and their data from claude-code"
ls
```
Expected: `commands detached_skills shared skill-presets.json skill-tests skills` (and `shared/` holds only `skills-repos/`).

- [ ] **Step 3: Bring over the untracked skills and the clones**

```bash
rsync -a --exclude '__pycache__/' --exclude '.DS_Store' ~/projects/dotfiles/claude-code/skills/ ~/projects/skills/skills/
rsync -a --exclude '__pycache__/' --exclude '.DS_Store' ~/projects/dotfiles/claude-code/detached_skills/ ~/projects/skills/detached_skills/
rsync -a ~/projects/dotfiles/claude-code/commands/ ~/projects/skills/commands/
rsync -a ~/projects/dotfiles/claude-code/skill-tests/ ~/projects/skills/skill-tests/
rsync -a ~/projects/dotfiles/claude-code/shared/skills-repos/ ~/projects/skills/shared/skills-repos/
cp ~/projects/dotfiles/claude-code/skill-presets.json ~/projects/skills/
for d in skills detached_skills commands skill-tests shared/skills-repos; do diff -rq --exclude __pycache__ --exclude .DS_Store ~/projects/dotfiles/claude-code/$d ~/projects/skills/$d && echo "$d SAME"; done
```
Expected: five `SAME` lines.

- [ ] **Step 4: Ignore rules and the frontmatter hook**

`~/projects/skills/.gitignore`:
```
__pycache__/
.DS_Store
# External skill repos: scripts and manifest are tracked, clones are not.
shared/skills-repos/*/
!shared/skills-repos/install.sh
!shared/skills-repos/update.sh
!shared/skills-repos/repos.txt
# External skill clone (github.com/DenisSergeevitch/agents-best-practices)
skills/agents-best-practices/
```

```bash
mkdir -p .git-hooks && cp ~/projects/dotfiles/.git-hooks/lint-skill-frontmatter.sh .git-hooks/
```

`~/projects/skills/.pre-commit-config.yaml`:
```yaml
repos:
  - repo: local
    hooks:
      - id: lint-skill-frontmatter
        name: Validate Claude Code skill frontmatter
        entry: .git-hooks/lint-skill-frontmatter.sh
        language: system
        files: ^(skills|detached_skills)/[^/]+/SKILL\.md$
        stages: [pre-commit]
```

```bash
pre-commit install >/dev/null && git add -A . && git status --short | grep -c '^A' && git commit -q -m "Add the skills dotfiles never tracked, the ignore rules and the frontmatter hook" && pre-commit run --all-files | tail -1
```
Expected: ~26 added skill directories, hook `Passed`.

---

### Task 2: Constant and the symlinks in dotfiles

**Files:**
- Modify: `constants.env` (after `DIR_CLAUDE`), `constants/schema.toml:49`, `install/08-ai-tools-links.sh:5-8`, `.gitignore:20-31`

- [ ] **Step 1: Constant**

`constants.env`: after the `DIR_CLAUDE=` line add `DIR_SKILLS=$HOME/projects/skills`.
`constants/schema.toml`: after `DIR_CLAUDE` add `DIR_SKILLS       = { type = "dir", about = "Claude skills, detached skills and commands (~/projects/skills)" }`.

- [ ] **Step 2: install/08 creates the three links**

Replace the `section "Claude"` block with:
```zsh
section "Claude"
link_all \
    "$CLAUDE_CODE"                     "$HOME/.claude" \
    "$DOTFILES/claude-code-memory"     "$CLAUDE_PROJECT/memory" \
    "${DIR_SKILLS:?}/skills"           "$CLAUDE_CODE/skills" \
    "${DIR_SKILLS:?}/detached_skills"  "$CLAUDE_CODE/detached_skills" \
    "${DIR_SKILLS:?}/commands"         "$CLAUDE_CODE/commands"
```

- [ ] **Step 3: .gitignore**

Replace the `shared/skills-repos` block and the `agents-best-practices` block with:
```
# Content lives in $DIR_SKILLS; install/08 links it here.
claude-code/skills
claude-code/detached_skills
claude-code/commands
```

- [ ] **Step 4: Replace the directories with links (the install step needs sudo; do the same by hand)**

```bash
cd ~/projects/dotfiles
git rm -rq claude-code/skills claude-code/detached_skills claude-code/commands claude-code/skill-tests claude-code/shared/skills-repos claude-code/skill-presets.json
/bin/rm -rf claude-code/skills claude-code/detached_skills claude-code/commands claude-code/skill-tests claude-code/shared/skills-repos
for d in skills detached_skills commands; do ln -sfh ~/projects/skills/$d claude-code/$d; done
ls ~/.claude/skills | wc -l; ls ~/.claude/commands | wc -l; ls ~/.agents/skills | wc -l; ls ~/projects/serho-users/renata/.claude/skills/arxiv/SKILL.md
```
Expected: `87`, `12`, `87`, the friend's link resolves.

---

### Task 3: Consumers that named the dotfiles path

**Files:**
- Modify: `claude-code/scripts/skill_cli.py:27-43,254`, `claude-code/shared/scripts/bind-topic-skill.sh:27-28`, `hammerspoon/Spoons/VoiceCtl.spoon/init.lua:12-13`, `launchagents/com.servitola.sync-friend-skills.plist:15`, `~/projects/cron/scripts/insight-miner-nightly.sh:8`, `~/projects/serho-users/{dimka,heyusocute,renata,zuho}/.claude/settings.json:40`, `.pre-commit-config.yaml:52-57`

- [ ] **Step 1: skill_cli.py**

```python
SKILLS = Path(os.environ["DIR_SKILLS"])
PRESETS_FILE = SKILLS / "skill-presets.json"
SOURCES = {
    "public": SKILLS / "skills",
    "public-detached": SKILLS / "detached_skills",
    "bot-shared": TOPICS / ".claude" / "skills",
}
```
(`DOTFILES` stays for `sync-friend-skills.py`, which remains in dotfiles.) Add `import os` if missing. Rename the labels' meaning in the docstring: "public" now means "the shared skill set".

- [ ] **Step 2: shell, Lua, plist, cron, friends**

`bind-topic-skill.sh`: the two `"$HOME/projects/dotfiles/claude-code/..."` lines → `"${DIR_SKILLS:?}/skills"` and `"${DIR_SKILLS:?}/detached_skills"`.
`VoiceCtl.spoon/init.lua`: `"/projects/dotfiles/claude-code/detached_skills/voice-mac/aliases.json"` → `"/projects/skills/detached_skills/voice-mac/aliases.json"` (Hammerspoon has no constants loader for this Spoon; `hammerspoon/constants.lua` exists — use `require("constants").DIR_SKILLS .. "/detached_skills/voice-mac/aliases.json"` if the Spoon can `require` it, else the literal).
`launchagents/com.servitola.sync-friend-skills.plist` line 15: `$HOME/projects/skills/skills` written out as the absolute home path (launchd expands nothing); then `launchctl bootout gui/$UID/com.servitola.sync-friend-skills; launchctl bootstrap gui/$UID ~/Library/LaunchAgents/com.servitola.sync-friend-skills.plist`.
`~/projects/cron/scripts/insight-miner-nightly.sh`: `"${DIR_SKILLS:?}/skills/insight-miner/scripts/collect.py"`.
Friends' `settings.json`: `perl -pi -e 's#/projects/dotfiles/claude-code/skills/#/projects/skills/skills/#g'` on the four files; `python3 -m json.tool` each.
`.pre-commit-config.yaml`: delete the `lint-skill-frontmatter` hook entry and `.git-hooks/lint-skill-frontmatter.sh`.

- [ ] **Step 3: Verify**

```bash
grep -rnE 'dotfiles/claude-code/(skills|detached_skills|commands)|claude-code/skill-presets|claude-code/skill-tests' --exclude-dir=.git --exclude-dir=projects --exclude-dir=paste-cache --exclude-dir=file-history --exclude-dir=plans --exclude-dir=superpowers --exclude='*.jsonl' . | grep -v AGENTS.md
skill list | head -3
python3 claude-code/scripts/sync-friend-skills.py --all --dry-run 2>&1 | tail -2
```
Expected: no grep hits; `skill list` prints skills; the dry run reports nothing to change (if the script has no `--dry-run`, run `--all` and expect "0 changes").

---

### Task 4: Docs, commits, remote

**Files:**
- Modify: `claude-code/AGENTS.md:1-8`, `docs/repo-map.md:16`, `docs/commands.md:22-28`, `AGENTS.md` (handoff), `~/projects/skills/AGENTS.md` (create)

- [ ] **Step 1: Docs**

`claude-code/AGENTS.md` lines 1–8: title → `# claude-code — the Claude Code harness (hooks, settings, agents, scripts); skills and commands live in $DIR_SKILLS`; add after the symlink list: `- `skills/`, `detached_skills/`, `commands/` are symlinks into `$DIR_SKILLS` (`~/projects/skills`, private), created by `install/08-ai-tools-links.sh` and git-ignored. To use this harness with your own skills: set `DIR_SKILLS` in `constants.env`, put `skills/`, `detached_skills/`, `commands/` there, run `zsh install/08-ai-tools-links.sh`.`
`docs/repo-map.md:16`: say the content moved to `~/projects/skills` on 2026-10-10.
`docs/commands.md`: the `skill*` rows mention `$DIR_SKILLS`.
`~/projects/skills/AGENTS.md` (+ `CLAUDE.md`, `WARP.md` symlinks): what is here, how dotfiles links it, the detached-skills rule, the frontmatter limits, `skill-presets.json`, `shared/skills-repos`.
Dotfiles `AGENTS.md` handoff: a `**State (2026-10-10, skills moved out)**` paragraph.

- [ ] **Step 2: Checks and commits**

```bash
cd ~/projects/dotfiles && export PATH=/opt/homebrew/opt/python@3/libexec/bin:$PATH
python3 constants/check.py && pre-commit run --all-files | grep -c Failed
git add constants.env constants/schema.toml install/08-ai-tools-links.sh .gitignore claude-code/scripts/skill_cli.py claude-code/shared/scripts/bind-topic-skill.sh hammerspoon/Spoons/VoiceCtl.spoon/init.lua launchagents/com.servitola.sync-friend-skills.plist .pre-commit-config.yaml claude-code/AGENTS.md docs/repo-map.md docs/commands.md
git commit -m "[claude-code] skills, detached skills and commands move to ~/projects/skills behind DIR_SKILLS"
git add AGENTS.md && git commit -m "[claude-code] handoff: skills repository"
cd ~/projects/skills && git add AGENTS.md CLAUDE.md WARP.md && git commit -m "Describe the repository"
cd ~/projects/cron && git commit -am "insight-miner reads the skill from DIR_SKILLS" && git push -q origin master
```

- [ ] **Step 3: Gitea**

```bash
source ~/.config/gitea_token.sh; C=~/.config/gitea-ca/clients/mac
curl -s --cert $C/mac.crt --key $C/mac.key -H "Authorization: token $GITEA_TOKEN" -H 'Content-Type: application/json' -X POST "$GITEA_URL/api/v1/user/repos" -d '{"name":"skills","private":true,"default_branch":"master","description":"Claude Code skills, detached skills and commands. Moved out of dotfiles 2026-10-10."}' | jq -r .full_name
cd ~/projects/skills && git remote add origin https://gitea.example.com/servitola/skills.git && git push -u origin master
```
Expected: `servitola/skills`, push ok.
