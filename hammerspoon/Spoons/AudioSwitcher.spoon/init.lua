local obj = {}
obj.__index = obj
obj.name = "AudioSwitcher"
obj.version = "1.0"
obj.author = "servitola"

-- Load Notification spoon
local notification = hs.loadSpoon("Notification")

-- Device icons with modern style
local deviceIcons = {
    ["Scarlett"] = "🎛️",
    ["MacBook Pro"] = "🖥️",
    ["Marshall"] = "🎧"
}

function obj:findAudioDevice(pattern)
    local devices = hs.audiodevice.allOutputDevices()
    for _, device in ipairs(devices) do
        if string.find(device:name():lower(), pattern:lower()) then
            return device
        end
    end
    return nil
end

function obj:findNextDevice()
    local current = hs.audiodevice.defaultOutputDevice()
    if not current then return nil end

    local devices = hs.audiodevice.allOutputDevices()
    for i, device in ipairs(devices) do
        if device:uid() == current:uid() then
            -- Return next device, or first if we're at the end
            return devices[i + 1] or devices[1]
        end
    end
    return nil
end

function obj:switchAudioDevice()
    local nextDevice = self:findNextDevice()
    if nextDevice then
        nextDevice:setDefaultOutputDevice()
        self:showDeviceNotification(nextDevice:name())
    end
end

function obj:switchToExternal()
    local device = self:findAudioDevice("Scarlett")
    if device then
        device:setDefaultOutputDevice()
        self:showDeviceNotification(device:name())
    end
end

function obj:switchToInternal()
    local device = self:findAudioDevice("MacBook Pro")
    if device then
        device:setDefaultOutputDevice()
        self:showDeviceNotification(device:name())
    end
end

function obj:switchToMarshall()
    local device = self:findAudioDevice("Marshall")
    if device then
        device:setDefaultOutputDevice()
        self:showDeviceNotification(device:name())
    else
        notification.show("❌  Marshall headphones not found")
    end
end

function obj:showDeviceNotification(deviceName)
    -- Find matching icon or use default
    local icon = "🔈"
    for pattern, deviceIcon in pairs(deviceIcons) do
        if string.find(deviceName:lower(), pattern:lower()) then
            icon = deviceIcon
            break
        end
    end

    notification.show(string.format("%s   %s", icon, deviceName))
end

function obj:init()
    -- Add menu bar item
    self.menuBarItem = hs.menubar.new()
    self.menuBarItem:setClickCallback(function()
        self:switchAudioDevice()
    end)
    
    -- Update menu bar icon
    local currentDevice = hs.audiodevice.defaultOutputDevice()
    if currentDevice then
        self:showDeviceNotification(currentDevice:name())
    end
end

return obj
