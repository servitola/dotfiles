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
	@mkdir -p ~/Library/Application\ Support/Windsurf\ -\ Next/User

	@rm -f ~/Library/Application\ Support/Windsurf\ -\ Next/User/settings.json
	@ln -sfvh ~/projects/dotfiles/windsurf/User/settings.json ~/Library/Application\ Support/Windsurf\ -\ Next/User/settings.json

	@rm -f ~/Library/Application\ Support/Windsurf\ -\ Next/User/keybindings.json
	@ln -sfvh ~/projects/dotfiles/windsurf/User/keybindings.json ~/Library/Application\ Support/Windsurf\ -\ Next/User/keybindings.json

	@rm -f ~/.codeium/windsurf-next/memories/global_rules.md
	@ln -sfvh ~/projects/dotfiles/windsurf/global_rules.md ~/.codeium/windsurf-next/memories/global_rules.md

	@echo "setup VSCode user settings symlinks"
	@mkdir -p ~/Library/Application\ Support/Code/User
	@rm -f ~/Library/Application\ Support/Code/User/settings.json
	@ln -sfvh ~/projects/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
	@rm -f ~/Library/Application\ Support/Code/User/keybindings.json
	@ln -sfvh ~/projects/dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

	@echo "setup yt-dlp"
	@mkdir -p ~/.config/yt-dlp
	@rm -f ~/.config/yt-dlp/config
	@ln -sfvh ~/projects/dotfiles/yt-dlp/config ~/.config/yt-dlp/config

	@echo "setup iina shortcuts"
	@mkdir -p ~/Library/Application\ Support/com.colliderli.iina/input_conf
	@rm -f ~/Library/Application\ Support/com.colliderli.iina/input_conf/servitola.conf
	@ln -sfvh ~/projects/dotfiles/iina/servitola.conf ~/Library/Application\ Support/com.colliderli.iina/input_conf/servitola.conf

	@echo "Setting up Rider vmoptions symlink for all Rider installations"
	@sh -c '\
	for dir in "~/Library/Application Support/JetBrains"/Rider*; do \
		if [ -d "$$dir" ]; then \
			echo "Updating: $$dir/rider.vmoptions"; \
			rm -rf "$$dir/rider.vmoptions"; \
			ln -sfvh "~/projects/dotfiles/jetbrains rider/rider.vmoptions" "$$dir/rider.vmoptions"; \
		fi; \
	done'

	@echo "setup Appium symlinks"
	@rm -rf ~/.appium
	@ln -sfvh ~/projects/dotfiles/appium/.appium ~/.appium

	@echo "setup btop symlinks"
	@rm -rf ~/.config/btop
	@ln -sfvh ~/projects/dotfiles/btop ~/.config/btop

	@echo "setup bat symlinks"
	@rm -rf ~/.config/bat
	@ln -sfvh ~/projects/dotfiles/bat ~/.config/bat

	@echo "setup eza symlinks"
	@rm -rf ~/.config/eza
	@ln -sfvh ~/projects/dotfiles/eza ~/.config/eza

	@echo "setup aichat symlinks"
	@mkdir -p ~/Library/Application\ Support/aichat
	@rm -rf ~/Library/Application\ Support/aichat/config.yaml
	@ln -sfvh ~/projects/dotfiles/Library/Application\ Support/aichat/config.yaml ~/Library/Application\ Support/aichat/config.yaml

	@echo "setup Claude Desktop config symlink"
	@mkdir -p ~/Library/Application\ Support/Claude
	@rm -rf ~/Library/Application\ Support/Claude/claude_desktop_config.json
	@ln -sfvh ~/projects/dotfiles/claude-desktop/claude_desktop_config.json ~/Library/Application\ Support/Claude/claude_desktop_config.json

	@echo "setup yazi symlinks"
	@rm -rf ~/.config/yazi
	@ln -sfvh ~/projects/dotfiles/yazi/.config/yazi ~/.config/yazi

	@echo "setup alt-tab symlinks"
	@mkdir -p ~/Library/Preferences
	@rm -rf ~/Library/Preferences/com.lwouis.alt-tab-macos.plist
	@ln -sfvh ~/projects/dotfiles/alt-tab/Library/Preferences/com.lwouis.alt-tab-macos.plist ~/Library/Preferences/com.lwouis.alt-tab-macos.plist

	@echo "setup Fork custom commands symlink"
	@mkdir -p ~/Library/Application\ Support/com.DanPristupov.Fork
	@rm -rf ~/Library/Application\ Support/com.DanPristupov.Fork/custom-commands.json
	@ln -sfvh ~/projects/dotfiles/fork/custom-commands.json ~/Library/Application\ Support/com.DanPristupov.Fork/custom-commands.json

	@echo "setup bin directory"
	@mkdir -p ~/.local/bin
	@rm -rf ~/.local/bin/analyze-ui-test
	@ln -sfvh ~/projects/dotfiles/bin/analyze-ui-test.sh ~/.local/bin/analyze-ui-test

	@echo "set default applications for different file extensions"
	@$(SHELL) -c 'source macos/set_default_apps.sh'

	@echo "run dock setup. Run once again when dockutil is installed please!"
	@$(SHELL) -c 'source macos/dock_setup.sh'

	@echo "installing trash-cli to replace rm with trash"
	@npm install --global trash-cli

	@echo "installing vsce to publish vscode extensions"
	@npm install --global vsce
	@npm install --global typescript

	@echo "Installing Context Menu settings..."
	@rm -rf ~/Library/Group\ Containers/85P8ZUTQL8.net.langui.ContextMenu
	@rm -rf ~/Library/Application\ Scripts/net.langui.ContextMenu*
	@ln -sf ~/projects/dotfiles/contextmenu/85P8ZUTQL8.net.langui.ContextMenu ~/Library/Group\ Containers/
	@find ~/projects/dotfiles/contextmenu -name "net.langui.ContextMenu*" -exec ln -sf {} ~/Library/Application\ Scripts/ \;

	@if [ ! -d "$(HOME)/projects/gruvbox-wallpapers" ]; then \
		echo "Cloning gruvbox-wallpapers repository..."; \
		git clone --depth 1 https://github.com/AngelJumbo/gruvbox-wallpapers.git $(HOME)/projects/gruvbox-wallpapers \
	else \
		echo "gruvbox-wallpapers repository already cloned."; \
		cd $(HOME)/projects/gruvbox-wallpapers && git fetch --depth=1 origin && git reset --hard origin/main; \
	fi

	@m appearance highlightcolor grape

	@$(SHELL) -c 'source ableton/setup-mcp.sh'

	@echo "Installation complete!"
