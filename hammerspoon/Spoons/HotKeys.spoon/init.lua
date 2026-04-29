local obj={}

-- Hyper is Caps Lock (⇪) remapped to Hyper in Karabiner-Elements
-- Karabiner sends: right_command + right_control + right_option + right_shift simultaneously

hyper = { "right_command", "right_control", "right_option", "right_shift" }

local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")
local log = hs.logger.new('HotKeys', 'info')
local vpnGlobalProtect = dofile(spoonPath .. "vpn_globalprotect.lua")
local yandexSearch = dofile(spoonPath .. "yandex_search.lua")
local systemHealth = dofile(spoonPath .. "system_health.lua")
local clipboardLlm = dofile(spoonPath .. "clipboard_llm.lua")

local _launchTask = nil  -- prevent GC of hs.task used for app launching

-- Generic helper: focus a specific window of an app, or launch it with a path
-- appNameOrId: bundle ID (e.g. "com.microsoft.VSCode") or app name (e.g. "Fork")
-- appDisplayName: name for "open -a" launch (required for bundle IDs)
local function focusAppWindow(appNameOrId, titlePattern, launchPath, appDisplayName)
    local isBundleId = appNameOrId:find("%.")
    local app
    if isBundleId then
        app = hs.application.get(appNameOrId)
    else
        local found = hs.application.find(appNameOrId)
        if found and tostring(found):match("hs.window:") then
            app = found:application()
        else
            app = found
        end
    end

    if not app then
        local launchName = appDisplayName or appNameOrId
        _launchTask = hs.task.new("/usr/bin/open", function() _launchTask = nil end,
            { "-a", launchName, launchPath })
        _launchTask:start()
        return
    end

    local targetWindow = nil
    for _, window in ipairs(app:allWindows()) do
        if window:title():find(titlePattern) then
            targetWindow = window
            break
        end
    end

    if targetWindow then
        if hs.application.frontmostApplication() == app and hs.window.focusedWindow() == targetWindow then
            app:hide()
        else
            if targetWindow:isMinimized() then targetWindow:unminimize() end
            targetWindow:focus()
        end
    else
        _launchTask = hs.task.new("/usr/bin/open", function() _launchTask = nil end,
            { "-a", appNameOrId:find("%.") and appNameOrId or appNameOrId, launchPath })
        _launchTask:start()
    end
end

local function unminimize_if_needed(app)
    if not app then return false end
    if app.isHidden and app:isHidden() then app:unhide() end
    local hasVisible = false
    for _, win in ipairs(app:allWindows() or {}) do
        if win:isStandard() and not win:isMinimized() then
            hasVisible = true
            break
        end
    end
    if not hasVisible then
        local unminimized = false
        for _, win in ipairs(app:allWindows() or {}) do
            if win:isMinimized() then
                win:unminimize()
                unminimized = true
        end
    end
        return unminimized
    end
    return true
end

local buttonFiles = {
    "tilde",
    "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
    "minus", "equal", "backspace",
    "tab",
    "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
    "bracketleft", "bracketright",
    "return",
    "capslock",
    "a", "s", "d", "f", "g", "h", "j", "k", "l",
    "semicolon", "apostrophe", "backslash",
    "shift",
    "z", "x", "c", "v", "b", "n", "m",
    "period", "comma", "slash",
    "space",
    "left","up", "down", "right"
}

-- Icons used:
--  — MacOS or common
-- 🌐 — Browser
-- ℝ — Rider IDE
-- 📁 — Finder
-- 🔄 — Git
-- 📝 — VSCode
-- 🔗 — Many apps but not macos itself

-- ⚠️ —— HARD TO PRESS, don't use

-- ⇪ -- Hyper (Caps Lock)
-- ⌘ -- Command
-- ⌥ -- Option/Alt
-- ⌃ -- Control
-- ⇧ -- Shift
-- ⌫ -- Backspace
-- ⇥ -- Tab
-- ↩ -- Return/Enter
-- ␣ -- Space
-- ⎋ -- Escape

local function parseChord(chordStr)
    local modifiers = {}
    local key = ""

    local numMatch = chordStr:match("num(%d)")
    if numMatch then
        key = "pad" .. numMatch
    else
        key = chordStr:match("F%d+") or chordStr:match("[a-z0-9]$")
    end

    if key == nil then
        if chordStr:match("⎋") then
            key = "escape"
        elseif chordStr:match("⇥") then
            key = "tab"
        elseif chordStr:match("%[") then
            key = "["
        elseif chordStr:match("%]") then
            key = "]"
        elseif chordStr:match("←") then
            key = "left"
        elseif chordStr:match("→") then
            key = "right"
        elseif chordStr:match("↑") then
            key = "up"
        elseif chordStr:match("↓") then
            key = "down"
        elseif chordStr:match(",") then
            key = ","
        elseif chordStr:match("%.") then
            key = "."
        end
    end

    if chordStr:find("⇪") then
        table.insert(modifiers, "right_command")
        table.insert(modifiers, "right_control")
        table.insert(modifiers, "right_option")
        table.insert(modifiers, "right_shift")
    end
    if chordStr:find("⇧") then table.insert(modifiers, "shift") end
    if chordStr:find("⌃") then table.insert(modifiers, "ctrl") end
    if chordStr:find("⌥") then table.insert(modifiers, "alt") end
    if chordStr:find("⌘") then table.insert(modifiers, "cmd") end

    return modifiers, key
end

local layoutsPath = spoonPath .. "layout/" .. "60%/"

allChords = {}

for _, filename in ipairs(buttonFiles) do
    local filePath = layoutsPath .. filename .. ".lua"
    local success, buttonData = pcall(dofile, filePath)
    if not success then
        log.e("Failed to load: " .. filePath .. "\nError: " .. tostring(buttonData))
        goto continue
    end
    if not buttonData or type(buttonData) ~= "table" then
        log.e("Invalid data in: " .. filePath .. " (expected table, got " .. type(buttonData) .. ")")
        goto continue
    end
    for _, chord_entry in ipairs(buttonData) do
        if chord_entry then
            table.insert(allChords, chord_entry)
        end
    end
    ::continue::
end

log.d("Loaded " .. #allChords .. " total chord entries")

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

local appSpecificHotkeys = {
    ["Fork"] = {
        { from = {"cmd", "shift"}, key = "e", to = {"cmd", "shift"}, target_key = "l" },
        { from = {"cmd", "shift"}, key = "r", to = {"cmd", "shift"}, target_key = "p" },
    },
    ["Music"] = {
        { from = {"cmd"}, key = "e", to = {"cmd"}, target_key = "l" },
    },
    ["WarpOss"] = {
        { from = {"alt"}, key = "z", sendText = "/new" },
    },
    ["Finder"] = {
        { from = {"alt"}, key = "z", to = {"cmd", "alt"}, target_key = "l" },
	},
    ["*"] = {
        { from = {"left_control", "alt", "cmd"}, key = "x", to = {"cmd"}, target_key = "[" },
        { from = {"left_control", "alt", "cmd"}, key = "c", to = {"cmd"}, target_key = "]" }
    }
}

local appSpecificHelper = dofile(spoonPath .. "app_specific_hotkeys.lua")

function obj:init()

    hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
        spoon.KSheet:hide()
        ksheet = not ksheet
        unsubscribe()
    end)

    appSpecificHelper.init(appSpecificHotkeys)

    local bindCount = 0
    for _, chord_entry in ipairs(allChords) do
        if chord_entry.chord then
            local code = chord_entry.chord
            if chord_entry.code then
                code = chord_entry.code
            end

            local modifiers, key = parseChord(code)

            if chord_entry.app then
                log.d(string.format("Binding chord='%s' → modifiers=[%s], key='%s', app='%s'",
                    code, table.concat(modifiers, ", "), key, chord_entry.app))
            elseif chord_entry.fn then
                log.d(string.format("Binding chord='%s' → modifiers=[%s], key='%s', fn='%s'",
                    code, table.concat(modifiers, ", "), key, chord_entry.fn))
            end

            if chord_entry.fn then
                local functionName = chord_entry.fn
                bindCount = bindCount + 1

                if functionName == "window.left" then
                    spoon.Windows:bind_window_left(modifiers, key)
                elseif functionName == "window.right" then
                    spoon.Windows:bind_window_right(modifiers, key)
                elseif functionName == "window.fullscreen" then
                    spoon.Windows:bind_window_fullscreen(modifiers, key)
                elseif functionName == "window.set_all_to_default" then
                    spoon.Windows:bind_all_windows_to_default(modifiers, key)
                elseif functionName == "window.half_left" then
                    spoon.Windows:bind_window_half_left(modifiers, key)
                elseif functionName == "window.half_right" then
                    spoon.Windows:bind_window_half_right(modifiers, key)
                elseif functionName == "window.top_60" then
                    spoon.Windows:bind_window_top_60(modifiers, key)
                elseif functionName == "window.bottom_40" then
                    spoon.Windows:bind_window_bottom_40(modifiers, key)
                elseif functionName == "window.center" then
                    spoon.Windows:bind_window_center(modifiers, key)
                elseif functionName == "android.show_all" then
                    hs.hotkey.bind(modifiers, key, function()
                        local matching_windows = {}
                        for _, window in ipairs(hs.window.allWindows()) do
                            local app = window:application()
                            if app then
                            local window_title = window:title()
                                local app_title = app:title()
                            for _, pattern in ipairs({"qemu-system-aarch64"}) do
                                if app_title == pattern or string.find(window_title, pattern) then
                                    table.insert(matching_windows, window)
                                end
                            end
                        end
                        end

                        if #matching_windows == 0 then
                            return
                        end

                        local any_visible = false
                        for _, window in ipairs(matching_windows) do
                            if window:isVisible() then
                                any_visible = true
                                break
                            end
                        end

                        if any_visible then
                            for _, window in ipairs(matching_windows) do
                                window:application():hide()
                            end
                        else
                            for _, window in ipairs(matching_windows) do
                                window:focus()
                            end
                        end
                    end)
                elseif functionName == "info.show_shortcuts" then
                    hs.hotkey.bind(modifiers, key, function()
                        if ksheet then
                            spoon.KSheet:hide()
                        else
                            hideKSheetShortCut:enable();
                            spoon.KSheet:show()
                        end

                        ksheet = not ksheet
                    end)
                elseif functionName == "set_russian_language" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.keycodes.setLayout("Ru Birman")
                    end)
                elseif functionName == "set_english_language" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.keycodes.setLayout("En Birman")
                    end)
                elseif functionName == "translate_to_russian" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_ru = {modifiers, key},
                    })
                elseif functionName == "translate_to_english" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_en = {modifiers, key},
                    })
                elseif functionName == "translate_to_greek" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_el = {modifiers, key},
                    })
                elseif functionName == "audio.internal" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.AudioSwitcher:switchToInternal()
                    end)
                elseif functionName == "audio.external" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.AudioSwitcher:switchToExternal()
                    end)
                elseif functionName == "audio.marshall" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.AudioSwitcher:switchToMarshall()
                    end)
                elseif functionName == "audio.connect_marshall" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.AudioSwitcher:connectAndSwitchToMarshall()
                    end)
                elseif functionName == "audio.bt" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.AudioSwitcher:connectAndSwitchToBT()
                    end)
                elseif functionName == "show_youtrack" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.YouTrackTicket:toggle()
                    end)
                elseif functionName == "show_youtrack_tasks" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.YouTrackTasks:toggle()
                    end)
                elseif functionName == "browser_git" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.BrowserTabOpener:openTab("github.com")
                    end)
                elseif functionName == "browser_git_dotfiles" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.BrowserTabOpener:openTab("github.com/servitola/dotfiles")
                    end)
                elseif functionName == "press_return" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.eventtap.keyStroke({}, "return")
                    end)
                elseif functionName == "browser_youtube" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.BrowserTabOpener:openTab("youtube.com")
                    end)
                elseif functionName == "browser_youtube_playing" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.BrowserTabOpener:focusPlayingTab("youtube.com/watch")
                    end)
                elseif functionName == "youtube_stream" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.YouTubeStream:toggle()
                    end)
                elseif functionName == "vpn.toggle_globalprotect" then
                    hs.hotkey.bind(modifiers, key, function()
                        vpnGlobalProtect.toggle()
                    end)
                elseif functionName == "browser_search_selected" then
                    hs.hotkey.bind(modifiers, key, function()
                        yandexSearch.searchSelectedText()
                    end)
                elseif functionName == "paste_bypass" then
                    hs.hotkey.bind(modifiers, key, function()
                        local contents = hs.pasteboard.getContents()
                        if contents then
                            if #contents > 10000 then
                                hs.alert.show("Clipboard too large (" .. #contents .. " chars)", 2)
                                return
                            end
                            hs.eventtap.keyStrokes(contents)
                        end
                    end)
                elseif functionName == "musicapp.play_pause" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.itunes.playpause()
                    end)
                elseif functionName == "vscode.dotfiles" then
                    hs.hotkey.bind(modifiers, key, function()
                        focusAppWindow("com.microsoft.VSCode", "dotfiles",
                            os.getenv("HOME") .. "/projects/dotfiles", "Visual Studio Code")
                    end)
                elseif functionName == "fork.dotfiles" then
                    hs.hotkey.bind(modifiers, key, function()
                        focusAppWindow("Fork", "dotfiles",
                            os.getenv("HOME") .. "/projects/dotfiles")
                    end)
                elseif functionName == "warp.launch_default" then
                    local warpLaunchWatcher = nil
                    local warpTimer1 = nil  -- prevent GC
                    local warpTimer2 = nil  -- prevent GC
                    hs.hotkey.bind(modifiers, key, function()
                        local warp = hs.application.get("dev.warp.WarpOss")
                        if not warp then
                            -- Stop any previous watcher to prevent leaks on rapid presses
                            if warpLaunchWatcher then warpLaunchWatcher:stop() end
                            warpLaunchWatcher = hs.application.watcher.new(function(name, event, app)
                                if name == "WarpOss" and event == hs.application.watcher.launched then
                                    warpLaunchWatcher:stop()
                                    warpLaunchWatcher = nil
                                    warpTimer1 = hs.timer.doAfter(0.3, function()
                                        warpTimer1 = nil
                                        local w = hs.application.get("dev.warp.WarpOss")
                                        if not w then return end
                                        local savedFrame
                                        local windows = w:allWindows()
                                        if #windows > 0 then
                                            savedFrame = windows[1]:frame()
                                        end
                                        for _, win in ipairs(windows) do
                                            win:close()
                                        end
                                        w:hide()
                                        hs.urlevent.openURL("warposs://launch/Default")
                                        warpTimer2 = hs.timer.doAfter(0.3, function()
                                            warpTimer2 = nil
                                            local w2 = hs.application.get("dev.warp.WarpOss")
                                            if w2 then
                                                local win = w2:mainWindow()
                                                if win and savedFrame then
                                                    win:setFrame(savedFrame)
                                                end
                                                w2:activate()
                                            end
                                        end)
                                    end)
                                end
                            end)
                            warpLaunchWatcher:start()
                            hs.application.open("dev.warp.WarpOss")
                        elseif hs.application.frontmostApplication() == warp then
                            warp:hide()
                        else
                            unminimize_if_needed(warp)
                            warp:activate()
                        end
                    end)
                elseif functionName == "fork.ctraderdev" then
                    hs.hotkey.bind(modifiers, key, function()
                        focusAppWindow("Fork", "cTraderDev",
                            os.getenv("HOME") .. "/projects/Spotware/cTraderDev")
                    end)
                elseif functionName == "system_health" then
                    hs.hotkey.bind(modifiers, key, function()
                        systemHealth.toggle()
                    end)
                elseif functionName == "clipboard_llm" then
                    hs.hotkey.bind(modifiers, key, function()
                        clipboardLlm.show()
                    end)
                elseif functionName == "app_usage_stats" then
                    hs.hotkey.bind(modifiers, key, function()
                        if appUsageAnalytics then appUsageAnalytics.toggle() end
                    end)
                    hs.hotkey.bind(modifiers, key, function()
                    end)
                elseif functionName == "window.hide_all_except_work"
                    or functionName == "window.focus_work"
                    or functionName == "window.focus_personal"
                    or functionName == "window.focus_comms" then
                    local exceptionSets = {
                        ["window.hide_all_except_work"] = { ["WarpOss"] = true, ["Workbot"] = true },
                        ["window.focus_work"] = {
                            ["Rider"] = true, ["Fork"] = true, ["Firefox"] = true,
                            ["WarpOss"] = true, ["Code"] = true,
                            ["Workbot"] = true
                        },
                        ["window.focus_personal"] = {
                            ["Telegram"] = true, ["Yandex"] = true
                        },
                        ["window.focus_comms"] = {
                            ["Telegram"] = true, ["Messages"] = true,
                            ["zoom.us"] = true, ["Yandex Telemost"] = true
                        },
                    }
                    local focusApps = {
                        ["window.hide_all_except_work"] = { "WarpOss" },
                        ["window.focus_work"] = { "Firefox" },
                        ["window.focus_personal"] = { "Telegram" },
                        ["window.focus_comms"] = { "zoom.us", "Yandex Telemost", "Telegram" },
                    }
                    local exceptions = exceptionSets[functionName]
                    local focusList = focusApps[functionName]
                    hs.hotkey.bind(modifiers, key, function()
                        hs.closeConsole()
                        for _, app in ipairs(hs.application.runningApplications()) do
                            if app:kind() == 1 then
                                local appName = app:name()
                                local isException = exceptions[appName]
                                if isException then
                                    if app:isHidden() then app:unhide() end
                                    for _, win in ipairs(app:allWindows()) do
                                        if win:isMinimized() then win:unminimize() end
                                        set_window_default(win)
                                    end
                                elseif appName == "Yandex" then
                                    local hasVideo = false
                                    for _, win in ipairs(app:allWindows()) do
                                        if is_yandex_video_player(appName, win:title(), win) then
                                            hasVideo = true
                                        else
                                            win:minimize()
                                        end
                                    end
                                    if not hasVideo and not app:isHidden() then app:hide() end
                                elseif appName == "Telegram" then
                                    local hasVideo = false
                                    for _, win in ipairs(app:allWindows()) do
                                        if not win:isStandard() then
                                            hasVideo = true
                                        else
                                            win:minimize()
                                        end
                                    end
                                    if not hasVideo and not app:isHidden() then app:hide() end
                                else
                                    if not app:isHidden() then app:hide() end
                                end
                            end
                        end
                        for _, name in ipairs(focusList) do
                            local a = hs.application.get(name)
                            if a then a:activate(); break end
                        end
                    end)
                elseif functionName == "window.hide_current" then
                    hs.hotkey.bind(modifiers, key, function()
                        local win = hs.window.focusedWindow()
                        if win then win:minimize() end
                    end)
                elseif functionName == "hammerspoon_reload" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.reload()
                    end)
                elseif functionName == "wallpaper_refresh" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.GruvboxWallpapers:setRandomWallpaper()
                    end)
                end
            elseif chord_entry.app then
                hs.hotkey.bind(modifiers, key, function()

                    local modifierStr = table.concat(modifiers, "+")
                    log.d("Hotkey triggered: " .. modifierStr .. "+" .. key .. " → " .. chord_entry.app)

                    local app
                    if chord_entry.app == "Visual Studio Code" then
                        app = hs.application.get("com.microsoft.VSCode")
                    else
                        local found = hs.application.find(chord_entry.app)
                        app = found
                        if found and tostring(found):match("hs.window:") then
                            app = found:application()
                            log.d("Found window, getting application: " .. tostring(app))
                        end
                    end

                    if not app or (app and app.isHidden and app:isHidden()) then
                        log.d("Launching/focusing app: " .. chord_entry.app)
                        hs.application.launchOrFocus(chord_entry.app)
                        hs.timer.doAfter(0.15, function()
                            unminimize_if_needed(hs.application.find(chord_entry.app))
                        end)
                    elseif hs.application.frontmostApplication() ~= app then
                        log.d("Activating app: " .. chord_entry.app)
                        if not unminimize_if_needed(app) then
                            hs.application.launchOrFocus(chord_entry.app)
                        else
                        app:activate()
                        end
                    else
                        local hasVisibleWindow = false
                        for _, win in ipairs(app:allWindows() or {}) do
                            if win:isVisible() then
                                hasVisibleWindow = true
                                break
                            end
                        end
                        if hasVisibleWindow then
                            log.d("Hiding app: " .. chord_entry.app)
                            if app and app.hide then app:hide() end
                        else
                            log.d("Opening main window for app: " .. chord_entry.app)
                            if not unminimize_if_needed(app) then
                                hs.application.launchOrFocus(chord_entry.app)
                            end
                        end
                    end
                end)
            elseif chord_entry.sendKey then
                hs.hotkey.bind(modifiers, key, function()
                    hs.eventtap.keyStrokes(chord_entry.sendKey)
                end)
                bindCount = bindCount + 1
            end

            if chord_entry.window_default_position and chord_entry.app then
                if chord_entry.window_default_position == "right" then
                    spoon.Windows:add_right_window_type_app(chord_entry.app)
                elseif chord_entry.window_default_position == "bottom" then
                    spoon.Windows:add_bottom_window_type_app(chord_entry.app)
                end
            end

            ::continue::
        end
    end

    log.d("Successfully bound " .. bindCount .. " hotkeys")
end

return obj
