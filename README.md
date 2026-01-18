# servitola dotfiles
This is my answer to the question: "How to live with your MacOS?"
I use this configuration and adjust it on 3 of my Macs: Mac Studio M1Pro, MacBook Pro 16 M3Pro, MacBook Pro 16 i9 2019 since January 21, 2020. I try to sync every single property that can be synced.

## CAUTION: I use this configuration, and it works, but the installation was not debugged on a new machine. Also I have some specific details which can't fit others surely. They are described in the end of this readme.
## I will be glad if you find any issues and report them.
## Problems solved FAQ

* Q: I want <ins>all file types</ins> to be opened with the <ins>proper app</ins> on <ins>double tap</ins> **always**
* A: Look at the [Script which sets default apps](https://github.com/servitola/dotfiles/blob/master/macos/set_default_apps.sh) which uses [duti](https://github.com/moretension/duti). You'll easily understand how to add your file extension. Get your [app's name](https://stackoverflow.com/a/39464824/817396).

* Q: I want my <ins>main</ins> English <ins>keyboard layout</ins> to turn on <ins>automatically everywhere</ins> except in my messenger (I use [Telegram](https://telegram.org/))
* A: This solution for layout switching works perfectly. Look at the [Hammerspoon script which sets language when application is focused](https://github.com/servitola/dotfiles/blob/master/hammerspoon/set_language_on_app_focused.lua). [Set up your messenger](https://stackoverflow.com/a/39464824/817396) and set your layouts. I use `Ilya Birman En and Ru layouts`. There is an app for the switching: **Keyboard Pilot** but it conflicts with Ilya's layouts.

* Q: I want to <ins>manipulate my windows</ins> from my keyboard and I want only 4 or fewer easy positions
* A: The easiest window management: `ctrl + alt + arrow keys`

     ![Video of my window management](https://i.imgur.com/crdP0bi.gif)

* Q: I want my <ins>Terminal to assist me</ins> and I know almost nothing
* A: I use [Warp](https://app.warp.dev/referral/495XNY) and I have the best setup for [ZSH](https://www.wikiwand.com/en/Z_shell) with [oh-my-zsh](https://ohmyz.sh/) and [powerlevel10k](https://github.com/romkatv/powerlevel10k) theme. It is very helpful.

* Q: I want to <ins>search my entire command history</ins> instantly with <ins>fuzzy search</ins> and <ins>sync across machines</ins>
* A: I use [Atuin](https://atuin.sh/). It replaces your shell history with a SQLite database. Press `Ctrl-R` for fuzzy search through all your commands. Up arrow searches your current directory. It syncs encrypted across machines.

* Q: I want to <ins>update all</ins> my applications at once
* A: Autoupdate **Everything** with the `up` command. Run `up` from Terminal. It also cleans a lot of cache folders. I have 200+ applications and feel no pressure.

* Q: I want my <ins>work web links</ins> to be opened <ins>in Safari</ins> and the <ins>other stuff</ins> in <ins>another browser</ins>
* A: Look at `hammerspoon/config_UrlDispatcher.sh`. There are some [RegEx](https://www.wikiwand.com/en/Regular_expression) to identify different types of links. Just set [Hammerspoon](hammerspoon.org/) as your default browser in `System Preferences → General → Default web browser`.

* Q: I want to <ins>understand</ins> all the <ins>shortcuts</ins> I can use on macOS and <ins>with this repository</ins>
* A: Almost all shortcuts are easy to use and set up with: `hammerspoon/Spoons/Hotkeys.spoon/init.lua`

1. Caps Lock + key
1. Option + key
1. Shift + Option
1. Shift + key

OBSOLETED IMAGE!!! CHECK THE FILE `hammerspoon/Spoons/Hotkeys.spoon/init.lua`
![Hyper Key Layout](https://i.imgur.com/37uyo3Z.jpg)

* Q: I want to control my <ins>environment variables</ins> (Exports)
* A: Look at [Zsh exports.sh](https://github.com/servitola/dotfiles/blob/master/zsh/exports.sh)

* Q: I want to have a <ins>firewall</ins> - <ins>free and easy</ins> to use
* A: I use [LuLu](https://objective-see.org/products/lulu.html)

* Q: I want to <ins>draw lines</ins> on my <ins>screenshots</ins>. I take screenshots for work
* A: I use [Shottr](https://shottr.cc/). It is installed with all programs using homebrew here. Check out its [Tips & Tricks](https://shottr.cc/#section-tips/). They are really helpful.

* Q: I use an <ins>external audiocard</ins> and I want to control its <ins>volume in a standard way</ins> and use an equalizer depending on the device
* A: I use [eqmac](https://eqmac.app/). It is installed with all programs using homebrew here.

* Q: I use Spotlight, but it's not as powerful as I want. I want to calculate numbers, use AI, search Google
* A: I use [raycast](https://www.raycast.com/). It is installed with all programs using homebrew here. Check out its extensions

* Q: I want to save my global NPM packages list and install/update them
* A: Check the [npm-list](https://github.com/servitola/dotfiles/blob/master/npm/global-packages.txt) list of global packages I install with [script](https://github.com/servitola/dotfiles/blob/master/npm/install-globals.sh)

* Q: I want to save my global Python packages list and install/update them
* A: Check the [pythong-list](https://github.com/servitola/dotfiles/blob/master/python/global-packages.txt) list of global packages I install with [script](https://github.com/servitola/dotfiles/blob/master/python/install-globals.sh)

* Q: I want to convert audio file to text
* A: I use [whisper-x](https://github.com/m-bain/whisperX). I use CPU conversion. I use alias 'w' for 'whisperx' with biggest model

Convert with best quality:
```
w ~/test.mp3
```

* Q: I want to <ins>download a video</ins> from <ins>YouTube</ins> or <ins>RuTube</ins>:
* A: I use [yt-dlp](https://github.com/yt-dlp/yt-dlp). Just use the **yt-dlp** command with any link. For example:
```
yt-dlp https://www.youtube.com/watch?v=QhROKjpuLMM
yt-dlp https://www.youtube.com/user/ButKorn/videos
```
* Q: I want to <ins>download a mp3</ins> from <ins>YouTube</ins> or <ins>RuTube</ins>:
* A: Same yt-dlp usage. Try my aliases in zsh to do so.

Audio as .mp3 and save to Desktop:
```
yta https://www.youtube.com/watch?v=i6JjquwFNU4
```
Video as .mp4 and save to Desktop:
```
ytv https://www.youtube.com/watch?v=8ApNlMcNEY0
```
* Q: I want to <ins>hide comments</ins> and <ins>speed up videos</ins> on <ins>YouTube</ins>. And also 1000 of options. You're surely find yours:
* A: I use [Improve YouTube](https://chromewebstore.google.com/detail/improve-youtube-%F0%9F%8E%A7-for-yo/bnomihfieiccainjcjblhegjgglakjdd). Install it and import my settings from [here](https://github.com/servitola/dotfiles/tree/master/chromium-ImprovedTube-extension)

* Q: I want to have multiple buffers and not switch between windows multiple times. I want to <ins>copy</ins> and <ins>paste</ins> <ins>multiple</ins> things at once.
* A: I use [maccy](https://maccy.app/). It is installed with all programs using homebrew here.

* Q: I want to find out what is taking up space on my hard drive
* A: I use [baobab](https://wiki.gnome.org/action/show/Apps/DiskUsageAnalyzer?action=show&redirect=Apps%2FBaobab). Just type `baobab` in Terminal/iTerm2.

* Q: How to <ins>install</ins> this repository?
* A: With regular Makefile. Run ```cd ~/projects/dotfiles && make``` in Terminal.

* Q: But <ins>where to download</ins> in the first place?
* A: You must clone or download the zip file of this repo to `~/projects/dotfiles`. Rename the paths across the code if you want to use a different path.
```bash
mkdir ~/projects
cd ~/projects
git clone https://github.com/servitola/dotfiles.git
```
You will be asked to install command tools - agree.

* Q: What is the best way to <ins>maintain this project</ins>?
* A: I use [VSCode](https://code.visualstudio.com/). When you open the project's folder, you will be suggested all the necessary plugins to install. For git, I use [PreCommit](https://pre-commit.com/) to check that my commits don't have extra spaces and secrets.

* Q: What is <ins>important</ins> to do next?
* A: Next, do the following:
  * Replace my name and email in [GitConfig](https://github.com/servitola/dotfiles/blob/master/git/gitconfig) with yours. Also remove all 'proxy' lines from there since they are specific for my work.
  * Remove proxy from [ClaudeConfig](https://github.com/servitola/dotfiles/blob/master/claude-code/settings.json). They are specific for my work
  * Set screenshot shortcuts to other shortcuts (even if they are turned off) so that [Shottr](https://shottr.cc/) can take them.

* Q: I want to understand what this repository installs exactly
* A: Check the [Makefile](https://github.com/servitola/dotfiles/blob/master/Makefile) script. It installs all the programs (mostly with homebrew), deletes configs at default places, creates symlinks, and completes the setup.

#
## Extra:
* [JetBrains Rider](https://www.jetbrains.com/rider/) settings
* AnnePro2 ObinsKit config with light scheme
