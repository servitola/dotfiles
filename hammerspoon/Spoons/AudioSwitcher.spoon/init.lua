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

function obj:switchToBT()
    switchToAudioDevice("BT")
end

return obj
