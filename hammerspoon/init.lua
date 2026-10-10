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
if hs.fs.attributes(hs.configdir .. "/Spoons/GlobalProtectToggle.spoon") then
    safeLoadSpoon("GlobalProtectToggle") -- GlobalProtect VPN on a key, github.com/servitola/GlobalProtectToggle.spoon
end
safeLoadSpoon("BrowserTabOpener") -- jump to a site's open tab, cycle, or open it, github.com/servitola/BrowserTabOpener.spoon
spoon.BrowserTabOpener.browser = constants.APP_BROWSER_BUNDLE
safeLoadSpoon("AudioSwitcher") -- audio device switching
safeLoadSpoon("YouTubeStream") -- YouTube stream player
if hs.fs.attributes(hs.configdir .. "/Spoons/LinkRouter.spoon") then
    safeLoadSpoon("LinkRouter") -- each clicked link to the browser its rule names, github.com/servitola/LinkRouter.spoon
end
safeLoadSpoon("HotKeys") -- all hotkeys
safeLoadSpoon("VoiceCtl") -- voice-driven mac control (see detached skill voice-mac)
safeLoadSpoon("ScreenGlow") -- edge glow while an agent drives the desktop, github.com/servitola/ScreenGlow.spoon
if spoon.HotKeys then
    local ok, err = pcall(require, "actions")  -- personal actions register into spoon.HotKeys
    if not ok then
        hs.logger.new('init'):e("actions: " .. tostring(err))
        notify.show({
            title    = "actions failed",
            message  = tostring(err):sub(1, 80),
            symbol   = "exclamationmark.triangle.fill",
            tint     = "red",
            duration = 8,
        })
    end
    spoon.HotKeys:start()  -- binds chords; must follow every register()
end

require "reactive_state"  -- shared state (must load before modules that use it)
require "link_router"

safeLoadSpoon("AutoKeyboardLayout") -- a layout per app
spoon.AutoKeyboardLayout.primary = constants.LAYOUT_PRIMARY
spoon.AutoKeyboardLayout.secondary = constants.LAYOUT_SECONDARY
spoon.AutoKeyboardLayout:start()

require "game_mode"
require "punto_switcher"
appUsageAnalytics = require "app_usage_analytics"
require "input_logger"
require "keyboard_lock"
require "wifi_watcher"
require "text_expansion"
require "dismiss_fork_dialog"
require "reload_hammerspoon_on_script_changed"

hs.loadSpoon("BirmanLayer")
local layer = spoon.BirmanLayer
layer.excludedBundles = {}
for bundle in pairs(require("game_mode").bundles) do
    table.insert(layer.excludedBundles, bundle)
end
layer.baseFixups = true
layer.excludedLayouts = { "com.apple.keylayout.Greek" } -- Apple's own Greek ⌥ layer: accented letters (ά έ ή), Greek symbols
layer:start()
