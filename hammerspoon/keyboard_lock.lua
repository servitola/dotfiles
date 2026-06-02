local log = hs.logger.new('KeyboardLock', 'info')
local banner = require("notify")
local M = {}
local locked = false
local lockTap = nil

local karabinerCli = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

-- Shared banner id — unlock supersedes lock on the same surface instead
-- of stacking two banners. Same for repeated toggles.
local KEYBOARD_BANNER_ID = "keyboard-state"

local function notifyLocked()
    banner.show({
        id          = KEYBOARD_BANNER_ID,
        title       = "Keyboard locked",
        message     = "input blocked",
        symbol      = "keyboard.fill",
        symbolColor = "#ff453a",
        tint        = "red",
        animate     = true,
        duration    = 2,
    })
end

local function notifyUnlocked(autoFromWake)
    banner.show({
        id          = KEYBOARD_BANNER_ID,
        title       = "Keyboard unlocked",
        message     = autoFromWake and "auto-unlocked after wake" or "input restored",
        symbol      = "keyboard",
        symbolColor = "#34c759",
        tint        = "green",
        duration    = 2,
    })
end

local function setKarabinerVar(value)
    hs.execute(string.format("'%s' --set-variables '{\"keyboard_disabled\":%d}'", karabinerCli, value))
end

local function stopTap()
    if lockTap then
        pcall(function() lockTap:stop() end)
        lockTap = nil
    end
    locked = false
    setKarabinerVar(0)
end

function M.toggle()
    if locked then
        stopTap()
        notifyUnlocked(false)
        log.i("Keyboard unlocked")
    else
        lockTap = hs.eventtap.new(
            {
                hs.eventtap.event.types.keyDown,
                hs.eventtap.event.types.keyUp,
                hs.eventtap.event.types.systemDefined,
            },
            function(event)
                return true
            end
        )
        lockTap:start()
        setKarabinerVar(1)
        locked = true
        notifyLocked()
        log.i("Keyboard locked")
    end
end

-- Auto-unlock on wake to prevent stuck keyboard
local sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if locked and (event == hs.caffeinate.watcher.systemDidWake
                or event == hs.caffeinate.watcher.screensDidWake) then
        stopTap()
        notifyUnlocked(true)
        log.i("Keyboard auto-unlocked after wake")
    end
end)
sleepWatcher:start()

-- Expose as global for hs -c access from Karabiner shell_command
toggleKeyboardLock = M.toggle

return M
