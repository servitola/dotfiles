-- Owner's PowerWindows config. The Spoon's catalog covers common apps; this file holds
-- what is specific to this machine.
local browsers = require "browsers"
local telegrams = require "telegrams"

local VIDEO_POPUP = { slot = "corner", keepAspect = true, popup = true }
local SHADOW_TOLERANCE = 4

-- Telegram keeps untitled shadow windows sized like its real windows (they do not follow
-- their position), while a video player has a size of its own.
local function isTelegramShadow(win, info)
    for _, other in ipairs(win:application():allWindows()) do
        if other:id() ~= win:id() and other:title() ~= "" then
            local f = other:frame()
            if math.abs(f.w - info.w) <= SHADOW_TOLERANCE and math.abs(f.h - info.h) <= SHADOW_TOLERANCE then
                return true
            end
        end
    end
    return false
end

return {
    hotkeys = false, -- HotKeys.spoon binds the chords (lint tables, ⌘H, keypad 8)
    wasd = false,
    cycle = true, -- a chord pressed again gives the half / native fullscreen
    macosKeys = false, -- the Globe window keys stay macOS's
    overrides = {
        ["org.m0k.transmission"] = "corner",
    },
    rule = function(win, info)
        -- ScreenGlow and other Spoon canvases are untitled Hammerspoon windows; the
        -- Hammerspoon override (console → side) must not drag them along.
        if info.bundle == "org.hammerspoon.Hammerspoon" and info.title == "" then return false end
        if browsers.by_app(info.app) then
            -- Chromium's extension/side panels come up as untitled standard windows.
            if info.title == "" then return false end
            -- Catches localized player titles too: Vivaldi/Yandex brand every normal window.
            if browsers.is_video_window(info.app, info.title) then return VIDEO_POPUP end
        end
        if telegrams.by_app(info.app) and info.title == "" then
            if isTelegramShadow(win, info) then return false end
            return VIDEO_POPUP
        end
    end,
    focusSets = require "window_focus_sets",
    experimental = {
        placeOnLaunch = {
            bundles = { "com.todesktop.220410vabqjud82", "com.jetbrains.rider" }, -- Moises, Rider
            finderFirstWindow = true,
        },
    },
}
