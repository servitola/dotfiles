# servitola dotfiles
This is my answer how to live with your macos. I use it and adjust it every day on 2 of my macoses: macmini m1 and macbook pro 16 intel. I try to sync every single property could be synced.
## Problems solved FAQ

* Q: I want all the file types be opened with the proper app on double tap **always**
* A: Look at `macos/set_default_apps.sh`. You'll easily understand how to add your file extension. Get your [app's name](https://stackoverflow.com/a/39464824/817396).
#
* Q: I want my main English (or another) keyboard layout turn on everywhere automatically except my messenger (I use Telegram)
* A: This solution of layout switching hell work perfectly. Look at `hammerspoon/set_language_on_app_focused`. [Set your messenger](https://stackoverflow.com/a/39464824/817396) and set your layouts. I use `Ilya Birman En and Ru layouts`. There is an app for that: **Keyboard Pilot** but it conflicts with Ilya's layouts
#
* Q: I want to manipulate my windows from my keyboard and I want only 4 or less easy positions
* A: The easiest Window management: `ctrl + alt + arrow keys`

     ![Video of my window management](https://i.imgur.com/crdP0bi.gif)
#
* Q: I want my Terminal helps me a lot and I know almost nothing
* A: I use iTerm2 and I have the greatest setup for [ZSH](https://www.wikiwand.com/en/Z_shell) with [oh-my-zsh](https://ohmyz.sh/) and [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. It helps a lot
![Screenshot of my shell prompt](https://i.imgur.com/8dgnsIb.jpg)
#
* Q: I want to update all my applications at once
* A: Autoupdate **Everything** with `up` command. Run `up` from Terminal. It cleans a lot of cache folders also. I have 120 applications and feel no pressure
#
* Q: I want to understand all the shortcuts I can use on macos and + with this repository
* A: Almost all shortcuts are easy to use and setup with: `hammerspoon/Spoons/Hotkeys.spoon/init.lua`

![Hyper Key Layout](https://i.imgur.com/4RAIU84.jpg)
#
* Q: How to install this repository?
* A: run ```sh ./install.sh``` in Terminal
#
* Q: But where to download at first?
* A: You must clone or download zip with this repo to `~/projects/dotfiles`. Rename the paths across the code if you want to use a different path
#
* Q: What is the best way to maintain this project?
* A: I use [VSCode](https://code.visualstudio.com/). On open the project's folder it will suggest all the needed plugins to install
#
* Q: What important to do after?
* A: Do next:
* Replace my name and email in `git/gitconfig` with yours please
* Set CapsLock to do nothing in macos settings
* Set screenshot shortcuts to another shortcuts (even if they are turned off) for [Flameshot](https://flameshot.org/) could take them
## Extra
* [JetBrains Rider](https://www.jetbrains.com/rider/) settings

## Details:
* [Karabiner](https://karabiner-elements.pqrs.org/) mimics my [AnnePro2](https://www.annepro.net/) layout. [Hammerspoon](hammerspoon.org/) does the rest. So [Karabiner](https://karabiner-elements.pqrs.org/) + [Hammerspoon](hammerspoon.org/) is for Macbook and [Hammerspoon](hammerspoon.org/) only is for macmini with [AnnePro2](https://www.annepro.net/)
