function findAudioDevice(pattern)

    local devices = hs
            .audiodevice
            .allOutputDevices()

    for _, device in ipairs(devices) do
        local name = device:name()
        if name and string.find(name:lower(), pattern:lower()) then
            return device
        end
    end

    return nil
end
