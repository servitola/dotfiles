# git/

Gitconfig fragments symlinked into `~/.gitconfig` (`install/07-config-links.sh`), plus the
machine-wide AI-footer guard below.

## AI co-author/tool footer guard

**Mechanism**: `git config --global init.templateDir ~/projects/dotfiles/git/hooks/template`
Git copies everything under a template dir's `hooks/` into
`.git/hooks/` on every `git init` and `git clone`, anywhere on the machine, for any repo. Our
template ships one file, `hooks/template/hooks/commit-msg` — a stub that `exec`s
`git/hooks/check-ai-footer.sh "$@"`. It's a stub and not the logic itself so a pattern fix in
`check-ai-footer.sh` reaches every already-materialized repo instantly, no re-init needed.

`check-ai-footer.sh` reads the commit message file, strips `#`-comment lines the way git itself
does, and greps case-insensitively for a short pattern list

Any match aborts the commit (exit 1) with the offending line on stderr, before the commit object
is ever created.

**Blind spots**:
- `git commit --no-verify` bypasses every hook, ours included — same as any git hook.
- Repos outside `~/projects` that existed before the backfill ran, and were never covered by a
  later `backfill.sh <root>` call.
- Bare repos and submodule gitlinks (`.git` as a file, not the `hooks/` case a `find -name .git
  -type d` sweep covers) aren't touched by `backfill.sh`; submodules inherit hooks from the
  superproject's `.git/modules/<name>/hooks`, a separate mechanism.
- A repo with its own pre-existing `commit-msg` hook (for something else, e.g. commitlint) is
  left alone by the backfill — the check has to be added to that hook by hand.
