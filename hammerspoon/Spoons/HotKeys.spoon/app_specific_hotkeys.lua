-- App-specific hotkey remapping helper functions
local M = {}

local appHotkeys = {}

local function setupAppHotkeys(appName, remaps)
    if not appHotkeys[appName] then
        appHotkeys[appName] = {}
    end

    for _, remap in pairs(remaps) do
        local hotkey = hs.hotkey.new(remap.from, remap.key, function()
            if remap.sendText then
                hs.eventtap.keyStrokes(remap.sendText)
            else
                hs.eventtap.keyStroke(remap.to, remap.target_key, 0)
            end
        end)
        table.insert(appHotkeys[appName], hotkey)
    end
end

local function enableAppHotkeys(appName)
    if appHotkeys[appName] then
        for _, hotkey in pairs(appHotkeys[appName]) do
            hotkey:enable()
        end
    end
end

local function disableAppHotkeys(appName)
    if appHotkeys[appName] then
        for _, hotkey in pairs(appHotkeys[appName]) do
            hotkey:disable()
        end
    end
end

function M.init(appSpecificHotkeys)
    for appName, remaps in pairs(appSpecificHotkeys) do
        if appName == "*" then
            for _, remap in pairs(remaps) do
                hs.hotkey.bind(remap.from, remap.key, function()
                    if remap.sendText then
                        hs.eventtap.keyStrokes(remap.sendText)
                    else
                        hs.eventtap.keyStroke(remap.to, remap.target_key, 0)
                    end
                end)
            end
        else
            setupAppHotkeys(appName, remaps)
        end
    end

    -- Register with centralized app watcher hub (no own watcher)
    appWatcherHub.register(function(appName, eventType, appObject)
        if eventType == hs.application.watcher.activated then
            for app, _ in pairs(appHotkeys) do
                disableAppHotkeys(app)
            end
            enableAppHotkeys(appName)
        end
    end)

    local currentApp = hs.application.frontmostApplication()
    if currentApp then
        enableAppHotkeys(currentApp:name())
    end
end

function M.stop()
    for appName, _ in pairs(appHotkeys) do
        disableAppHotkeys(appName)
    end
end

return M
