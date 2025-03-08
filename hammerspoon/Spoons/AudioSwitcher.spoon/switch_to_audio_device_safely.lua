function switchToAudioDevice(deviceName)
    local device = findAudioDevice(deviceName)
    if device then
        device:setDefaultOutputDevice()
    end
end
