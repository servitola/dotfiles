function switchToAudioDevice(deviceName, message)
    local device = findAudioDevice(deviceName)

    if device then
        device:setDefaultOutputDevice()
        hs.notify.new({ title = device:name(), informativeText = "OK" }):send()
    else
        hs.notify.new({ title = "⚠️ " .. deviceName .. " not found", informativeText = "warning" }):send()
    end
end
