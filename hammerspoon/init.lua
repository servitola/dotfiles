require "constants";
require "capslock";

hs.loadSpoon("window")

spoon.window:bindWindowsHotkeys({
    up = {"right_option", "up"},
    right = {"right_option", "right"},
    down = {"right_option", "down"},
    left = {"right_option", "left"}
})

-- 

-- --data = hs.json.read("../data/data.json")

-- --hs.logger:w("test")
