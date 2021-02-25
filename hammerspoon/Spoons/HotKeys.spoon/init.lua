local obj = {}
obj.__index = obj

function obj:registerHotKey(modifiers, button, appName)
    hs.hotkey.bind(modifiers, button, function()
        openApp(appName)
    end)
end

function obj:openApp(name)
    local logger = hs.logger.new("capslock", 'verbose')
    logger.d()
    logger.d('Open App:')
    logger.d(name)

    local app = hs.application.get(name)
    if app then
        if app:isFrontmost() then
            app:hide()
        else
            app:mainWindow():focus()
        end
    else
        hs.application.launchOrFocus(name)
    end
end

function obj:setup(modifier, app_list)
     for _, shortcut_info in ipairs(app_list) do
        if shortcut_info.app_name then
            hs.hotkey.bind(modifier, shortcut_info.key, function()
                obj:openApp(shortcut_info.app_name)
            end)
        end
     end
end

function obj:bindOpenApp(modifier, key, app_name)
    hs.hotkey.bind(modifier, key, function()
        obj:openApp(app_name)
    end)
end

function obj:init()
    hs.hotkey.bind(hyper, '[', function()
        hs.itunes.previous()
    end)
    hs.hotkey.bind(hyper, ']', function()
        hs.itunes.next()
    end)
    hs.hotkey.bind(hyper, 'space', function()
        hs.itunes.playpause()
    end)
end

return obj
