local obj = {}
obj.__index = obj
obj.name = "AudioSwitcher"
obj.version = "1.0"
obj.author = "servitola"


function obj:findAudioDevice(pattern)
    local devices = hs.audiodevice.allOutputDevices()
    for _, device in ipairs(devices) do
        if string.find(device:name():lower(), pattern:lower()) then
            return device
        end
    end
    return nil
end

function obj:switchToExternal()
    local device = self:findAudioDevice("Scarlett")
    if device then
        device:setDefaultOutputDevice()
    end
end

function obj:switchToInternal()
    local device = self:findAudioDevice("MacBook Pro")
    if device then
        device:setDefaultOutputDevice()
    end
end

function obj:switchToMarshall()
    local device = self:findAudioDevice("Marshall")
    if device then
        device:setDefaultOutputDevice()
    end
end

function obj:switchToBT()
    local device = self:findAudioDevice("BT")
    if device then
        device:setDefaultOutputDevice()
    end
end

return obj
