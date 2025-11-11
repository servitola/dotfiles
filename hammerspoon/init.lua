hs.console.clearConsole()
hs.console.darkMode(true)
hs.console.alpha(0.99)
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })
hs.keycodes.setLayout("En Birman")

hs.loadSpoon("GruvboxWallpapers") -- set new wallpaper
hs.loadSpoon("Windows") -- window management
hs.loadSpoon("KSheet") -- shortcuts cheatsheet
hs.loadSpoon("PopupTranslateSelection") -- translate selected text
hs.loadSpoon("YouTrackTicket") -- YouTrack ticket creation
hs.loadSpoon("YouTrackTasks") -- YouTrack tasks view
hs.loadSpoon("BrowserTabOpener") -- YouTube tab opener
hs.loadSpoon("AudioSwitcher") -- audio device switching
hs.loadSpoon("YouTubeStream") -- YouTube stream player
hs.loadSpoon("VoiceDictation") -- voice-to-text typing
hs.loadSpoon("HotKeys") -- all hotkeys

require "config_UrlDispatcher" -- open urls in different browsers
require "set_language_on_app_focused"
require "reload_hammerspoon_on_script_changed"
