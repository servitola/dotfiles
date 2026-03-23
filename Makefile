.PHONY: install

SHELL := /bin/zsh -c
REMOVE := sudo rm -rf
LINK := sudo ln -sfvh
COPY := sudo cp -r

install:

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

	@echo "copy 'Birman Keyboard Layout' to /Library/Keyboard Layouts/"
	@$(REMOVE) /Library/Keyboard\ Layouts/Birman.bundle
	@$(COPY) ~/projects/dotfiles/keyboard-layout/Birman.bundle /Library/Keyboard\ Layouts/Birman.bundle

	@echo "setup git symlinks"
	@$(REMOVE) ~/.gitconfig
	@$(LINK) ~/projects/dotfiles/git/gitconfig ~/.gitconfig
	@mkdir -p ~/.config/git
	@$(REMOVE) ~/.config/git/ignore
	@$(LINK) ~/projects/dotfiles/git/global_ignore ~/.config/git/ignore

	@echo "setup karabiner symlinks"
	@$(REMOVE) ~/.config/karabiner
	@$(LINK) ~/projects/dotfiles/karabiner ~/.config/karabiner

	@echo "setup hammerspoon symlinks"
	@$(REMOVE) ~/.hammerspoon
	@$(LINK) ~/projects/dotfiles/hammerspoon ~/.hammerspoon
	@open /Applications/Hammerspoon.app

	@echo "setup midnight commander symlink"
	@$(REMOVE) ~/.config/mc
	@$(LINK) ~/projects/dotfiles/midnight\ commander ~/.config/mc

	@echo "setup Claude"
	@$(REMOVE) ~/.claude
	@$(LINK) ~/projects/dotfiles/claude-code ~/.claude
	@mkdir -p ~/.claude/projects/-Users-servitola-projects-dotfiles
	@$(REMOVE) ~/.claude/projects/-Users-servitola-projects-dotfiles/memory
	@$(LINK) ~/projects/dotfiles/claude-code-memory ~/.claude/projects/-Users-servitola-projects-dotfiles/memory

	@echo "setup Windsurf user settings symlinks"
	@mkdir -p ~/Library/Application\ Support/Windsurf/User

	@$(REMOVE) ~/Library/Application\ Support/Windsurf/User/settings.json
	@$(LINK) ~/projects/dotfiles/windsurf/User/settings.json ~/Library/Application\ Support/Windsurf/User/settings.json

	@$(REMOVE) ~/Library/Application\ Support/Windsurf/User/keybindings.json
	@$(LINK) ~/projects/dotfiles/windsurf/User/keybindings.json ~/Library/Application\ Support/Windsurf/User/keybindings.json

	@mkdir -p ~/.codeium/windsurf/memories
	@$(REMOVE) ~/.codeium/windsurf/memories/global_rules.md
	@$(LINK) ~/projects/dotfiles/windsurf/global_rules.md ~/.codeium/windsurf/memories/global_rules.md

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
	for dir in "$$HOME/Library/Application Support/JetBrains"/Rider*; do \
		if [ -d "$$dir" ]; then \
			echo "Updating: $$dir/rider.vmoptions"; \
			$(REMOVE) "$$dir/rider.vmoptions"; \
			$(LINK) "$$HOME/projects/dotfiles/jetbrains rider/rider.vmoptions" "$$dir/rider.vmoptions"; \
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

	@echo "setup atuin symlinks"
	@mkdir -p ~/.config/atuin
	@$(REMOVE) ~/.config/atuin/config.toml
	@$(LINK) ~/projects/dotfiles/atuin/config.toml ~/.config/atuin/config.toml

	@echo "setup nano symlinks"
	@$(REMOVE) ~/.nanorc
	@$(LINK) ~/projects/dotfiles/nano/nanorc ~/.nanorc

	@echo "setup nuget symlinks"
	@mkdir -p ~/.nuget/NuGet
	@$(REMOVE) ~/.nuget/NuGet/NuGet.Config
	@$(LINK) ~/projects/dotfiles/nuget/NuGet.Config ~/.nuget/NuGet/NuGet.Config


	@echo "setup Claude Desktop config symlink"
	@mkdir -p ~/Library/Application\ Support/Claude
	@$(REMOVE) ~/Library/Application\ Support/Claude/claude_desktop_config.json
	@$(LINK) ~/projects/dotfiles/claude-desktop/claude_desktop_config.json ~/Library/Application\ Support/Claude/claude_desktop_config.json


	@echo "setup Qwen Code symlinks"
	@mkdir -p ~/.qwen
	@$(REMOVE) ~/.qwen/settings.json
	@$(LINK) ~/projects/dotfiles/qwen-code/settings.json ~/.qwen/settings.json
	@$(REMOVE) ~/.qwen/QWEN.md
	@$(LINK) ~/projects/dotfiles/qwen-code/QWEN.md ~/.qwen/QWEN.md
	@$(REMOVE) ~/.qwen/skills
	@$(LINK) ~/projects/dotfiles/claude-code/skills ~/.qwen/skills
	@$(REMOVE) ~/.qwen/agents
	@$(LINK) ~/projects/dotfiles/claude-code/agents ~/.qwen/agents
	@$(REMOVE) ~/.qwen/commands
	@$(LINK) ~/projects/dotfiles/claude-code/commands ~/.qwen/commands

	@echo "setup yazi symlinks"
	@$(REMOVE) ~/.config/yazi
	@$(LINK) ~/projects/dotfiles/yazi/.config/yazi ~/.config/yazi

	@echo "setup ampcode settings"
	@mkdir -p ~/.config/amp
	@$(REMOVE) ~/.config/amp/settings.json
	@$(LINK) ~/projects/dotfiles/amp/settings.json ~/.config/amp/settings.json
	@$(REMOVE) ~/.config/amp/tools
	@$(LINK) ~/projects/dotfiles/amp/tools ~/.config/amp/tools
	@$(REMOVE) ~/.config/amp/commands
	@$(LINK) ~/projects/dotfiles/claude-code/commands ~/.config/amp/commands
	@$(REMOVE) ~/.config/amp/agents
	@$(LINK) ~/projects/dotfiles/claude-code/agents ~/.config/amp/agents
	@$(REMOVE) ~/.config/amp/skills
	@$(LINK) ~/projects/dotfiles/claude-code/skills ~/.config/amp/skills

	@echo "setup OpenCode symlinks"
	@mkdir -p ~/.opencode
	@$(REMOVE) ~/.opencode/opencode.json
	@$(LINK) ~/projects/dotfiles/opencode/opencode.json ~/.opencode/opencode.json
	@echo "setup noti"
	@$(REMOVE) ~/.config/noti
	@$(LINK) ~/projects/dotfiles/noti ~/.config/noti

	@echo "setup lazydocker symlinks"
	@mkdir -p ~/Library/Application\ Support/lazydocker
	@$(REMOVE) ~/Library/Application\ Support/lazydocker/config.yml
	@$(LINK) ~/projects/dotfiles/lazydocker/config.yml ~/Library/Application\ Support/lazydocker/config.yml

	@echo "setup lazygit symlinks"
	@mkdir -p ~/Library/Application\ Support/lazygit
	@$(REMOVE) ~/Library/Application\ Support/lazygit/config.yml
	@$(LINK) ~/projects/dotfiles/lazygit/config.yml ~/Library/Application\ Support/lazygit/config.yml

	@echo "setup Fork custom commands symlink"
	@mkdir -p ~/Library/Application\ Support/com.DanPristupov.Fork
	@$(REMOVE) ~/Library/Application\ Support/com.DanPristupov.Fork/custom-commands.json
	@$(LINK) ~/projects/dotfiles/fork/custom-commands.json ~/Library/Application\ Support/com.DanPristupov.Fork/custom-commands.json

	@echo "setup agent-of-empires (aoe) symlink"
	@$(REMOVE) ~/Library/Application\ Support/agent-of-empires
	@$(LINK) ~/projects/dotfiles/agent-of-empires ~/Library/Application\ Support/agent-of-empires

	@echo "set default applications for different file extensions"
	@$(SHELL) 'source macos/set_default_apps.sh'

	@echo "run dock setup. Run once again when dockutil is installed please!"
	@$(SHELL) 'source macos/dock_setup.sh'

	@echo "setting iTerm2 to use settings from dotfiles"
	@$(SHELL) 'source iterm/install.sh'

	@echo "installing Global NPM Packages"
	@$(SHELL) 'source npm/install-globals.sh'

	@echo 'setting aichat'
	@mkdir -p ~/Library/Application\ Support/aichat
	@$(REMOVE) ~/Library/Application\ Support/aichat/config.yaml
	@$(LINK) ~/projects/dotfiles/aichat/config.yaml ~/Library/Application\ Support/aichat/config.yaml
	@$(REMOVE) ~/Library/Application\ Support/aichat/dark.tmTheme
	@$(LINK) ~/projects/dotfiles/aichat/dark.tmTheme ~/Library/Application\ Support/aichat/dark.tmTheme

	@$(SHELL) 'source ableton/setup-mcp.sh'

	@echo "setup ghostty symlinks"
	@mkdir -p ~/Library/Application\ Support/com.mitchellh.ghostty
	@$(REMOVE) ~/Library/Application\ Support/com.mitchellh.ghostty/config
	@$(LINK) ~/projects/dotfiles/ghostty/config ~/Library/Application\ Support/com.mitchellh.ghostty/config

	@echo "setup Marta symlinks"
	@mkdir -p ~/Library/Application\ Support/org.yanex.marta
	@$(REMOVE) ~/Library/Application\ Support/org.yanex.marta/conf.marco
	@$(LINK) ~/projects/dotfiles/marta/conf.marco ~/Library/Application\ Support/org.yanex.marta/conf.marco
	@$(REMOVE) ~/Library/Application\ Support/org.yanex.marta/favorites.marco
	@$(LINK) ~/projects/dotfiles/marta/favorites.marco ~/Library/Application\ Support/org.yanex.marta/favorites.marco
	@$(REMOVE) ~/Library/Application\ Support/org.yanex.marta/Themes
	@$(LINK) ~/projects/dotfiles/marta/themes ~/Library/Application\ Support/org.yanex.marta/Themes
	@$(REMOVE) ~/Library/Application\ Support/org.yanex.marta/Plugins
	@$(LINK) ~/projects/dotfiles/marta/plugins ~/Library/Application\ Support/org.yanex.marta/Plugins

	@echo "setup Heroic Launcher symlinks"
	@mkdir -p ~/Library/Application\ Support/heroic
	@$(REMOVE) ~/Library/Application\ Support/heroic/config.json
	@$(LINK) ~/projects/dotfiles/heroic/config.json ~/Library/Application\ Support/heroic/config.json

	@echo "setup Warp terminal symlinks"
	@$(REMOVE) ~/.warp
	@$(LINK) ~/projects/dotfiles/warp ~/.warp

	@echo "Making scripts executable"
	@chmod +x \
		cleanup/clean.sh \
		cleanup/cleanup_all.sh \
		cleanup/helpers.sh \
		cleanup/try_clean.sh \
		cleanup/cleanup_targets.sh \
		macos/update_all_and_cleanup_all.sh \
		macos/update_all.sh \
		macos/cleanup_all.sh \
		macos/set_defaults.sh \
		macos/set_default_apps.sh \
		macos/dock_setup.sh \
		macos/helpers/try_to_clean_directory.sh \
		macos/helpers/try_to_clean_by_pattern.sh \
		macos/helpers/download_wallpaper.sh \
		macos/helpers/fetch_wallpaper_url.sh \
		macos/helpers/set_macos_default_if_different.sh \
		macos/helpers/set_plist_value_if_different.sh \
		macos/helpers/colors.sh \
		homebrew/install.sh \
		homebrew/install_all_homebrew_packages.sh \
		homebrew/install_minimum_homebrew_packages.sh \
		npm/install-globals.sh \
		python/install-globals.sh \
		python/install-uv-tools.sh \
		n8n/install.sh \
		n8n/n8n-service.sh \
		n8n/n8n-start.sh \
		iterm/install.sh \
		xcode/install.sh \
		zsh/setup_zsh.sh \
		zsh/bin/random_ascii.sh \
		ableton/setup-mcp.sh \
		karabiner/build.sh \
		claude-desktop/deepseek-mcp.sh \
		claude-desktop/github-mcp.sh \
		claude-desktop/google-calendar-mcp.sh \
		claude-desktop/google-maps-mcp.sh

	@echo "precommit setup"
	@cd ~/projects/dotfiles/ && pre-commit install

	@echo "setup cron jobs"
	@~/projects/dotfiles/cron/init-cron-jobs.sh

	@echo "Installation complete!"
	@echo
	@$(SHELL) 'source zsh/bin/random_ascii.sh'
