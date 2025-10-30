.PHONY: install

SHELL := /bin/zsh -c
REMOVE := sudo rm -rf
LINK :=sudo ln -sfvh
COPY := sudo cp -r

install:

	@$(SHELL) 'source zsh/functions.sh'
	@$(SHELL) 'source zsh/exports.sh'
	@$(SHELL) 'source macos/set_defaults.sh'
	@$(SHELL) 'source xcode/install.sh'
	@$(SHELL) 'source homebrew/install.sh'
	@$(SHELL) 'source homebrew/install_minimum_homebrew_packages.sh'
	@echo "Linking Homebrew completions for external commands"
	@brew completions link

	@$(SHELL) 'source zsh/setup_zsh.sh'

	@echo "setup hosts file (perhaps you need to do it manually later)"
	@$(REMOVE) /etc/hosts
	@$(LINK) ~/projects/dotfiles/macos/hosts /etc/hosts

	@echo "setup Birman Layout"
	@$(REMOVE) /Library/Keyboard\ Layouts/Birman.bundle
	@$(COPY) ~/projects/dotfiles/keyboard-layout/Birman.bundle /Library/Keyboard\ Layouts/Birman.bundle

	@echo "setup git symlinks"
	@$(REMOVE) ~/.gitconfig
	@$(LINK) ~/projects/dotfiles/git/gitconfig ~/.gitconfig
	@$(REMOVE) ~/.config/git/ignore
	@$(LINK) ~/projects/dotfiles/git/global_ignore ~/.config/git/ignore

	@echo "setup karabiner symlinks"
	@$(REMOVE) ~/.config/karabiner
	@$(LINK) ~/projects/dotfiles/karabiner ~/.config/karabiner

	@echo "setup goku symlinks"
	@$(REMOVE) ~/.config/karabiner.edn
	@$(LINK) ~/projects/dotfiles/goku/karabiner.edn ~/.config/karabiner.edn

	@echo "setup hammerspoon symlinks"
	@$(REMOVE) ~/.hammerspoon
	@$(LINK) ~/projects/dotfiles/hammerspoon ~/.hammerspoon
	@open /Applications/Hammerspoon.app

	@echo "setup midnight commander symlink"
	@$(REMOVE) ~/.config/mc
	@$(LINK) ~/projects/dotfiles/midnight\ commander ~/.config/mc

	@echo "setup Claude"
	@mkdir -p ~/.claude
	@$(REMOVE) ~/.claude/CLAUDE.md
	@$(LINK) ~/projects/dotfiles/claude-code/CLAUDE.md ~/.claude/CLAUDE.md

	@echo "setup Windsurf user settings symlinks"
	@mkdir -p ~/Library/Application\ Support/Windsurf\ -\ Next/User

	@$(REMOVE) ~/Library/Application\ Support/Windsurf\ -\ Next/User/settings.json
	@$(LINK) ~/projects/dotfiles/windsurf/User/settings.json ~/Library/Application\ Support/Windsurf\ -\ Next/User/settings.json

	@$(REMOVE) ~/Library/Application\ Support/Windsurf\ -\ Next/User/keybindings.json
	@$(LINK) ~/projects/dotfiles/windsurf/User/keybindings.json ~/Library/Application\ Support/Windsurf\ -\ Next/User/keybindings.json

	@mkdir -p ~/.codeium/windsurf-next/memories
	@$(REMOVE) ~/.codeium/windsurf-next/memories/global_rules.md
	@$(LINK) ~/projects/dotfiles/windsurf/global_rules.md ~/.codeium/windsurf-next/memories/global_rules.md

	@echo "setup VSCode user settings symlinks"
	@mkdir -p ~/Library/Application\ Support/Code/User
	@$(REMOVE) ~/Library/Application\ Support/Code/User/settings.json
	@$(LINK) ~/projects/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
	@$(REMOVE) ~/Library/Application\ Support/Code/User/keybindings.json
	@$(LINK) ~/projects/dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json

	@echo "setup Cursor user settings symlinks"
	@mkdir -p ~/Library/Application\ Support/Cursor/User
	@$(REMOVE) ~/Library/Application\ Support/Cursor/User/keybindings.json
	@$(LINK) ~/projects/dotfiles/cursor/keybindings.json ~/Library/Application\ Support/Cursor/User/keybindings.json
	@$(REMOVE) ~/Library/Application\ Support/Cursor/User/settings.json
	@$(LINK) ~/projects/dotfiles/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json

	@echo "setup yt-dlp"
	@mkdir -p ~/.config/yt-dlp
	@$(REMOVE) ~/.config/yt-dlp/config
	@$(LINK) ~/projects/dotfiles/yt-dlp/config ~/.config/yt-dlp/config

	@echo "setup iina shortcuts"
	@mkdir -p ~/Library/Application\ Support/com.colliderli.iina/input_conf
	@$(REMOVE) ~/Library/Application\ Support/com.colliderli.iina/input_conf/servitola.conf
	@$(LINK) ~/projects/dotfiles/iina/servitola.conf ~/Library/Application\ Support/com.colliderli.iina/input_conf/servitola.conf

	@echo "Setting up Rider vmoptions symlink for all Rider installations"
	@sh -c '\
	for dir in "~/Library/Application Support/JetBrains"/Rider*; do \
		if [ -d "$$dir" ]; then \
			echo "Updating: $$dir/rider.vmoptions"; \
			$(REMOVE) "$$dir/rider.vmoptions"; \
			$(LINK) "~/projects/dotfiles/jetbrains rider/rider.vmoptions" "$$dir/rider.vmoptions"; \
		fi; \
	done'

	@echo "setup btop symlinks"
	@$(REMOVE) ~/.config/btop
	@$(LINK) ~/projects/dotfiles/btop ~/.config/btop

	@echo "setup bat symlinks"
	@$(REMOVE) ~/.config/bat
	@$(LINK) ~/projects/dotfiles/bat ~/.config/bat

	@echo "setup eza symlinks"
	@$(REMOVE) ~/.config/eza
	@$(LINK) ~/projects/dotfiles/eza ~/.config/eza

	@echo "setup nano symlinks"
	@$(REMOVE) ~/.nanorc
	@$(LINK) ~/projects/dotfiles/nano/nanorc ~/.nanorc

	@echo "setup aichat symlinks"
	@mkdir -p ~/Library/Application\ Support/aichat
	@$(REMOVE) ~/Library/Application\ Support/aichat/config.yaml
	@$(LINK) ~/projects/dotfiles/Library/Application\ Support/aichat/config.yaml ~/Library/Application\ Support/aichat/config.yaml

	@echo "setup Claude Desktop config symlink"
	@mkdir -p ~/Library/Application\ Support/Claude
	@$(REMOVE) ~/Library/Application\ Support/Claude/claude_desktop_config.json
	@$(LINK) ~/projects/dotfiles/claude-desktop/claude_desktop_config.json ~/Library/Application\ Support/Claude/claude_desktop_config.json

	@echo "setup Claude Code settings symlink"
	@mkdir -p ~/.claude
	@$(REMOVE) ~/.claude/settings.json
	@$(LINK) ~/projects/dotfiles/claude-code/settings.json ~/.claude/settings.json

	@echo "setup yazi symlinks"
	@$(REMOVE) ~/.config/yazi
	@$(LINK) ~/projects/dotfiles/yazi/.config/yazi ~/.config/yazi

	@echo "setup ampcode settings"
	@$(REMOVE) ~/.config/amp
	@$(LINK) ~/projects/dotfiles/amp ~/.config/amp

	@echo "setup noti"
	@$(REMOVE) ~/.config/noti
	@$(LINK) ~/projects/dotfiles/noti ~/.config/noti

	@echo "setup lazydocker symlinks"
	@$(REMOVE) ~/Library/Application\ Support/lazydocker/config.yml
	@$(LINK) ~/projects/dotfiles/lazydocker/config.yml ~/Library/Application\ Support/lazydocker/config.yml

	@echo "setup Fork custom commands symlink"
	@mkdir -p ~/Library/Application\ Support/com.DanPristupov.Fork
	@$(REMOVE) ~/Library/Application\ Support/com.DanPristupov.Fork/custom-commands.json
	@$(LINK) ~/projects/dotfiles/fork/custom-commands.json ~/Library/Application\ Support/com.DanPristupov.Fork/custom-commands.json

	@echo "setup Colima for containers"
	@mkdir -p ~/.colima/default
	@$(REMOVE) ~/.colima/default/colima.yaml
	@$(LINK) ~/projects/dotfiles/colima/colima.yaml ~/.colima/default/colima.yaml

	@echo "set default applications for different file extensions"
	@$(SHELL) 'source macos/set_default_apps.sh'

	@echo "run dock setup. Run once again when dockutil is installed please!"
	@$(SHELL) 'source macos/dock_setup.sh'

	@echo "setting iTerm2 to use settings from dotfiles"
	@$(SHELL) 'source iterm/install.sh'

	@echo "installing Global NPM Packages"
	@$(SHELL) 'source npm/install-globals.sh'

	@echo "Syncing gruvbox-wallpapers"
	@~/projects/dotfiles/macos/sync_gruvbox_wallpapers.sh

	@m appearance --highlightcolor grape

	@$(SHELL) 'source ableton/setup-mcp.sh'

	@echo "setup ghostty symlinks"
	@mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
	@$(REMOVE) ~/Library/Application\ Support/com.mitchellh.ghostty/config
	@$(LINK) ~/projects/dotfiles/ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config

	@echo "Installation complete!"
