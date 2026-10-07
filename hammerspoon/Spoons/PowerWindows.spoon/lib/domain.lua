-- The domain: what is done to windows (lib/window) and what runs on top of
-- that (lib/features). Each part adds methods to powerWindows and calls the
-- others through self, so only query, which the others receive, must come
-- first.
local here = hs.spoons.scriptPath()
local function load(name) return dofile(here .. name .. ".lua") end

return function(powerWindows, core)
    local geometry, rules, settings = core.geometry, core.rules, core.settings
    local domain = {}

    domain.query = load("window/query")(powerWindows, settings)
    local query = domain.query
    load("window/timers")(powerWindows)
    load("window/place")(powerWindows, geometry, query)
    load("window/stack")(powerWindows, geometry, query)
    load("window/actions")(powerWindows, geometry, query)
    load("window/minimize")(powerWindows, query)

    load("features/hotkeys")(powerWindows, settings.ACTIONS)
    load("features/globe")(powerWindows, settings)
    load("features/screens")(powerWindows, geometry, rules, query)
    load("features/launch")(powerWindows, geometry)
    domain.focusSets = load("features/focus")(powerWindows, core.catalog)

    function domain.validate(config)
        settings.validate(config, settings.ACTIONS, hs.keycodes.map)
        -- An unknown slot would otherwise surface only when a window of that
        -- app is placed.
        for _, value in pairs(config.overrides) do
            rules.normalize(value, "override")
        end
    end

    return domain
end
