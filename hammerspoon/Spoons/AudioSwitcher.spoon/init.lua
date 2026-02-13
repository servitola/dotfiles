local obj = {}

dofile("./Spoons/AudioSwitcher.spoon/find_audio_device.lua")
dofile("./Spoons/AudioSwitcher.spoon/switch_to_audio_device_safely.lua")

function obj:switchToExternal()
    switchToAudioDevice("Scarlett")
end

function obj:switchToInternal()
    switchToAudioDevice("MacBook Pro")
end

function obj:switchToMarshall()
    switchToAudioDevice("Marshall")
end

function obj:connectAndSwitchToMarshall()
    local mac = "24-c4-06-9a-c2-aa"
    -- blueutil crashes (SIGABRT) when run as Hammerspoon child process due to
    -- macOS TCC Bluetooth restrictions. Using "open -a" launches it as a
    -- standalone process with its own Bluetooth entitlements.
    hs.execute("open -a /opt/homebrew/bin/blueutil --args --connect " .. mac)
    hs.timer.doAfter(5, function()
        switchToAudioDevice("Marshall")
    end)
end

function obj:switchToBT()
    switchToAudioDevice("BT")
end

return obj
