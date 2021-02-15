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

spoon.window:bindHotkey({ chord = {hyper, "t"}, appname = "Telegram"})
spoon.window:bindHotkey({ chord = {hyper, "r"}, appname = "Rider"})
spoon.window:bindHotkey({ chord = {hyper, "y"}, appname = "Yandex"})
spoon.window:bindHotkey({ chord = {hyper, "g"}, appname = "Fork"})
spoon.window:bindHotkey({ chord = {hyper, "j"}, appname = "Safari"})
spoon.window:bindHotkey({ chord = {hyper, "v"}, appname = "iTerm"})
spoon.window:bindHotkey({ chord = {hyper, "n"}, appname = "Visual Studio Code"})
spoon.window:bindHotkey({ chord = {hyper, "p"}, appname = "Music"})
hs.hotkey.bind(hyper, 'space', function() hs.itunes.playpause() end)
hs.hotkey.bind(hyper, '[', function() hs.itunes.previous() end)
hs.hotkey.bind(hyper, ']', function() hs.itunes.next() end)