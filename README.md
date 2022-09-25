# servitola dotfiles

![Screenshot of my shell prompt](https://i.imgur.com/8dgnsIb.jpg)
## Installation & Details:
* [Karabiner](https://karabiner-elements.pqrs.org/) mimics my [AnnePro2](https://www.annepro.net/) layout. [Hammerspoon](hammerspoon.org/) does the rest. So [Karabiner](https://karabiner-elements.pqrs.org/) + [Hammerspoon](hammerspoon.org/) is for Macbook and [Hammerspoon](hammerspoon.org/) only is for macmini with [AnnePro2](https://www.annepro.net/)
* You must clone or download zip with this repo to `~/projects/dotfiles`. Rename the paths across the code if you want to use a different path
* I use [VSCode](https://code.visualstudio.com/) to maintain the project
* Use `~/projects/dotfiles/hammerspoon/Spoons/Hotkeys.spoon/init.lua` to adjust or at least know almost all hotkeys around
* Run
```bash
sh ./install.sh
```
 to install everything. Check the script to see what it does:

 * homebrew packages installation
 * symlinks
 * terminal setup

Next:
* Replace my name and email in `git/gitconfig` with yours please
* Set CapsLock to do nothing in settings
* Set screenshot shortcuts to another shortcuts (even if they are turned off) for [Flameshot](https://flameshot.org/) could take them

## Features
* The easiest Window management: ctrl + alt + arrow keys
* Great setup for [ZSH](https://www.wikiwand.com/en/Z_shell) with [oh-my-zsh](https://ohmyz.sh/) and [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme
* Autoupdate **Everything** with 'up' command. Run it from Terminal. It cleans cache folders also
* KeyboardPilot alternative: Switch to preferred language on any App focused with the short script. I use English everywhere except for Telegram. Check `hammerspoon/set_language_on_app_focused.lua` for details
* Almost all shortcuts are easy to use and setup with: 'hammerspoon/Spoons/Hotkeys.spoon/init.lua'

## Extra
* [JetBrains Rider](https://www.jetbrains.com/rider/) settings
* Windows legacy dotfiles
