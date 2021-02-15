hs.loadSpoon("window")
hs.window.animationDuration = 0.08

local hyper = {
    "right_command", 
    "right_control", 
    "right_option", 
    "right_shift"}

spoon.window:bindWindowsHotkeys({
    up = {hyper, "up"},
    right = {hyper, "right"},
    down = {hyper, "down"},
    left = {hyper, "left"}
})

require "capslock";

data = hs.json.read("../data/data.json")

--hs.logger:w("test")