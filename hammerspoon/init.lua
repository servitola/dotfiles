require "constants";
require "capslock";

hs.loadSpoon("window")

spoon.window:bindWindowsHotkeys({
    up = {{"left_control", "left_option"}, "up"},
    right = {{"left_control", "left_option"}, "right"},
    down = {{"left_control", "left_option"}, "down"},
    left = {{"left_control", "left_option"}, "left"}
})

-- 

-- --data = hs.json.read("../data/data.json")

-- --hs.logger:w("test")