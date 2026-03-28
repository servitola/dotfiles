local log = hs.logger.new('KeyboardLock', 'info')
local M = {}
local locked = false
local lockTap = nil

local karabinerCli = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"

local function notify(text)
    hs.notify.new({ title = "Keyboard", informativeText = text }):send()
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
        notify("Unlocked")
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
        notify("Locked")
        log.i("Keyboard locked")
    end
end

-- Auto-unlock on wake to prevent stuck keyboard
local sleepWatcher = hs.caffeinate.watcher.new(function(event)
    if locked and (event == hs.caffeinate.watcher.systemDidWake
                or event == hs.caffeinate.watcher.screensDidWake) then
        stopTap()
        notify("Auto-unlocked after wake")
        log.i("Keyboard auto-unlocked after wake")
    end
end)
sleepWatcher:start()

-- Expose as global for hs -c access from Karabiner shell_command
toggleKeyboardLock = M.toggle

return M
