hs.console.clearConsole()
hs.console.darkMode(true)
hs.console.alpha(0.99)
hs.ipc.cliInstall()
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })
local constants = require "constants"
hs.keycodes.setLayout(constants.LAYOUT_PRIMARY)

require "app_watcher_hub" -- centralized app event dispatcher (must load before spoons)
local notify = require "notify"

local function safeLoadSpoon(name)
    local ok, err = pcall(hs.loadSpoon, name)
    if not ok then
        hs.logger.new('init'):e("Failed to load " .. name .. ": " .. tostring(err))
        notify.show({
            title    = "Spoon failed",
            message  = name .. " — " .. tostring(err):sub(1, 80),
            symbol   = "exclamationmark.triangle.fill",
            tint     = "red",
            duration = 8,
        })
    end
end

safeLoadSpoon("Fresh4kWallpaper") -- new wallpaper on every load
spoon.Fresh4kWallpaper:start()
safeLoadSpoon("PowerWindows") -- window layout
spoon.PowerWindows:configure(require "window_rules"):start()

safeLoadSpoon("KSheet") -- shortcuts cheatsheet
safeLoadSpoon("PopupTranslateSelection") -- translate selected text
safeLoadSpoon("YouTrackTicket") -- YouTrack ticket creation
safeLoadSpoon("YouTrackTasks") -- YouTrack tasks view
safeLoadSpoon("BrowserTabOpener") -- find and cycle browser tabs by URL pattern
safeLoadSpoon("AudioSwitcher") -- audio device switching
safeLoadSpoon("YouTubeStream") -- YouTube stream player
safeLoadSpoon("URLDispatcher") -- open urls in different browsers
safeLoadSpoon("HotKeys") -- all hotkeys
safeLoadSpoon("ScreenGlow") -- edge glow while an agent drives the desktop (hs -c 'spoon.ScreenGlow:pulse(45)')

require "reactive_state"  -- shared state (must load before modules that use it)
require "config_UrlDispatcher"
require "set_language_on_app_focused"

safeLoadSpoon("AutoKeyboardLayout") -- a layout per app
spoon.AutoKeyboardLayout.primary = constants.LAYOUT_PRIMARY
spoon.AutoKeyboardLayout.secondary = constants.LAYOUT_SECONDARY
spoon.AutoKeyboardLayout:start()

require "punto_switcher"
appUsageAnalytics = require "app_usage_analytics"
require "input_logger"
require "keyboard_lock"
require "wifi_watcher"
require "text_expansion"
require "dismiss_fork_dialog"
require "reload_hammerspoon_on_script_changed"
