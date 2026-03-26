-- GlobalProtect VPN Toggle Module
-- Runs AppleScript asynchronously via hs.task to avoid blocking Hammerspoon

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

local function showNotification(title, text)
    hs.notify.new({ title = title, informativeText = text }):send()
end

function M.toggle()
    -- Step 1: check current status (async)
    hs.task.new("/usr/bin/osascript", function(exitCode, stdout, stderr)
        if exitCode ~= 0 then
            showNotification("GlobalProtect VPN", "Failed to check VPN status")
            return
        end

        local wasConnected = (stdout:match("Disconnect") ~= nil)

        -- Step 2: toggle connection (async)
        hs.task.new("/usr/bin/osascript", function(exitCode2)
            if exitCode2 == 0 then
                local statusText = wasConnected and "Disconnected" or "Connected"
                showNotification("GlobalProtect VPN", statusText)
            else
                showNotification("GlobalProtect VPN", "Failed to toggle")
            end
        end, {"-e", toggleScript}):start()
    end, {"-e", checkScript}):start()
end

return M
