local obj={}

-- Hyper is Caps Lock (⇪) remapped to Hyper in Karabiner-Elements
-- Karabiner sends: right_command + right_control + right_option + right_shift simultaneously

hyper = { "right_command", "right_control", "right_option", "right_shift" }

local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")
local vpnGlobalProtect = dofile(spoonPath .. "vpn_globalprotect.lua")
local yandexSearch = dofile(spoonPath .. "yandex_search.lua")

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
        elseif chordStr:match(".") then
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

local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")
local layoutsPath = spoonPath .. "layout/" .. "60%/"

allChords = {}

for _, filename in ipairs(buttonFiles) do
    local filePath = layoutsPath .. filename .. ".lua"
    local success, buttonData = pcall(dofile, filePath)
    if not success then
        error("Failed to load: " .. filePath .. "\nError: " .. tostring(buttonData))
    end
    if not buttonData or type(buttonData) ~= "table" then
        error("Invalid data in: " .. filePath .. " (expected table, got " .. type(buttonData) .. ")")
    end
    for _, chord_entry in ipairs(buttonData) do
        if chord_entry then
            table.insert(allChords, chord_entry)
        end
    end
end

print("DEBUG: Loaded " .. #allChords .. " total chord entries")

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

local appSpecificHotkeys = {
    ["Fork"] = {
        { from = {"cmd", "shift"}, key = "e", to = {"cmd", "shift"}, target_key = "l" },
        { from = {"cmd", "shift"}, key = "r", to = {"cmd", "shift"}, target_key = "p" },
        { from = {"control"}, key = "1", to = {"cmd", "alt"}, target_key = "1"},
        { from = {"control"}, key = "2", to = {"cmd", "alt"}, target_key = "2"},
        { from = {"control"}, key = "3", to = {"cmd", "alt"}, target_key = "3"}
    },
    ["Music"] = {
        { from = {"cmd"}, key = "e", to = {"cmd"}, target_key = "l" },
    },
    ["Warp"] = {
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
                print(string.format("Binding chord='%s' → modifiers=[%s], key='%s', app='%s'",
                    code, table.concat(modifiers, ", "), key, chord_entry.app))
            elseif chord_entry.fn then
                print(string.format("Binding chord='%s' → modifiers=[%s], key='%s', fn='%s'",
                    code, table.concat(modifiers, ", "), key, chord_entry.fn))
            end

            if chord_entry.app then
                hs.hotkey.bind(modifiers, key, function()

                    local modifierStr = table.concat(modifiers, "+")
                    print("Hotkey triggered: " .. modifierStr .. "+" .. key .. " → " .. chord_entry.app)

                    local app
                    if chord_entry.app == "Visual Studio Code" then
                        app = hs.application.get("com.microsoft.VSCode")
                    else
                        local found = hs.application.find(chord_entry.app)
                        app = found
                        if found and tostring(found):match("hs.window:") then
                            app = found:application()
                            print("Found window, getting application: " .. tostring(app))
                        end
                    end

                    if not app or (app and app.isHidden and app:isHidden()) then
                        print("Launching/focusing app: " .. chord_entry.app)
                        hs.application.launchOrFocus(chord_entry.app)
                    elseif hs.application.frontmostApplication() ~= app then
                        print("Activating app: " .. chord_entry.app)
                        if app and app.activate then
                            hs.application.launchOrFocus(chord_entry.app)
                        end
                    else
                        print("Hiding app: " .. chord_entry.app)
                        if app and app.hide then
                            app:hide()
                        end
                    end
                end)
                if chord_entry.window_default_position then
                    if chord_entry.window_default_position == "right" then
                        spoon.Windows:add_right_window_type_app(chord_entry.app)
                    elseif chord_entry.window_default_position == "bottom" then
                        spoon.Windows:add_bottom_window_type_app(chord_entry.app)
                    end
                end
            elseif chord_entry.sendKey then
                hs.hotkey.bind(modifiers, key, function()
                    hs.eventtap.keyStrokes(chord_entry.sendKey)
                end)
                bindCount = bindCount + 1
            elseif chord_entry.fn then
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
                elseif functionName == "android.show_all" then
                    hs.hotkey.bind(modifiers, key, function()
                        local matching_windows = {}
                        for _, window in ipairs(hs.window.allWindows()) do
                            local window_title = window:title()
                            local app_title = window:application():title()
                            for _, pattern in ipairs({"qemu-system-aarch64"}) do
                                if app_title == pattern or string.find(window_title, pattern) then
                                    table.insert(matching_windows, window)
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
                elseif functionName == "audio.bt" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.AudioSwitcher:switchToBT()
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
                elseif functionName == "press_return" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.eventtap.keyStroke({}, "return")
                    end)
                elseif functionName == "browser_youtube" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.BrowserTabOpener:openPlayingYouTubeTab()
                    end)
                elseif functionName == "youtube_stream" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.YouTubeStream:toggle()
                    end)
                elseif functionName == "voice_dictation.toggle" then
                    hs.hotkey.bind(modifiers, key, function()
                        spoon.VoiceDictation:toggleRecording()
                    end)
                elseif functionName == "vpn.toggle_globalprotect" then
                    hs.hotkey.bind(modifiers, key, function()
                        vpnGlobalProtect.toggle()
                    end)
                elseif functionName == "browser_search_selected" then
                    hs.hotkey.bind(modifiers, key, function()
                        yandexSearch.searchSelectedText()
                    end)
                elseif functionName == "musicapp.play_pause" then
                    hs.hotkey.bind(modifiers, key, function()
                        hs.itunes.playpause()
                    end)
                elseif functionName == "vscode.dotfiles" then
                    hs.hotkey.bind(modifiers, key, function()
                        local dotfilesPath = os.getenv("HOME") .. "/projects/dotfiles"
                        local vscode = hs.application.get("com.microsoft.VSCode")

                        if not vscode then
                            hs.execute("open -a 'Visual Studio Code' '" .. dotfilesPath .. "'", true)
                            return
                        end

                        local dotfilesWindow = nil
                        for _, window in ipairs(vscode:allWindows()) do
                            local title = window:title()
                            if title:find("dotfiles") or title:find("/projects/dotfiles") then
                                dotfilesWindow = window
                                break
                            end
                        end

                        if dotfilesWindow then
                            local isFrontmost = hs.application.frontmostApplication() == vscode
                            local isFocused = (hs.window.focusedWindow() == dotfilesWindow)

                            if isFrontmost and isFocused then
                                vscode:hide()
                            else
                                dotfilesWindow:focus()
                            end
                        else
                            hs.execute("open -a 'Visual Studio Code' '" .. dotfilesPath .. "'", true)
                        end
                    end)
                end
            end

            ::continue::
        end
    end

    print("DEBUG: Successfully bound " .. bindCount .. " hotkeys")
end

return obj
