hs.console.clearConsole()
hs.console.darkMode(true)
hs.console.alpha(0.99)
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })
hs.keycodes.setLayout("English - Ilya Birman Typography")
hs.application.enableSpotlightForNameSearches(true)

hs.loadSpoon("GruvboxWallpapers") -- set new wallpaper
hs.loadSpoon("Windows") -- window management
hs.loadSpoon("KSheet") -- shortcuts cheatsheet
hs.loadSpoon("PopupTranslateSelection") -- translate selected text
hs.loadSpoon("YouTrackTicket") -- YouTrack ticket creation
hs.loadSpoon("YouTrackTasks") -- YouTrack tasks view
hs.loadSpoon("BrowserTabOpener") -- YouTube tab opener
--hs.loadSpoon("AudioSwitcher") -- audio device switching
hs.loadSpoon("HotKeys") -- all hotkeys

require "config_UrlDispatcher"; -- open urls in different browsers
require "set_language_on_app_focused";
require "reload_hammerspoon_on_script_changed"

local systemMonitor = require "system_monitor"
systemMonitor.start()

hs.timer.doAfter(1, function()
    if systemMonitor and systemMonitor.showMemoryNotification then
        systemMonitor.showMemoryNotification()
    end
end)
