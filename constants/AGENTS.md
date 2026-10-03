# constants/

Every value true about this machine — paths, browser of the day, chat ids,
proxies — so nothing hardcodes them again.

| File | Role |
|---|---|
| `../constants.env` | The values. One file, in git. |
| `load.zsh` | Exports them, via `zsh/exports.sh` → every shell, service, cron job. |
| `constants.py` | `from constants import K`, where there is no shell. |
| `../hammerspoon/constants.lua` | `require("constants")` — in `hammerspoon/`, the only path its `require` sees. |
| `render-all.zsh` | Runs every `*/render.zsh`. Called by `const sync`, `install/07-config-links.sh`, `up`. |
| `template.zsh` | `render <config>` → `~/.local/state/dotfiles/generated/<same name>`. |
| `../<app>/render.zsh` | Two lines: source `template.zsh`, `render` that config. Today `git/`, `nuget/`. |
| `../zsh/bin/const` | The CLI — how an AI agent reads a value. |

`KEY=value`, no quotes, no `export`; the value is the rest of the line verbatim.
`#` only at line start — inline it lands inside the value. `$HOME` is the one
expansion every reader does; `${HOME}` is not.

```zsh
$APP_BROWSER       # already exported in any shell
const app.browser  # dots and case normalise to APP_BROWSER
const list DIR_    # namespaces: ME_ APP_ DIR_ FILE_ TG_ PROXY_ HOST_ MODEL_
```

## Generated consumers

git config and NuGet XML expand nothing, so their configs are templates: the repo
file keeps its ordinary name (`git/identity.gitconfig`, `nuget/NuGet.Config`) and
holds `${CONSTANT}` — edit that one, then `const sync`. `<app>/render.zsh`
expands it into `~/.local/state/dotfiles/generated/`, where the `~/.nuget`
symlink and the `git/gitconfig` include point. A new consumer is one two-line
`render.zsh`, registered nowhere.

Every `$` expands, comments included — a literal one needs `\$`; an unknown name
aborts the render instead of writing empty. Nothing generated is in the repo: if
git asks who you are, the render never ran.

## Rules

- A value belongs here when a second consumer needs it — not every string.
- Secrets are fine: the repo is private and self-hosted.
- Adding a key needs no installer step, symlink or regeneration.
- Consumers read the constant, never copy it. `hammerspoon/browsers.lua`:
  `APP_BROWSER` picks `M.main`, unknown name fails loudly.
- `app = "@APP_BROWSER"` in a keyboard chord resolves in three places that must
  stay in step: `HotKeys.spoon/init.lua`, `docs/keyboard/parse_active.py`,
  `docs/keyboard/app_constants.py`.
- `APP_*` is the role vocabulary of the keyboard layout: a chord binds `@APP_IDE`,
  not `Rider`. Adding a role means a chord (or another consumer) exists for it;
  `_BUNDLE` and `_CLI` suffixes are companions of the same role, not roles.
