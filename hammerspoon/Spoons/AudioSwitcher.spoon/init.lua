local obj = {}
obj.__index = obj
obj.name = "AudioSwitcher"
obj.version = "1.0"
obj.author = "servitola"

function obj:listDevices()
    local devices = hs.audiodevice.allOutputDevices()
    local deviceList = ""
    for _, device in ipairs(devices) do
        deviceList = deviceList .. "- " .. device:name() .. "\n"
    end

    print("Available Audio Devices:")
    print(deviceList)
end

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
    self:listDevices()

    local device = self:findAudioDevice("Scarlett")
    if device then
        device:setDefaultOutputDevice()
    end
end

function obj:switchToInternal()
    self:listDevices()

    local device = self:findAudioDevice("MacBook Pro") -- Internal MacBook speakers
    if device then
        device:setDefaultOutputDevice()
    end
end

function obj:switchToMarshall()
    self:listDevices()

    local device = self:findAudioDevice("Marshall")
    if device then
        device:setDefaultOutputDevice()
        hs.alert.show("🎧 Switched to Marshall")
    else
        hs.alert.show("❌ Marshall headphones not found")
    end
end

return obj
