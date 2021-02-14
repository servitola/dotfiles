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

spoon.WindowsManager:bindHotkey({ chord = {hyper, "t"}, appname = "Telegram"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "r"}, appname = "Rider"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "y"}, appname = "Yandex"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "f"}, appname = "Alfred"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "g"}, appname = "Fork"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "j"}, appname = "Safari"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "v"}, appname = "iTerm"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "n"}, appname = "Visual Studio Code"})
spoon.WindowsManager:bindHotkey({ chord = {hyper, "p"}, appname = "Music"})
hs.hotkey.bind(hyper, 'space', function() hs.itunes.playpause() end)
hs.hotkey.bind(hyper, '[', function() hs.itunes.previous() end)
hs.hotkey.bind(hyper, ']', function() hs.itunes.next() end)