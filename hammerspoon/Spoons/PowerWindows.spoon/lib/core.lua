-- The core: geometry, rules, settings and the catalog (lib/core, pure Lua
-- with no Hammerspoon in it) and the config tables init.lua hands over.
local here = hs.spoons.scriptPath() .. "core/"
local function load(name) return dofile(here .. name .. ".lua") end

return function(config)
    return {
        geometry = load("geometry"),
        rules = load("rules"),
        settings = load("settings"),
        catalog = load("catalog")(config.catalog),
        dialogs = config.dialogs,
        defaults = config.settings,
    }
end
