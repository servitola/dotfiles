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

-- Last line of the run's output, shown as an alert; `quiet` keeps a successful run silent.
local function runPhone(args, quiet)
    local task = hs.task.new(home .. "/projects/android_phone/bin/phone", function(code, stdout, stderr)
        local msg = (code == 0 and stdout or stderr):match("([^\n]+)\n?$")
        if msg and not (quiet and code == 0) then hs.alert.show("Jelly Max: " .. msg, 5) end
    end, args)
    local env = task:environment()
    env.PATH = "/opt/homebrew/bin:" .. (env.PATH or "/usr/bin:/bin")
    task:setEnvironment(env)
    return task:start()
end

local _jellyTask = nil
local function jellyScreenToggle()
    local window = hs.window.find("^Jelly Max$")
    if window then
        if hs.window.focusedWindow() == window then window:close() else window:focus() end
        return
    end
    if _jellyTask and _jellyTask:isRunning() then return end
    _jellyTask = runPhone({ "screen" }, true)
    -- scrcpy, started as a child of Hammerspoon, opens its window in the background
    hs.timer.waitUntil(function() return hs.window.find("^Jelly Max$") or not _jellyTask:isRunning() end,
        function()
            local w = hs.window.find("^Jelly Max$")
            if not w then return end
            -- the owner's hand-picked spot on the built-in display: a phone-shaped strip at the right
            w:moveToUnit({ x = 0.730, y = 0.006, w = 0.262, h = 0.912 }, 0)
            w:focus()
        end, 0.3)
end

-- Any USB device triggers it: the phone's USB product name is not known, and the script
-- exits at once unless Wi-Fi ADB is down and the Jelly is on the cable.
local _jellyRescueTask = nil
_G.jellyUsbWatcher = hs.usb.watcher.new(function(event)
    if event.eventType ~= "added" or (_jellyRescueTask and _jellyRescueTask:isRunning()) then return end
    hs.timer.doAfter(3, function() _jellyRescueTask = runPhone({ "usb-rescue" }) end)
end):start()

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
    register("jelly.screen_toggle", jellyScreenToggle)
end
