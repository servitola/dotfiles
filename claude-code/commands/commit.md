---
description: Stage and commit current changes in dotfiles [component] style
argument-hint: [optional intent hint]
---

Optional intent hint from user: $ARGUMENTS

# What to do

1. Run in parallel:
   - `git status` (no `-uall`)
   - `git diff` (unstaged)
   - `git diff --cached` (staged)
   - `git log --pretty=format:%s --no-merges -20` (style reference)
2. Group changed files into **logical units**. If the diff spans multiple unrelated changes, propose splitting into separate commits — one per logical change. Per `~/CLAUDE.md`: atomic commits, never `git add -A` / `git add .`.
3. For each commit, draft a message:
   - Subject: `[component] lowercase imperative description`
   - `component` = top-level directory of the changed files (`litellm`, `hammerspoon`, `claude-code`, `zsh`, `homebrew`, `docker`, `voiceink`, `keyboard-layout`, `karabiner`, `git`, `Makefile`, `opencode`, `qwen-code`, `codex`, `amp`, `rag`, `qdrant`, `mistral-vibe`). Special-case: `hotkeys` for `hammerspoon/Spoons/Hotkeys.spoon`, `docker-logger` for `docker/logger`. Multi-component: `[a and b]`.
   - Verbs: add / fix / improve / remove / adjust / save / install / update / connect / refactor / rename / disable / enable.
   - ≤72 chars, no trailing period, no Conventional Commits prefixes (`feat:`, `fix:`, etc.), no emojis.
   - Body only if the *why* is genuinely non-obvious — and then it explains *why*, not *what*.
4. Print the plan as a numbered list:
   ```
   1. [component] message   →   files: a/b.lua, c/d.sh
   2. [other] message       →   files: e/f.json
   ```
   Then ask the user to confirm before executing.
5. On confirmation, for each commit run sequentially:
   - `git add <explicit files>` (NEVER `-A` / `.`)
   - `git commit -m "..."` via HEREDOC.
6. After all commits, run `git status` once to confirm clean state.

# Rules

- Read the diff. Never invent changes not in it.
- If only one logical change exists, skip the split — draft one message and confirm.
- If nothing is staged AND nothing is unstaged, say so and stop.
- If $ARGUMENTS gives a hint, use it to bias verb/component but stay grounded in the diff.
- Don't run pre-commit hooks with `--no-verify`. If a hook fails, surface the error and stop.
- Never push. Never amend.
