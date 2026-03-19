# Design Decisions — Why Things Are This Way

Detailed explanations for decisions that aren't obvious from reading the code.
For quick reference, see MEMORY.md.

## Shell Architecture

### exports.sh vs exports-path.sh vs zshrc.sh
- `exports.sh` (via zshenv): ALL env vars, hardcoded Homebrew constants (no `eval brew shellenv` — saves ~30ms per subshell). Runs for every shell type including scripts
- `exports-path.sh` (via zprofile): ALL PATH entries using `path+=()`. Runs `eval brew shellenv` here for proper PATH ordering. Only login shells
- `zshrc.sh`: Only interactive setup. No env vars, no PATH manipulation. Clean separation

### Atuin --disable-up-arrow
Atuin 18.13.3+ ignores `up_arrow = false` in config.toml. The `--disable-up-arrow` CLI flag is the only reliable way. Manual bindkey overrides after `atuin init` are kept as additional safety.

## Karabiner Build System

`karabiner.json` is generated from 25 separate rule files:
- `rules/01-06`: Core remappings (Tab layer, Caps→Hyper, Grave→Escape, F-keys)
- `rules/07-17`: Hyper layer split by modifier (hyper-only, hyper-shift, hyper-command, etc.)
- `rules/18`: Non-hyper misc modifiers
- `rules/19-25`: Small standalone rules (brightness, alt shortcuts, fn→control, music)

Build: `cd karabiner && ./build.sh` (uses jq to merge template + rule files)

## Hammerspoon Async Pattern

GruvboxWallpapers.spoon and any new network/shell operations MUST use `hs.task.new()` callbacks. `io.popen()` blocks the main thread, freezing all hotkeys and window management.

## BrowserTabOpener Tab Cycling

AppleScript searches tabs with `contains`, tracks current active tab position, returns next match (wrapping). Tab switching via `set active tab index of front window` — this is the only reliable method. `hs.urlevent.openURLWithBundle` just re-focuses the same tab. AppleScript tabs don't have an `index` property — must use positional counter.

## Layout Switching Reliability

macOS sometimes silently reverts `hs.keycodes.setLayout()` during app activation transitions. The retry loop (5 attempts at 30ms intervals, 150ms total window) catches these race conditions.
