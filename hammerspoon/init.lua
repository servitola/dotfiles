hs.console.clearConsole()
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })
hs.keycodes.setLayout("English - Ilya Birman Typography")
hs.application.enableSpotlightForNameSearches(true)

--hs.loadSpoon("UnsplashZ") -- download new wallpaper
hs.loadSpoon("Windows") -- window management
hs.loadSpoon("KSheet") -- shortcuts cheatsheet
hs.loadSpoon("PopupTranslateSelection") -- translate selected text
hs.loadSpoon("HotKeys") -- all hotkeys
require "config_UrlDispatcher"; -- open urls in different browsers
require "set_language_on_app_focused";
require "reload_hammerspoon_on_script_changed"
