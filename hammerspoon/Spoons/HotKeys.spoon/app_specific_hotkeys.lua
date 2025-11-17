-- App-specific hotkey remapping helper functions
local M = {}

local appHotkeys = {}
local appWatcher = nil

local function setupAppHotkeys(appName, remaps)
    if not appHotkeys[appName] then
        appHotkeys[appName] = {}
    end

    for _, remap in pairs(remaps) do
        local hotkey = hs.hotkey.new(remap.from, remap.key, function()
            hs.eventtap.keyStroke(remap.to, remap.target_key)
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
    -- Setup hotkeys for all configured apps
    for appName, remaps in pairs(appSpecificHotkeys) do
        if appName == "*" then
            -- Global hotkeys - always enabled
            for _, remap in pairs(remaps) do
                hs.hotkey.bind(remap.from, remap.key, function()
                    hs.eventtap.keyStroke(remap.to, remap.target_key)
                end)
            end
        else
            -- App-specific hotkeys
            setupAppHotkeys(appName, remaps)
        end
    end

    -- Watch for app focus changes
    appWatcher = hs.application.watcher.new(function(appName, eventType, appObject)
        if eventType == hs.application.watcher.activated then
            -- Disable all app-specific hotkeys
            for app, _ in pairs(appHotkeys) do
                disableAppHotkeys(app)
            end
            -- Enable hotkeys for the newly focused app
            enableAppHotkeys(appName)
        end
    end)
    appWatcher:start()

    -- Enable hotkeys for currently focused app
    local currentApp = hs.application.frontmostApplication()
    if currentApp then
        enableAppHotkeys(currentApp:name())
    end
end

function M.stop()
    if appWatcher then
        appWatcher:stop()
        appWatcher = nil
    end

    -- Disable all hotkeys
    for appName, _ in pairs(appHotkeys) do
        disableAppHotkeys(appName)
    end
end

return M
