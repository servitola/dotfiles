-- Explicit list: Hammerspoon has no portable readdir, and a grep for a module
-- name should land here.
local register = function(name, fn) spoon.HotKeys:register(name, fn) end

for _, mod in ipairs({ "apps", "audio", "browser", "display", "media", "system", "translate" }) do
    require("actions." .. mod)(register)
end
require("actions.window_sets").register(register)
