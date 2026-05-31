-- GlobalProtect VPN Toggle Module
-- Runs AppleScript asynchronously via hs.task to avoid blocking Hammerspoon

local notify = require("notify")

local M = {}

local checkScript = [[
tell application "System Events" to tell process "GlobalProtect"
    click menu bar item 1 of menu bar 2
    delay 0.2
    set buttonName to name of button 2 of window 1
    click menu bar item 1 of menu bar 2
    return buttonName
end tell
]]

local toggleScript = [[
tell application "System Events" to tell process "GlobalProtect"
    click menu bar item 1 of menu bar 2
    delay 0.2
    click button 2 of window 1
    delay 0.2
    click menu bar item 1 of menu bar 2
end tell
]]

local function vpnConnected()
    notify.show({
        title       = "VPN connected",
        message     = "GlobalProtect",
        symbol      = "lock.shield.fill",
        symbolColor = "#34c759",
        tint        = "green",
        animate     = true,
        duration    = 2,
    })
end

local function vpnDisconnected()
    notify.show({
        title       = "VPN off",
        message     = "GlobalProtect",
        symbol      = "lock.open.fill",
        symbolColor = "#8e8e93",
        tint        = "gray",
        duration    = 2,
    })
end

local function vpnError(text)
    notify.show({
        title    = "VPN error",
        message  = text,
        symbol   = "exclamationmark.shield.fill",
        tint     = "red",
        duration = 5,
    })
end

function M.toggle()
    -- Step 1: check current status (async)
    hs.task.new("/usr/bin/osascript", function(exitCode, stdout, stderr)
        if exitCode ~= 0 then
            vpnError("failed to check status")
            return
        end

        local wasConnected = (stdout:match("Disconnect") ~= nil)

        -- Step 2: toggle connection (async)
        hs.task.new("/usr/bin/osascript", function(exitCode2)
            if exitCode2 == 0 then
                if wasConnected then
                    vpnDisconnected()
                else
                    vpnConnected()
                end
            else
                vpnError("toggle failed")
            end
        end, {"-e", toggleScript}):start()
    end, {"-e", checkScript}):start()
end

return M
