# where_is_my_space

One-command macOS cleanup. Removes caches, logs, crash reports, and temporary files to free disk space.

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/servitola/dotfiles/master/cleanup/cleanup_all.sh | zsh
```

## What Gets Cleaned

**System**
- Library Caches (`~/Library/Caches`, `/Library/Caches`)
- Crash reports, diagnostic reports, core dumps
- DNS cache flush
- `.DS_Store` and `.AppleDouble` files
- ASL logs, previous system information
- Zsh completion cache rebuild

**Development**
- Xcode: DerivedData, archives, simulator logs
- JetBrains: IDE caches and logs
- VSCode / Windsurf: logs, cached data
- Android SDK cache, Gradle cache
- NuGet cache, NPM logs, NPX cache
- pre-commit and Puppeteer caches

**Applications**
- Steam: logs, app cache, depot cache, shader cache, temp, downloads
- Discord cache
- Obsidian caches (Cache, Code Cache, GraphiteCache, WebGPU)
- Battle.net old versions and logs
- Heroic launcher cache
- Adobe media cache
- Google Updater cache
- Yandex Browser extension cache
- Claude Desktop cache
- IINA, Moises, Messages attachments

**Homebrew**
- Cask installers (`.pkg`, `.dmg`, `.zip`, `.tar.gz` left in Caskroom)

**Trash**
- User Trash, Volume Trashes

## Requirements

- macOS
- zsh (default shell on macOS)
- sudo access (for system caches and protected directories)

## How It Works

Each directory is checked before cleaning — if it doesn't exist or is already empty, it's skipped silently. The script shows a spinner during cleanup and reports the size freed for each item. At the end, it shows the total space freed and available disk space.

## Part of [servitola/dotfiles](https://github.com/servitola/dotfiles)

When used within dotfiles, the `up` command runs this cleanup automatically after system updates.
