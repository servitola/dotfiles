#!/bin/zsh
# Step 07 — symlink app configs. Tables of source -> destination, grouped by
# where they land; the three at the bottom link then do a dependent action.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "home dotfiles (~)"
link_all \
    "$DOTFILES/git/gitconfig"          "$HOME/.gitconfig" \
    "$DOTFILES/tmux/tmux.conf"         "$HOME/.tmux.conf" \
    "$DOTFILES/nano/nanorc"            "$HOME/.nanorc" \
    "$DOTFILES/nuget/NuGet.Config"     "$HOME/.nuget/NuGet/NuGet.Config" \
    "$DOTFILES/zap"                    "$HOME/.zap"

section "XDG config (~/.config)"
link_all \
    "$DOTFILES/git/global_ignore"      "$CONFIG/git/ignore" \
    "$DOTFILES/btop"                   "$CONFIG/btop" \
    "$DOTFILES/bat"                    "$CONFIG/bat" \
    "$DOTFILES/eza"                    "$CONFIG/eza" \
    "$DOTFILES/ripgrep/ripgreprc"      "$CONFIG/ripgrep/ripgreprc" \
    "$DOTFILES/atuin/config.toml"      "$CONFIG/atuin/config.toml" \
    "$DOTFILES/noti"                   "$CONFIG/noti" \
    "$DOTFILES/yt-dlp/config"          "$CONFIG/yt-dlp/config" \
    "$DOTFILES/midnight commander"     "$CONFIG/mc"

section "Application Support"
link_all \
    "$DOTFILES/rtk/config.toml"        "$APP_SUPPORT/rtk/config.toml" \
    "$DOTFILES/rtk/filters.toml"       "$APP_SUPPORT/rtk/filters.toml" \
    "$DOTFILES/vscode/settings.json"   "$APP_SUPPORT/Code/User/settings.json" \
    "$DOTFILES/vscode/keybindings.json" "$APP_SUPPORT/Code/User/keybindings.json" \
    "$DOTFILES/iina/servitola.conf"    "$APP_SUPPORT/com.colliderli.iina/input_conf/servitola.conf" \
    "$DOTFILES/lazydocker/config.yml"  "$APP_SUPPORT/lazydocker/config.yml" \
    "$DOTFILES/lazygit/config.yml"     "$APP_SUPPORT/lazygit/config.yml" \
    "$PRIVATE/fork/custom-commands.json" "$APP_SUPPORT/com.DanPristupov.Fork/custom-commands.json" \
    "$DOTFILES/ghostty/config"         "$APP_SUPPORT/com.mitchellh.ghostty/config" \
    "$DOTFILES/marta/conf.marco"       "$APP_SUPPORT/org.yanex.marta/conf.marco" \
    "$DOTFILES/marta/favorites.marco"  "$APP_SUPPORT/org.yanex.marta/favorites.marco" \
    "$DOTFILES/marta/themes"           "$APP_SUPPORT/org.yanex.marta/Themes" \
    "$DOTFILES/marta/plugins"          "$APP_SUPPORT/org.yanex.marta/Plugins" \
    "$DOTFILES/heroic/config.json"     "$APP_SUPPORT/heroic/config.json" \
    "$DOTFILES/agent-of-empires"       "$APP_SUPPORT/agent-of-empires"

section "karabiner (link, then build karabiner.json from rules)"
link "$DOTFILES/karabiner" "$CONFIG/karabiner"
"$DOTFILES/karabiner/build.sh"

section "hammerspoon (link, then launch the app)"
link "$DOTFILES/hammerspoon" "$HOME/.hammerspoon"
open /Applications/Hammerspoon.app

section "Rider vmoptions (one per installed Rider)"
# null_glob: zsh aborts on an unmatched glob (no Rider installed)
setopt null_glob
for rider_dir in "$APP_SUPPORT/JetBrains"/Rider*; do
    test -d "$rider_dir" || continue
    link "$DOTFILES/jetbrains rider/rider.vmoptions" \
         "$rider_dir/rider.vmoptions"
done
