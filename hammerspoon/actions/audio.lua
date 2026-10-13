local notify = require("notify")

-- The F5 key (the F-row is Karabiner's; it passes f5 through) mutes the default microphone.
-- The state is read from the device every time, so a new default device (AirPods) is never
-- reported wrong. While muted a banner stays on screen (glasswings `persistent`, same id so
-- the unmute rewrites it in place) and a 🎤✕ menu-bar item unmutes on click.
local micBar
local function showMic(device)
    local muted = device:inputMuted()
    if muted then
        micBar = micBar or hs.menubar.new()
        micBar:setTitle("🎤✕")
        micBar:setTooltip("Microphone muted — click or press F5 to unmute")
        micBar:returnToMenuBar()
    elseif micBar then
        micBar:removeFromMenuBar()
    end
    notify.show({
        id = "mic",
        title = muted and "Mic muted" or "Mic live",
        message = device:name() .. (muted and " — F5 to unmute" or ""),
        symbol = muted and "mic.slash.fill" or "mic.fill",
        tint = muted and "red" or "green",
        persistent = muted,
        duration = muted and nil or 1.5,
    })
    return muted
end

local function toggleMic()
    local device = hs.audiodevice.defaultInputDevice()
    if not device then
        notify.show({ title = "Mic", message = "no input device", symbol = "mic.slash", tint = "red", duration = 2 })
        return
    end
    local muted = not device:inputMuted()
    if not device:setInputMuted(muted) then
        notify.show({ title = "Mic", message = device:name() .. " cannot be muted", symbol = "mic.slash", tint = "red", duration = 3 })
        return
    end
    showMic(device)
end

local micWatcher = hs.audiodevice.watcher
micWatcher.setCallback(function(event)
    if event == "dIn " then
        local device = hs.audiodevice.defaultInputDevice()
        if device then showMic(device) end
    end
end)
micWatcher.start()
if micBar then micBar:setClickCallback(toggleMic) end

return function(register)
    register("audio.mic_toggle", function()
        toggleMic()
        if micBar then micBar:setClickCallback(toggleMic) end
    end)
    register("audio.internal", function() spoon.AudioSwitcher:switchToInternal() end)
    register("audio.external", function() spoon.AudioSwitcher:switchToExternal() end)
    register("audio.marshall", function() spoon.AudioSwitcher:switchToMarshall() end)
    register("audio.connect_marshall", function() spoon.AudioSwitcher:connectAndSwitchToMarshall() end)
    register("audio.bt", function() spoon.AudioSwitcher:connectAndSwitchToBT() end)
end
