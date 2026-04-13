local obj = {}
obj._switching = false
obj._watcher = nil

local log = hs.logger.new('AudioSwitcher', 'info')
local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")

dofile(spoonPath .. "find_audio_device.lua")
dofile(spoonPath .. "switch_to_audio_device_safely.lua")

local BLOCKED_TRANSPORT_TYPES = {
    ["hdmi"]         = true,
    ["displayport"]  = true,
    ["thunderbolt"]  = true,
    ["airplay"]      = true,
}

function obj:switchToExternal()
    switchToAudioDevice("Scarlett")
end

function obj:switchToInternal()
    switchToAudioDevice("MacBook Pro")
end

function obj:switchToMarshall()
    switchToAudioDevice("Marshall")
end

-- Wait for an audio device to appear, checking every second.
local function waitForAudioDevice(deviceName, message, timeoutSecs)
    local device = findAudioDevice(deviceName)
    if device then
        device:setDefaultOutputDevice()
        hs.notify.new({ title = device:name(), informativeText = message or "OK" }):send()
        return
    end

    local elapsed = 0
    local interval = 1
    local timeout = timeoutSecs or 15

    local timer = hs.timer.doUntil(
        function()
            local dev = findAudioDevice(deviceName)
            if dev then
                dev:setDefaultOutputDevice()
                hs.notify.new({ title = dev:name(), informativeText = message or "OK" }):send()
                return true
            end
            elapsed = elapsed + interval
            if elapsed >= timeout then
                hs.notify.new({ title = "⚠️ " .. deviceName .. " not found", informativeText = "timed out after " .. timeout .. "s" }):send()
                return true
            end
            return false
        end,
        interval
    )
end

-- Check if a Bluetooth device is already connected by parsing system_profiler output.
-- This avoids TCC restrictions that crash blueutil when called from Hammerspoon.
local function isBluetoothConnected(mac)
    local output, status = hs.execute("system_profiler SPBluetoothDataType 2>/dev/null")
    if not status or not output then
        return false
    end

    -- Normalize MAC to uppercase for matching
    local normalizedMac = string.gsub(mac, "-", ":"):upper()

    -- Look for the device in the "Connected:" section
    -- We check if the MAC appears after "Connected:" and before "Not Connected:"
    local connectedSection = output:match("Connected:%s*\n(.-)Not Connected:")
    if not connectedSection then
        -- If there's no "Not Connected" section, everything after "Connected:" is connected
        connectedSection = output:match("Connected:%s*\n(.*)")
    end
    if not connectedSection then
        return false
    end

    return connectedSection:upper():find(normalizedMac) ~= nil
end

function obj:connectAndSwitchToMarshall()
    local mac = "24-c4-06-9a-c2-aa"

    if isBluetoothConnected(mac) then
        log.i("Marshall already connected, switching immediately")
        switchToAudioDevice("Marshall", "🔊 Marshall")
        return
    end

    log.i("Marshall not connected, initiating connection")
    hs.execute("open -a /opt/homebrew/bin/blueutil --args --connect " .. mac)
    waitForAudioDevice("Marshall", "🔊 Marshall", 15)
end

function obj:connectAndSwitchToBT()
    local mac = "eb-06-ef-24-61-cf"

    if isBluetoothConnected(mac) then
        log.i("BT already connected, switching immediately")
        switchToAudioDevice("Laptop", "🔊 Audio System")
        return
    end

    log.i("BT not connected, initiating connection")
    hs.execute("open -a /opt/homebrew/bin/blueutil --args --connect " .. mac)
    waitForAudioDevice("Laptop", "🔊 Audio System", 15)
end

function obj:startWatcher()
    self._watcher = hs.audiodevice.watcher.setCallback(function(event)
        if event ~= "dOut" then return end
        if self._switching then return end

        local device = hs.audiodevice.defaultOutputDevice()
        if not device then return end

        local transport = (device:transportType() or ""):lower()
        if not BLOCKED_TRANSPORT_TYPES[transport] then return end

        log.i("HDMI/display audio detected: " .. device:name() .. " (" .. transport .. "), switching to BT")
        hs.notify.new({
            title = "🔇 " .. device:name() .. " blocked",
            informativeText = "Switching to BT speakers",
            withdrawAfter = 5
        }):send()

        self._switching = true
        hs.timer.doAfter(1, function()
            self:connectAndSwitchToBT()
            hs.timer.doAfter(6, function()
                self._switching = false
            end)
        end)
    end)
    hs.audiodevice.watcher.start()
    log.i("Audio device watcher started")
end

function obj:stopWatcher()
    hs.audiodevice.watcher.stop()
    log.i("Audio device watcher stopped")
end

return obj
