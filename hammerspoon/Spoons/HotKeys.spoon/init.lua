local obj={}

-- Hyper is Caps Lock (⇪) remapped to Hyper in Karabiner-Elements

local layoutFiles = {
    "01. English",
    "02. Russian",
    "03. Greek",
    "04. English_Shift", -- ⇧
    "05. Russian_Shift", -- ⇧
    "06. Greek_Shift", -- ⇧
    "07. Alt", -- ⌥ (Ilya Birman's layout)
    "08. Alt_Shift", -- ⌥⇧ (Ilya Birman's layout)
    "09. Command", -- ⌘
    "10. Control", -- ⌃
    "11. Hyper", -- ⇪
    "12. Hyper_Alt", -- ⇪ ⌥
    "13. Hyper_Command", -- ⇪ ⌘
    "14. Hyper_Control", -- ⇪ ⌃
    "15. Hyper_Shift", -- ⇪ ⇧
    "16. Command_Shift", -- ⌘ ⇧
    "17. Command_Alt", -- ⌘ ⌥
    "18. Command_Conrol", -- ⌘ ⌃
    "19. Control_Shift", -- ⌃ ⇧
    "20. Control_Alt", -- ⌃ ⌥
    "21. Hyper_Alt_Command", -- ⇪ ⌥ ⌘
    "22. Hyper_Alt_Control", -- ⇪ ⌥ ⌃
    "23. Hyper_Alt_Shift", -- ⇪ ⌥ ⇧
    "24. Hyper_Control_Command", -- ⇪ ⌘ ⌃
    "25. Hyper_Command_Shift", -- ⇪ ⇧ ⌘
    "26. Hyper_Shift_Control", -- ⇪ ⇧ ⌃
    "27. Control_Alt_Command", -- ⌃ ⌥ ⌘
    "28. Shift_Control_Alt", -- ⌃ ⌥ ⇧
    "29. Shift_Control_Command", -- ⌃ ⇧ ⌘
    "30. Shift_Alt_Command" -- ⇧ ⌥ ⌘
}

hyper = { "right_command", "right_control", "right_option", "right_shift" }

-- Icons used:
--  — MacOS or common
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

-- next hotkey candidate:
-- control + y

local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")
local layoutsPath = spoonPath .. "layouts/"

layers_list = {}

for _, filename in ipairs(layoutFiles) do
    local filePath = layoutsPath .. filename .. ".lua"
    local _, layout = pcall(dofile, filePath)
    table.insert(layers_list, layout)
end

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

local appSpecificHotkeys = {
    ["Fork"] = {
        { from = {"cmd", "shift"}, key = "e", to = {"cmd", "shift"}, target_key = "l" },
        { from = {"cmd", "shift"}, key = "r", to = {"cmd", "shift"}, target_key = "p" },
        { from = {"control"}, key = "q", to = {"cmd", "alt"}, target_key = "1"},
        { from = {"control"}, key = "w", to = {"cmd", "alt"}, target_key = "2"},
        { from = {"control"}, key = "e", to = {"cmd", "alt"}, target_key = "3"}
    },
    ["Music"] = {
        { from = {"cmd"}, key = "e", to = {"cmd"}, target_key = "l" },
    },
    ["Telegram"] = {
        { from = {"control"}, key = "q", to = {"cmd"}, target_key = "0"}
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

    for _, layer in pairs(layers_list) do
        if layer.chords then
            for _, chord_row in pairs(layer.chords) do
                if chord_row.app then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()

                        print("Hotkey triggered: " .. table.concat(layer.modifier, "+") .. "+" .. chord_row.key .. " → " .. chord_row.app)

                        local app
                        if chord_row.app == "Visual Studio Code" then
                            app = hs.application.get("com.microsoft.VSCode")
                        else
                            local found = hs.application.find(chord_row.app)
                            app = found
                            if found and tostring(found):match("hs.window:") then
                                app = found:application()
                                print("Found window, getting application: " .. tostring(app))
                            end
                        end

                        if not app or (app and app.isHidden and app:isHidden()) then
                            print("Launching/focusing app: " .. chord_row.app)
                            hs.application.launchOrFocus(chord_row.app)
                        elseif hs.application.frontmostApplication() ~= app then
                            print("Activating app: " .. chord_row.app)
                            if app and app.activate then
                                hs.application.launchOrFocus(chord_row.app)
                            end
                        else
                            print("Hiding app: " .. chord_row.app)
                            if app and app.hide then
                                app:hide()
                            end
                        end
                    end)
                    if chord_row.window_default_position then
                        if chord_row.window_default_position == "right" then
                            spoon.Windows:add_right_window_type_app(chord_row.app)
                        elseif chord_row.window_default_position == "bottom" then
                            spoon.Windows:add_bottom_window_type_app(chord_row.app)
                        end
                    end
                elseif chord_row.sendKey then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        hs.eventtap.keyStrokes(chord_row.sendKey)
                    end)
                elseif chord_row.specific_function then
                    if chord_row.specific_function == "window.left" then
                        spoon.Windows:bind_window_left(layer.modifier, chord_row.key)
                    elseif chord_row.specific_function == "window.right" then
                        spoon.Windows:bind_window_right(layer.modifier, chord_row.key)
                    elseif chord_row.specific_function == "window.fullscreen" then
                        spoon.Windows:bind_window_fullscreen(layer.modifier, chord_row.key)
                    elseif chord_row.specific_function == "window.set_all_to_default" then
                        spoon.Windows:bind_all_windows_to_default(layer.modifier, chord_row.key)
                    elseif chord_row.specific_function == "android.show_all" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            for _, window in ipairs(hs.window.allWindows()) do
                                local window_title = window:title()
                                local app_title = window:application():title()
                                for _, app in ipairs(chord_row.layers_list) do
                                    if app_title == app or string.find(window_title, app) then
                                        window:focus()
                                    end
                                end
                            end
                        end)
                    elseif chord_row.specific_function == "info.show_shortcuts" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            if ksheet then
                                spoon.KSheet:hide()
                            else
                                hideKSheetShortCut:enable();
                                spoon.KSheet:show()
                            end

                            ksheet = not ksheet
                        end)
                    elseif chord_row.specific_function == "set_russian_language" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            hs.keycodes.setLayout("Russian – Ilya Birman Typography")
                        end)
                    elseif chord_row.specific_function == "set_english_language" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            hs.keycodes.setLayout("English - Ilya Birman Typography")
                        end)
                    elseif chord_row.specific_function == "translate_to_russian" then
                        spoon.PopupTranslateSelection:bindHotkeys({
                            translate_to_ru = {layer.modifier, chord_row.key},
                        })
                    elseif chord_row.specific_function == "translate_to_english" then
                        spoon.PopupTranslateSelection:bindHotkeys({
                            translate_to_en = {layer.modifier, chord_row.key},
                        })
                    elseif chord_row.specific_function == "translate_to_greek" then
                        spoon.PopupTranslateSelection:bindHotkeys({
                            translate_to_el = {layer.modifier, chord_row.key},
                        })
                    elseif chord_row.specific_function == "audio.internal" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.AudioSwitcher:switchToInternal()
                        end)
                    elseif chord_row.specific_function == "audio.external" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.AudioSwitcher:switchToExternal()
                        end)
                    elseif chord_row.specific_function == "audio.marshall" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.AudioSwitcher:switchToMarshall()
                        end)
                    elseif chord_row.specific_function == "audio.bt" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.AudioSwitcher:switchToBT()
                        end)
                    elseif chord_row.specific_function == "show_youtrack" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.YouTrackTicket:toggle()
                        end)
                    elseif chord_row.specific_function == "show_youtrack_tasks" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.YouTrackTasks:toggle()
                        end)
                    elseif chord_row.specific_function == "browser_git" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.BrowserTabOpener:openTab("github.com")
                        end)
                    elseif chord_row.specific_function == "press_return" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            hs.eventtap.keyStroke({}, "return")
                        end)
                    elseif chord_row.specific_function == "browser_youtube" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.BrowserTabOpener:openTab("youtube.com")
                        end)
                    elseif chord_row.specific_function == "youtube_stream" then
                        hs.hotkey.bind(layer.modifier, chord_row.key, function()
                            spoon.YouTubeStream:toggle()
                        end)
                    end
                end
            end
        end
    end
end

return obj
