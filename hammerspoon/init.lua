hs.console.clearConsole()
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })

hs.loadSpoon("UnsplashZ") -- download new wallpaper
hs.loadSpoon("Windows") -- window management
hs.loadSpoon("KSheet") -- shortcuts cheatsheet
hs.loadSpoon("PopupTranslateSelection") -- translate selected text
hs.loadSpoon("HotKeys") -- all hotkeys
require "config_UrlDispatcher"; -- open urls in different browsers

hs.pathwatcher.new(hs.configdir, hs.reload):start() -- reload Hammerspoon config on change