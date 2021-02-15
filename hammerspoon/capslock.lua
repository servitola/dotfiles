local hyper = {
    "right_command", 
    "right_control", 
    "right_option", 
    "right_shift"}
local hyperAndShift = {
    "left_shift", 
    "right_command", 
    "right_control", 
    "right_option", 
    "right_shift"}

-- \ ???
-- 1 F1
-- 2 F2
-- 3 F3
-- 4 F4
-- 5 F5
-- 6 F6
-- 7 F7
-- 8 F8
-- 9 F9
-- 0 F10
-- - F11
-- = F12
-- delete F13
-- Q page-up
-- W arrow-up
-- E page-down
hs.hotkey.bind(hyper, "r", function() openApp("Rider") end)
hs.hotkey.bind(hyper, "t", function() openApp("Telegram") end)
hs.hotkey.bind(hyper, "y", function() openApp("Yandex") end)
hs.hotkey.bind(hyper, "u", function() openApp("Folx") end)
-- I ???
-- O arrow-up
hs.hotkey.bind(hyper, "p", function() openApp("Music") end)
hs.hotkey.bind(hyper, '[', function() hs.itunes.previous() end)
hs.hotkey.bind(hyper, ']', function() hs.itunes.next() end)
-- \ ???
-- Enter ???
-- A arrow-left
hs.hotkey.bind(hyperAndShift, "a", function() openApp("Android Studio") end)
-- S arrow-bottom
-- D arrow-right
-- F Alfred
hs.hotkey.bind(hyper, "g", function() openApp("Fork") end)
hs.hotkey.bind(hyper, "h", function() openApp("Finder") end)
hs.hotkey.bind(hyper, "j", function() openApp("Safari") end)
-- K arrow-left
-- L arrow-bottom
-- ; arrow-right
-- ' ???
-- Z Punto Switcher
-- X home
-- C end
hs.hotkey.bind(hyper, "v", function() openApp("iTerm") end)
-- B ???
hs.hotkey.bind(hyper, "n", function() openApp("Visual Studio Code") end)
hs.hotkey.bind(hyper, "m", function() openApp("YouTube") end)
-- , ???
-- . ???
-- / ???
hs.hotkey.bind(hyper, 'space', function() hs.itunes.playpause() end)

function openApp(name)
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