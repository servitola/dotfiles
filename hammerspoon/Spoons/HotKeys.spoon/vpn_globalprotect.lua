-- GlobalProtect VPN Toggle Module
-- Provides functionality to toggle GlobalProtect VPN connection via AppleScript
-- and display status notifications

local M = {}

-- Check current VPN connection status
-- Returns: boolean (true if connected, false if disconnected)
local function isConnected()
    local script = [[
        tell application "System Events" to tell process "GlobalProtect"
            click menu bar item 1 of menu bar 2
            delay 0.2
            set buttonName to name of button 2 of window 1
            click menu bar item 1 of menu bar 2
            return buttonName
        end tell
    ]]

    local ok, buttonName = hs.osascript.applescript(script)

    if not ok then
        return nil
    end

    -- Button says "Connect" = currently disconnected
    -- Button says "Disconnect" = currently connected
    return (buttonName == "Disconnect")
end

-- Toggle VPN connection (connect if disconnected, disconnect if connected)
local function toggleConnection()
    local script = [[
        tell application "System Events" to tell process "GlobalProtect"
            click menu bar item 1 of menu bar 2
            delay 0.2
            click button 2 of window 1
            delay 0.2
            click menu bar item 1 of menu bar 2
        end tell
    ]]

    return hs.osascript.applescript(script)
end

-- Show notification with VPN status
local function showNotification(status)
    local statusText = status and "Connected" or "Disconnected"
    hs.notify.new({
        title = "GlobalProtect VPN",
        informativeText = "Status: " .. statusText
    }):send()
end

-- Main toggle function that combines status check, toggle, and notification
function M.toggle()
    -- Check current status
    local wasConnected = isConnected()

    if wasConnected == nil then
        hs.notify.new({
            title = "GlobalProtect VPN",
            informativeText = "Failed to check VPN status"
        }):send()
        return
    end

    -- Toggle connection
    local ok = toggleConnection()

    if ok then
        -- Show new status (opposite of what it was)
        showNotification(not wasConnected)
    else
        hs.notify.new({
            title = "GlobalProtect VPN",
            informativeText = "Failed to toggle"
        }):send()
    end
end

return M
