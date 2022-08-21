local obj = {}
obj.__index = obj

function obj:openApp(name)
    local app = hs.application.get(name)

    if not app or app:isHidden() then
      hs.application.launchOrFocus(name)
    elseif hs.application.frontmostApplication() ~= app then
      app:activate()
    else
      app:hide()
    end
  end

function obj:bindOpenApp(modifier, key, app_name)
    hs.hotkey.bind(modifier, key, function()
        obj:openApp(app_name)
    end)
end

return obj
