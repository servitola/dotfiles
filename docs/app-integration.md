# App Integration Guide

**Checklist:**
1. Create `~/projects/dotfiles/{app-name}/` directory (lowercase, hyphen-separated)
2. Add/copy config files to the directory
3. Add Makefile symlink commands using patterns below
4. Test symlinks manually (don't run full `make install`)

**Makefile Integration:**
Add to `install` target:
```makefile
@echo "setup {app description}"
@mkdir -p {target_parent}
@$(REMOVE) {target_path}
@$(LINK) ~/projects/dotfiles/{app-dir}/{config_file} {target_path}
```

**Variables:** `REMOVE := sudo rm -rf`, `LINK := sudo ln -sfvh`, `COPY := sudo cp -r`

**Testing:** After adding to Makefile, test symlinks manually with the commands you added before running full `make install`.

**Common Patterns:**
- **Single file**: `@$(LINK) ~/projects/dotfiles/app/config.json ~/.config/app/config.json`
- **Directory**: `@$(LINK) ~/projects/dotfiles/app ~/.config/app`
- **App Support**: `@$(LINK) ~/projects/dotfiles/app/config.plist ~/Library/Application\ Support/App/config.plist`

**Examples:**
See @./Makefile for real working examples from your current setup.
