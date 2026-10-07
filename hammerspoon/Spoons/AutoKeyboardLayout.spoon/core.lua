-- Everything that needs no Hammerspoon: tested with plain `lua tests/run.lua`.
local core = {}

local function contains(list, value)
    for _, item in ipairs(list) do
        if item == value then return true end
    end
    return false
end

function core.resolve(bundle, config)
    local override = config.overrides[bundle]
    if override == false then return nil end
    if override then return override end
    if config.secondary and contains(config.secondaryApps, bundle) then return config.secondary end
    return config.primary
end

-- A value is tried as a layout name, then an input method name, then an input source id:
-- names are what System Settings shows, ids are what survives a system language change.
function core.kind(value, known)
    if contains(known.layouts, value) then return "layout" end
    if contains(known.methods, value) then return "method" end
    if contains(known.sources, value) then return "source" end
    return nil
end

local function check(value, where, known)
    if type(value) ~= "string" then
        error(where .. " must be a layout name or an input source id, got " .. type(value), 0)
    end
    if not core.kind(value, known) then
        local installed = {}
        for _, name in ipairs(known.layouts) do installed[#installed + 1] = name end
        for _, name in ipairs(known.methods) do installed[#installed + 1] = name end
        error(string.format('%s: "%s" is not installed. Installed: %s', where, value, table.concat(installed, ", ")), 0)
    end
end

function core.validate(config, known)
    if config.primary ~= nil then check(config.primary, "primary", known) end
    if config.secondary ~= nil then check(config.secondary, "secondary", known) end
    if type(config.secondaryApps) ~= "table" then
        error("secondaryApps must be a list of bundle ids, got " .. type(config.secondaryApps), 0)
    end
    for _, bundle in ipairs(config.secondaryApps) do
        if type(bundle) ~= "string" then error("secondaryApps: a bundle id is a string, got " .. type(bundle), 0) end
    end
    if type(config.overrides) ~= "table" then error("overrides must be a table, got " .. type(config.overrides), 0) end
    for bundle, value in pairs(config.overrides) do
        if type(bundle) ~= "string" then error("overrides: a key is an app's bundle id, got " .. type(bundle), 0) end
        if value ~= false then check(value, "overrides[" .. bundle .. "]", known) end
    end
end

return core
