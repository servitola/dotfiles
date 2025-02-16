.PHONY: install

SHELL := /bin/zsh

install:
	@$(SHELL) -c 'source zsh/functions.sh'
	@$(SHELL) -c 'source zsh/exports.sh'
	@$(SHELL) -c 'source macos/set_defaults.sh'
	@$(SHELL) -c 'source xcode/install.sh'
	@$(SHELL) -c 'source homebrew/install.sh'
	@$(SHELL) -c 'source homebrew/install_minimum_homebrew_packages.sh'
	@$(SHELL) -c 'source zsh/setup_zsh.sh'

	@echo "setup hosts file (perhaps you need to do it manually later)"
	@sudo rm -rf /etc/hosts
	@sudo ln -sfvh ~/projects/dotfiles/macos/hosts /etc/hosts

	@echo "setup git symlinks"
	@rm -rf ~/.gitconfig
	@ln -sfvh ~/projects/dotfiles/git/gitconfig ~/.gitconfig

	@echo "setup karabiner symlinks"
	@rm -rf ~/.config/karabiner
	@ln -sfvh ~/projects/dotfiles/karabiner ~/.config/karabiner

	@echo "setup goku symlinks"
	@rm -rf ~/.config/karabiner.edn
	@ln -sfvh ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

	@echo "setup hammerspoon symlinks"
	@rm -rf ~/.hammerspoon
	@ln -sfvh ~/projects/dotfiles/hammerspoon ~/.hammerspoon
	@open /Applications/Hammerspoon.app

	@echo "setup midnight commander symlink"
	@rm -rf ~/.config/mc
	@ln -sfvh ~/projects/dotfiles/midnight\ commander ~/.config/mc

	@echo "setup Windsurf user settings symlinks"
	@mkdir -p ~/Library/Application\ Support/Windsurf/User
	@rm -f ~/Library/Application\ Support/Windsurf/User/settings.json
	@ln -sfvh ~/projects/dotfiles/windsurf/User/settings.json ~/Library/Application\ Support/Windsurf/User/settings.json
	@rm -f ~/Library/Application\ Support/Windsurf/User/keybindings.json
	@ln -sfvh ~/projects/dotfiles/windsurf/User/keybindings.json ~/Library/Application\ Support/Windsurf/User/keybindings.json
	@rm -f ~/.codeium/windsurf/memories/global_rules.md
	@ln -sfvh ~/projects/dotfiles/windsurf/global_rules.md ~/.codeium/windsurf/memories/global_rules.md

	@echo "setup flameshot symlinks"
	@rm -rf ~/.config/flameshot
	@ln -sfvh ~/projects/dotfiles/flameshot ~/.config/flameshot

	@echo "setup Rider vmoptions symlink"
	@rm -rf ~/Library/Application\ Support/JetBrains/Rider2024.3/rider.vmoptions
	@ln -sfvh ~/projects/dotfiles/jetbrains\ rider/rider.vmoptions ~/Library/Application\ Support/JetBrains/Rider2024.3/rider.vmoptions

	@echo "setup LINQPad symlinks"
	@rm -rf ~/LINQPad
	@ln -sfvh ~/projects/dotfiles/LINQPad ~/LINQPad

	@echo "setup Appium symlinks"
	@rm -rf ~/.appium
	@ln -sfvh ~/projects/dotfiles/appium/.appium ~/.appium

	@echo "set default applications for different file extensions"
	@$(SHELL) -c 'source macos/set_default_apps.sh'

	@echo "run dock setup. Run once again when dockutil is installed please!"
	@$(SHELL) -c 'source macos/dock_setup.sh'

	@echo "installing trash-cli to replace rm with trash"
	@npm install --global trash-cli

	@echo "installing vsce to publish vscode extensions"
	@npm install --global vsce
	@npm install --global typescript

	@echo "installing Finder Context Menu"
	@rm -rf ~/Library/Group\ Containers/85P8ZUTQL8.net.langui.ContextMenu/Actions
	@ln -sfvh ~/projects/dotfiles/contextmenu/Actions ~/Library/Group\ Containers/85P8ZUTQL8.net.langui.ContextMenu/Actions
	@mkdir -p ~/Library/Application\ Scripts/net.langui.ContextMenuHelper
	@echo '#!/bin/sh\npkill -nf ScriptMonitor\nexec "$$@"' > ~/Library/Application\ Scripts/net.langui.ContextMenuHelper/contextmenu.sh
	@chmod +x ~/Library/Application\ Scripts/net.langui.ContextMenuHelper/contextmenu.sh

	@echo "Installation complete!"
