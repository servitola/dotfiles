local home = os.getenv("HOME")
local _launchTask = nil  -- prevent GC of hs.task used for app launching

local function focusAppWindow(appNameOrId, titlePattern, launchPath, appDisplayName)
    local app = appNameOrId:find("%.") and hs.application.get(appNameOrId)
        or hs.application.find(appNameOrId)
    if app and tostring(app):match("hs.window:") then app = app:application() end

    if not app then
        _launchTask = hs.task.new("/usr/bin/open", function() _launchTask = nil end,
            { "-a", appDisplayName or appNameOrId, launchPath })
        _launchTask:start()
        return
    end

    for _, window in ipairs(app:allWindows()) do
        if window:title():find(titlePattern) then
            if hs.application.frontmostApplication() == app and hs.window.focusedWindow() == window then
                app:hide()
            else
                if window:isMinimized() then window:unminimize() end
                window:focus()
            end
            return
        end
    end
    _launchTask = hs.task.new("/usr/bin/open", function() _launchTask = nil end,
        { "-a", appDisplayName or appNameOrId, launchPath })
    _launchTask:start()
end

local zapLaunchWatcher, zapTimer1, zapTimer2  -- kept alive against GC

local function zapLaunchDefault()
    local zap = hs.application.get("dev.zap.Zap")
    if zap then
        if hs.application.frontmostApplication() == zap then
            zap:hide()
        else
            spoon.HotKeys.unminimizeIfNeeded(zap)
            zap:activate()
        end
        return
    end
    if zapLaunchWatcher then zapLaunchWatcher:stop() end
    zapLaunchWatcher = hs.application.watcher.new(function(name, event)
        if name ~= "Zap" or event ~= hs.application.watcher.launched then return end
        zapLaunchWatcher:stop()
        zapLaunchWatcher = nil
        zapTimer1 = hs.timer.doAfter(0.3, function()
            zapTimer1 = nil
            local w = hs.application.get("dev.zap.Zap")
            if not w then return end
            local windows = w:allWindows()
            local savedFrame = windows[1] and windows[1]:frame()
            for _, win in ipairs(windows) do win:close() end
            w:hide()
            hs.urlevent.openURL("zap://launch/Default")
            zapTimer2 = hs.timer.doAfter(0.3, function()
                zapTimer2 = nil
                local w2 = hs.application.get("dev.zap.Zap")
                if not w2 then return end
                local win = w2:mainWindow()
                if win and savedFrame then win:setFrame(savedFrame) end
                w2:activate()
            end)
        end)
    end)
    zapLaunchWatcher:start()
    hs.application.open("dev.zap.Zap")
end

local function androidShowAll()
    local matching = {}
    for _, window in ipairs(hs.window.allWindows()) do
        local app = window:application()
        if app and (app:title() == "qemu-system-aarch64" or window:title():find("qemu-system-aarch64")) then
            table.insert(matching, window)
        end
    end
    if #matching == 0 then return end
    local anyVisible = false
    for _, window in ipairs(matching) do
        if window:isVisible() then anyVisible = true break end
    end
    for _, window in ipairs(matching) do
        if anyVisible then window:application():hide() else window:focus() end
    end
end

return function(register)
    register("vscode.dotfiles", function()
        focusAppWindow("com.microsoft.VSCode", "dotfiles", home .. "/projects/dotfiles", "Visual Studio Code")
    end)
    register("fork.dotfiles", function()
        focusAppWindow("com.DanPristupov.Fork", "dotfiles", home .. "/projects/dotfiles", "Fork")
    end)
    register("fork.workprojectdev", function()
        focusAppWindow("com.DanPristupov.Fork", "workprojectDev", home .. "/projects/workname/workprojectDev", "Fork")
    end)
    register("forkgram.chat", function()
        hs.urlevent.openURLWithBundle("tg://privatepost?channel=3172923198", "com.tdesktop.Telegram")
    end)
    register("zap.launch_default", zapLaunchDefault)
    register("android.show_all", androidShowAll)
end
