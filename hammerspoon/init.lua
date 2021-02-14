hs.loadSpoon("window")
hs.window.animationDuration = 0.08

spoon.window:bindWindowsHotkeys({
    up = {{"left_control", "left_option"}, "up"},
    right = {{"left_control", "left_option"}, "right"},
    down = {{"left_control", "left_option"}, "down"},
    left = {{"left_control", "left_option"}, "left"}
})

require "hotkeys";