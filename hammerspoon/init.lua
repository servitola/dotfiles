hs.console.clearConsole()
hs.console.darkMode(true)
hs.console.alpha(0.99)
hs.ipc.cliInstall()
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })
hs.keycodes.setLayout("En Birman")

require "app_watcher_hub" -- centralized app event dispatcher (must load before spoons)

local function safeLoadSpoon(name)
    local ok, err = pcall(hs.loadSpoon, name)
    if not ok then
        hs.logger.new('init'):e("Failed to load " .. name .. ": " .. tostring(err))
        hs.notify.new({ title = "Hammerspoon", informativeText = "Failed to load " .. name }):send()
    end
end

safeLoadSpoon("GruvboxWallpapers") -- set new wallpaper
safeLoadSpoon("Windows") -- window management
safeLoadSpoon("KSheet") -- shortcuts cheatsheet
safeLoadSpoon("PopupTranslateSelection") -- translate selected text
safeLoadSpoon("YouTrackTicket") -- YouTrack ticket creation
safeLoadSpoon("YouTrackTasks") -- YouTrack tasks view
safeLoadSpoon("BrowserTabOpener") -- find and cycle browser tabs by URL pattern
safeLoadSpoon("AudioSwitcher") -- audio device switching
spoon.AudioSwitcher:startWatcher()
safeLoadSpoon("YouTubeStream") -- YouTube stream player
safeLoadSpoon("URLDispatcher") -- open urls in different browsers
safeLoadSpoon("HotKeys") -- all hotkeys

require "reactive_state"  -- shared state (must load before modules that use it)
require "config_UrlDispatcher"
require "set_language_on_app_focused"
require "punto_switcher"
appUsageAnalytics = require "app_usage_analytics"
require "keyboard_lock"
require "text_expansion"
require "dismiss_fork_dialog"
require "reload_hammerspoon_on_script_changed"
