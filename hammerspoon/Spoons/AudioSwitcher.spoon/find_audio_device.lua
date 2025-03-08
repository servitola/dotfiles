function findAudioDevice(pattern)

    local devices = hs
            .audiodevice
            .allOutputDevices()

    for _, device in ipairs(devices) do
        if string.find(
                device:name():lower(),
                pattern:lower())
            then return device
        end
    end

    return nil
end
