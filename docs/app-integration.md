# App Integration Guide

**Checklist:**
1. Create `~/projects/dotfiles/{app-name}/` directory (lowercase, hyphen-separated)
2. Add/copy config files to the directory
3. Add a `link` line to the right installer step (see below)
4. Test the symlink manually (don't run full `make install`)

**Installer Integration:**
The install logic is plain zsh (`install.sh` runs the numbered
`install/[0-9]*.sh` steps), not make. Add a `source -> destination` pair to
the right `link_all` table — usually `install/07-config-links.sh` (app
configs) or `install/08-ai-tools-links.sh` (AI tools):

```zsh
link_all \
    "$DOTFILES/{app-dir}/{config_file}" "{target_path}" \
    ...
```

`link_all` (and `link` for a one-off) is defined in `install/lib.sh` and does
mkdir-parent + `sudo rm -rf` + `sudo ln -sfvh`, so you don't repeat those.
Use `copy_dir` instead when a real copy is needed (e.g. the Birman layout in
`install/05-system-links.sh`).

**Path vars (from `install/lib.sh`):** `$DOTFILES`, `$PRIVATE`,
`$APP_SUPPORT` (= `~/Library/Application Support`), `$CONFIG` (= `~/.config`),
`$CLAUDE_CODE`, `$LAUNCH_AGENTS`.

**Testing:** run just the one step (`zsh install/07-config-links.sh`), then
check the symlink resolves, before a full `make install`.

**Common Patterns** (each is one `src dst` pair inside a `link_all` table):
- **Single file**: `"$DOTFILES/app/config.json" "$CONFIG/app/config.json"`
- **Directory**:   `"$DOTFILES/app" "$CONFIG/app"`
- **App Support**: `"$DOTFILES/app/config.plist" "$APP_SUPPORT/App/config.plist"`
  (quote the whole path — spaces in "Application Support" are handled by the quotes)

**Examples:**
See `install/07-config-links.sh` for real working examples from your current setup.
