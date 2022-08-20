local obj = {}
obj.__index = obj

function obj:registerHotKey(modifiers, button, appName)
    hs.hotkey.bind(modifiers, button, function()
        openApp(appName)
    end)
end

function obj:openApp(name)
    local logger = hs.logger.new("capslock", 'verbose')
    local app = hs.application.find(name)

    if not app or app:isHidden() then
      hs.application.launchOrFocus(name)
    elseif hs.application.frontmostApplication() ~= app then
      app:activate()
    else
      app:hide()
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

return obj
