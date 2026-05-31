local obj = {}
obj._switching = false
obj._watcher = nil

local log = hs.logger.new('AudioSwitcher', 'info')
local notify = require("notify")
local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")

dofile(spoonPath .. "find_audio_device.lua")
dofile(spoonPath .. "switch_to_audio_device_safely.lua")

local BLOCKED_TRANSPORT_TYPES = {
    ["hdmi"]         = true,
    ["displayport"]  = true,
    ["thunderbolt"]  = true,
    ["airplay"]      = true,
}

-- Per-device presentation: friendly title + subtitle, SF Symbol, accent.
-- Tech device names (BE-RCA, MacBook Pro Speakers, Marshall BT) live in
-- the AudioSwitcher matching layer; the user never sees them in banners.
-- The symbol pulses via SwiftUI's variableColor effect (sound emanating).
local PRESETS = {
    internal = {
        title = "Laptop",
        subtitle = "built-in speakers",
        symbol = "laptopcomputer",
        symbolColor = "#5856d6",
        tint = "indigo",
    },
    external = {
        title = "Scarlett",
        subtitle = "audio interface",
        symbol = "music.mic",
        symbolColor = "#ff9500",
        tint = "orange",
    },
    marshall = {
        title = "Marshall",
        subtitle = "bluetooth speaker",
        symbol = "hifispeaker.fill",
        symbolColor = "#ff453a",
        tint = "red",
    },
    berca = {
        title = "Living room",
        subtitle = "floor speakers",
        symbol = "hifispeaker.2.fill",
        symbolColor = "#34c759",
        tint = "green",
    },
}

function obj:switchToExternal()
    switchToAudioDevicePreset("Scarlett", PRESETS.external)
end

function obj:switchToInternal()
    switchToAudioDevicePreset("MacBook Pro", PRESETS.internal)
end

function obj:switchToMarshall()
    switchToAudioDevicePreset("Marshall BT", PRESETS.marshall)
end

-- Wait for an audio device to appear, checking every second.
-- Preset variant — banner uses the per-device symbol/title/color.
local function waitForAudioDevicePreset(deviceName, preset, timeoutSecs)
    local function announceSuccess(_dev)
        notify.show({
            title       = preset.title,
            message     = preset.subtitle,
            symbol      = preset.symbol,
            symbolColor = preset.symbolColor,
            tint        = preset.tint,
            animate     = true,
            duration    = 2,
        })
    end

    local device = findAudioDevice(deviceName)
    if device then
        device:setDefaultOutputDevice()
        announceSuccess(device)
        return
    end

    local elapsed = 0
    local interval = 1
    local timeout = timeoutSecs or 15
    local timer

    timer = hs.timer.doEvery(interval, function()
        local dev = findAudioDevice(deviceName)
        if dev then
            dev:setDefaultOutputDevice()
            announceSuccess(dev)
            timer:stop()
            return
        end
        elapsed = elapsed + interval
        if elapsed >= timeout then
            notify.show({
                title    = "⚠️ " .. preset.title .. " not found",
                message  = "timed out after " .. timeout .. "s",
                tint     = "red",
                duration = 5,
            })
            timer:stop()
        end
    end)
end

local function isBluetoothConnected(mac)
    local output = hs.execute("/opt/homebrew/bin/blueutil --is-connected " .. mac)
    return output and output:match("^%s*1") ~= nil
end

-- Non-blocking BT connect: returns immediately, blueutil runs in background.
local function connectBluetoothAsync(mac)
    hs.task.new("/opt/homebrew/bin/blueutil", nil, {"--connect", mac}):start()
end

function obj:connectAndSwitchToMarshall()
    local mac = "24-c4-06-9a-c2-aa"

    if isBluetoothConnected(mac) then
        log.i("Marshall already connected, switching immediately")
        switchToAudioDevicePreset("Marshall BT", PRESETS.marshall)
        return
    end

    log.i("Marshall not connected, initiating connection")
    connectBluetoothAsync(mac)
    waitForAudioDevicePreset("Marshall BT", PRESETS.marshall, 15)
end

function obj:connectAndSwitchToBT()
    local mac = "eb-06-ef-24-61-cf"

    if isBluetoothConnected(mac) then
        log.i("BT already connected, switching immediately")
        switchToAudioDevicePreset("BE-RCA", PRESETS.berca)
        return
    end

    log.i("BT not connected, initiating connection")
    connectBluetoothAsync(mac)
    waitForAudioDevicePreset("BE-RCA", PRESETS.berca, 15)
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
        notify.show({
            title    = "🔇 " .. device:name() .. " blocked",
            message  = "Switching to BT speakers",
            tint     = "orange",
            duration = 4,
        })

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
