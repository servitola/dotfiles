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

function obj:setup(app_list)
     for _, app in ipairs(app_list) do
        hs.hotkey.bind(hyper, app.key, function()
            obj:openApp(app.name)
        end)
     end
end

function obj:init()
    hs.hotkey.bind(hyper, "-", function()
        obj:openApp("Team Viewer")
    end)
    hs.hotkey.bind(ctrlAndAlt, "r", function()
        obj:openApp("Android Studio")
    end)
    hs.hotkey.bind(hyper, '[', function()
        hs.itunes.previous()
    end)
    hs.hotkey.bind(hyper, ']', function()
        hs.itunes.next()
    end)
    hs.hotkey.bind(hyper, "b", function()
        obj:openApp("Ableton")
    end)
    hs.hotkey.bind(hyper, "m", function()
        obj:openApp("YouTube")
    end)
    hs.hotkey.bind(hyper, 'space', function()
        hs.itunes.playpause()
    end)
end

return obj
