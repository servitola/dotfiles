# Skills extraction: move the Claude skills and commands out of dotfiles into `~/projects/skills`

**Status:** approved 2026-10-10, not implemented.

## Why

`claude-code/skills/` (87 skills), `claude-code/detached_skills/` (23) and
`claude-code/commands/` (12) are personal — friends' bots, family computers,
private services. Dotfiles cannot be published with them inside. The owner
wants every skill and command out, and dotfiles to keep only the harness: the
hooks, settings, agents, scripts and an instruction "point `DIR_SKILLS` at your
own repository and run the install step". Agents stay: they are the harness,
not content. Same pattern as the cron move (`2026-10-09-cron-extraction-design.md`).

## Design

**Repository.** `~/projects/skills`, private on Gitea, history of the three
directories via `git subtree split`. Layout unchanged: `skills/`,
`detached_skills/`, `commands/`. Data about skills moves with them:
`skill-presets.json`, `skill-tests/`, `shared/skills-repos/` (third-party skill
repositories: `install.sh`, `update.sh`, `repos.txt`; the clones themselves stay
git-ignored). The repository gets its own `.pre-commit-config.yaml` with the
`lint-skill-frontmatter` hook (Codex skips a skill whose `description` exceeds
1024 characters) — the hook is about skills, so it leaves dotfiles.

**Constant.** `DIR_SKILLS=$HOME/projects/skills`. `DIR_CLAUDE` stays as the
harness directory.

**Harness in dotfiles.** `~/.claude` remains a symlink to `claude-code/`. Inside
it, `skills`, `detached_skills` and `commands` become symlinks into
`$DIR_SKILLS`, created by `install/08-ai-tools-links.sh` and git-ignored. Every
consumer that goes through `~/.claude/skills/<name>` is therefore untouched:
friends' `serho-users/*/.claude/skills` links, Codex (`~/.agents/skills`),
OpenCode (`~/.config/opencode/commands`), plugins. Consumers that name the
dotfiles path move to `$DIR_SKILLS`: `claude-code/scripts/skill_cli.py`
(`SOURCES`, `PRESETS_FILE`), `claude-code/scripts/sync-friend-skills.py`,
`launchagents/com.servitola.sync-friend-skills.plist` and the four
`serho-users/*/.claude/settings.json` (absolute paths — launchd and Claude Code
expand nothing), `claude-code/shared/scripts/bind-topic-skill.sh`,
`hammerspoon/Spoons/VoiceCtl.spoon/init.lua` (`detached_skills/voice-mac/aliases.json`),
`~/projects/cron/scripts/insight-miner-nightly.sh`, `.gitignore`
(`claude-code/skills/agents-best-practices/`, `shared/skills-repos`),
`claude-code/AGENTS.md`, `docs/repo-map.md`, `docs/commands.md`.

**What dotfiles keeps publishable:** `claude-code/` without a single skill or
command, and an `AGENTS.md` paragraph that says: set `DIR_SKILLS`, put `skills/`,
`detached_skills/`, `commands/` there, run `zsh install/08-ai-tools-links.sh`.

**Verification.** `ls ~/.claude/skills | wc -l` = 87 and `~/.claude/commands`
= 12 through the links; `skill list` works; `ls ~/.agents/skills` shows the
skills (Codex); `sync-friend-skills` dry run reports no change; the frontmatter
hook is green in the new repository; `pre-commit run --all-files` is green in
dotfiles; `python3 constants/check.py` passes.

## Out of scope

- Friends' own `user-skills/` in `serho-users` — a different repository.
- `claude-code/plugins/` (marketplace cache) and `claude-code/agents/`.
- Merging `detached_skills/` into `skills/` with a flag.
