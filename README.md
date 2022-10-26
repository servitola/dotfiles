# servitola dotfiles
This is my answer to the question: «How to live with your MacOS?»
I use this config and adjust it on 2 of my macoses: macmini m1 and macbook pro 16 intel since 21.01.2020. I try to sync every single property could be synced.

## CAUTION: I use this config and it works but the installation was not debugged on a new machine.
## And I'm sure it won't work perfectly!
I will be glad if you will find any issues and report them.
## Problems solved FAQ

* Q: I want <ins>all the file types</ins> to be opened with the <ins>proper app</ins> on <ins>double tap</ins> **always**
* A: Look at [Script which sets default apps](https://github.com/servitola/dotfiles/blob/master/macos/set_default_apps.sh). You'll easily understand how to add your file extension. Get your [app's name](https://stackoverflow.com/a/39464824/817396).
#
* Q: I want my <ins>main</ins> English <ins>keyboard layout</ins> turn on <ins>everywhere automatically</ins> except my messenger (I use [Telegram](https://telegram.org/))
* A: This solution of layout switching hell work perfectly. Look at [Hammerspoon script which sets language on application is focused](https://github.com/servitola/dotfiles/blob/master/hammerspoon/set_language_on_app_focused.lua). [Set your messenger](https://stackoverflow.com/a/39464824/817396) and set your layouts. I use `Ilya Birman En and Ru layouts`. There is an app for that: **Keyboard Pilot** but it conflicts with Ilya's layouts
#
* Q: I want to <ins>manipulate my windows</ins> from my keyboard and I want only 4 or less easy positions
* A: The easiest Window management: `ctrl + alt + arrow keys`

     ![Video of my window management](https://i.imgur.com/crdP0bi.gif)
#
* Q: I want my <ins>Terminal to help me</ins> and I know almost nothing
* A: I use [iTerm2](https://iterm2.com/) and I have the greatest setup for [ZSH](https://www.wikiwand.com/en/Z_shell) with [oh-my-zsh](https://ohmyz.sh/) and [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. It helps a lot
![Screenshot of my shell prompt](https://i.imgur.com/8dgnsIb.jpg)
#
* Q: I want to <ins>update all</ins> my applications at once
* A: Autoupdate **Everything** with `up` command. Run `up` from Terminal. It cleans a lot of cache folders also. I have 120 applications and feel no pressure
#
* Q: I want my <ins>work web links</ins> be opened <ins>in Safari</ins> and the other stuff in another browser
* A: Look at `hammerspoon/config_UrlDispatcher.sh`. There are some [RegEx](https://www.wikiwand.com/en/Regular_expression) to identify different types of links. Just set [Hammerspoon](hammerspoon.org/) as your default browser in `System Preferences → General → Default web browser`
#
* Q: I want to <ins>understand</ins> all the <ins>shortcuts</ins> I can use on macos and + with this repository
* A: Almost all shortcuts are easy to use and setup with: `hammerspoon/Spoons/Hotkeys.spoon/init.lua`

1. Caps Lock + key
1. Option + key
1. Shift + Option
1. Shift + key

![Hyper Key Layout](https://i.imgur.com/37uyo3Z.jpg)
#
* Q: I want to control my <ins>environment variables</ins> (Exports)
* A: Look at [Zsh exports.sh](https://github.com/servitola/dotfiles/blob/master/zsh/exports.sh)
#
* Q: I want to have a <ins>firewall</ins> - <ins>free and easy</ins> to use
* A: I use [LuLu](https://objective-see.org/products/lulu.html). Sadly but this repository will download the package only. And you have to install it manually. I will fix it later
#
* Q: I want to <ins>draw any lines</ins> on my <ins>screenshots</ins>. I do screenshots for work
* A: I use [FlameShot](https://flameshot.org/). It is installed with all the programs with homebrew here
#
* Q: I want to <ins>download a video</ins> from <ins>YouTube</ins> or <ins>RuTube</ins>:
* A: I use [yt-dlp](https://github.com/yt-dlp/yt-dlp). Just use **yt-dlp** command with any link from . For example:
```
yt-dlp https://www.youtube.com/watch?v=QhROKjpuLMM
yt-dlp https://www.youtube.com/user/ButKorn/videos
```
#
* Q: I want to <ins>hide comments</ins> and <ins>speed up video</ins> on <ins>YouTube</ins>:
* A: I use [YouTube Enhancer](https://addons.mozilla.org/en-US/firefox/addon/enhancer-for-youtube/). Import my settings from [here](https://github.com/servitola/dotfiles/tree/master/youtube-enhancer)
#
* Q: I want to find out what takes the space on my hard drive
* A: I use [baobab](https://wiki.gnome.org/action/show/Apps/DiskUsageAnalyzer?action=show&redirect=Apps%2FBaobab)
Just type `baobab` in Terminal/iTerm2
#
* Q: How to <ins>install</ins> this repository?
* A: run ```cd ~/projects/dotfiles chmod +x install.sh ./install.sh``` in Terminal
#
* Q: But <ins>where to download</ins> at first?
* A: You must clone or download zip with this repo to `~/projects/dotfiles`. Rename the paths across the code if you want to use a different path
```bash
mkdir ~/projects
cd ~/projects
git clone https::github.com/servitola/dotfiles.git
```
install command tools will be asked to install - agree
#
* Q: What is the best way to <ins>maintain this project</ins>?
* A: I use [VSCode](https://code.visualstudio.com/). On open the project's folder you will be suggested all the necessary plugins to install. As for git I use [PreCommit](https://pre-commit.com/) to check that my commits don't have extra spaces and secrets
#
* Q: What <ins>important</ins> to do after?
* A: Do next:
* Replace my name and email in [GitConfig](https://github.com/servitola/dotfiles/blob/master/git/gitconfig) with yours please
* Set CapsLock to do nothing in macos settings
* Set screenshot shortcuts to another shortcuts (even if they are turned off) for [Flameshot](https://flameshot.org/) could take them
#
* Q: I want to understand what this repository installs exactly
* A: check the [Install.sh](https://github.com/servitola/dotfiles/blob/master/install.sh) script . It installs all the programs (with homebrew mostly), creates symlinks, does the rest
#
* Q: How to log in Hammerspoon to Hammespoon's console faster?
* A: in hammespoon's lua file write down:
```print "log message"```
#
## Extra
* [JetBrains Rider](https://www.jetbrains.com/rider/) settings
* AnnePro2 Qmk config with light scheme

## Details:
* [Karabiner](https://karabiner-elements.pqrs.org/) mimics my [AnnePro2](https://www.annepro.net/) layout. [Hammerspoon](hammerspoon.org/) does the rest. So [Karabiner](https://karabiner-elements.pqrs.org/) + [Hammerspoon](hammerspoon.org/) is for Macbook and [Hammerspoon](hammerspoon.org/) only is for macmini with [AnnePro2](https://www.annepro.net/)
