local home = os.getenv("HOME")
local constants = require "constants"
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
    register("fork.work", function()
        local repo = constants.DIR_WORK_MAIN
        focusAppWindow("com.DanPristupov.Fork", repo:match("[^/]+$"), repo, "Fork")
    end)
    register("forkgram.chat", function()
        local channel = constants.TG_CHAT_MAIN:gsub("^%-100", "")
        hs.urlevent.openURLWithBundle("tg://privatepost?channel=" .. channel, "com.tdesktop.Telegram")
    end)
    register("android.show_all", androidShowAll)
end
