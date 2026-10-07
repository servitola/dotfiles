local settings = {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, field in pairs(value) do result[key] = copy(field) end
    return result
end

-- Empty table = map, so `overrides = {}` merges.
local function isMap(value)
    return type(value) == "table" and value[1] == nil
end

settings.copy = copy

settings.ACTIONS = {}
for _, name in ipairs({
    "left", "right", "fullscreen", "arrangeAll", "halfLeft", "halfRight",
    "top60", "bottom40", "center", "swapSides", "minimizeAndFocusNext",
    "minimizeCurrent",
}) do settings.ACTIONS[name] = true end

-- keyCode → action, keyCode → true when the key needs the tracked Globe press;
-- macOS itself puts the fn flag on arrows and other named keys, never on a
-- character.
function settings.macosKeys(value, actions, keycodes)
    if not value then return nil end
    local byCode, needsGlobe = {}, {}
    for key, action in pairs(value) do
        if action ~= false then
            if not actions[action] then
                error(
                    "PowerWindows: macosKeys." .. tostring(key)
                        .. ": unknown action '" .. tostring(action) .. "'",
                    0
                )
            end
            local code = keycodes[key]
                or error(
                    "PowerWindows: macosKeys: unknown key '"
                        .. tostring(key) .. "'",
                    0
                )
            byCode[code] = action
            if #key > 1 then needsGlobe[code] = true end
        end
    end
    return byCode, needsGlobe
end

local KEY_TABLES = { "arrows", "shiftedArrows", "letters", "shiftedLetters" }

-- What merge cannot see: action names, key names, launch options. Raises with
-- no position, since it runs both in configure and in start.
function settings.validate(config, actions, keycodes)
    settings.macosKeys(config.macosKeys, actions, keycodes)
    for _, group in ipairs(KEY_TABLES) do
        for action, key in pairs(config.keys[group]) do
            local path = "keys." .. group .. "." .. tostring(action)
            if not actions[action] then
                error("PowerWindows: " .. path .. ": unknown action", 0)
            end
            if type(key) ~= "string" then
                error("PowerWindows: " .. path .. ": key must be a string", 0)
            end
        end
    end
    local launch = config.experimental.placeOnLaunch
    if launch and type(launch.bundles) ~= "table" then
        error(
            "PowerWindows: experimental.placeOnLaunch.bundles must be a list \z
             of bundle IDs",
            0
        )
    end
end

local PROFILE_KEYS = {
    gap = true, split = true, sideHeight = true, topShare = true, device = true,
    dialog = true,
}
-- Width over height: 21:9 is 2.33, 16:9 is 1.78.
local ULTRAWIDE = 2.1

local function unknown(path)
    return "unknown setting '" .. path .. "' (see config/settings.lua)"
end

-- Closed maps take only the keys of their defaults; open ones are keyed by
-- bundle, screen or name.
local CLOSED_MAPS = { device = true, dialog = true, keys = true }
local OPEN_MAPS = {
    overrides = true, screens = true, focusSets = true, experimental = true,
}

local SWITCHES = {
    hotkeys = true, wasd = true, cycle = true, catalog = true, dialogs = true,
    rearrangeOnScreenChange = true,
}

local function checkValue(current, value, path, name)
    if current == nil then return unknown(path) end
    if type(current) == "number" and type(value) ~= "number" then
        return "setting '" .. path .. "' must be a number"
    end
    -- 0 is true in Lua: `cycle = 0` would turn it on.
    if SWITCHES[name] and type(value) ~= "boolean" then
        return "setting '" .. path .. "' must be true or false"
    end
    if (CLOSED_MAPS[name] or OPEN_MAPS[name]) and not isMap(value) then
        return "setting '" .. path .. "' must be a table"
    end
    if CLOSED_MAPS[name] then
        for key, field in pairs(value) do
            local problem = checkValue(
                current[key], field, path .. "." .. tostring(key)
            )
            if problem then return problem end
        end
    end
end

local function checkProfiles(current, screens)
    for name, profile in pairs(screens) do
        local prefix = "screens." .. tostring(name)
        if type(profile) ~= "table" then return prefix .. " must be a table" end
        for key, value in pairs(profile) do
            local path = prefix .. "." .. tostring(key)
            if not PROFILE_KEYS[key] then return unknown(path) end
            local problem = checkValue(current[key], value, path, key)
            if problem then return problem end
        end
    end
end

local function check(current, changes)
    for key, value in pairs(changes) do
        local problem = checkValue(current[key], value, tostring(key), key)
            or (key == "screens" and checkProfiles(current, value))
        if problem then return problem end
    end
end

local function overlay(base, top)
    local result = {}
    for key, value in pairs(base) do result[key] = value end
    for key, value in pairs(top) do result[key] = value end
    return result
end

-- Checks everything before changing anything; level 3 points the error at the
-- configure call.
function settings.merge(current, changes)
    local problem = check(current, changes)
    if problem then error("PowerWindows: " .. problem, 3) end
    for key, value in pairs(changes) do
        if isMap(current[key]) and isMap(value) then
            for innerKey, innerValue in pairs(value) do
                current[key][innerKey] = innerValue
            end
        else
            current[key] = value
        end
    end
    return current
end

-- screen = { name, w, h }. Name beats shape; one profile, merged over the base
-- one level deep.
function settings.forScreen(config, screen)
    local screens = config.screens
    local profile = screens[screen.name]
        or (screen.h > screen.w and screens.portrait)
        or (screen.w / screen.h >= ULTRAWIDE and screens.ultrawide)
    if not profile then return config end
    local result = overlay(config, {})
    for key, value in pairs(profile) do
        result[key] = (isMap(config[key]) and isMap(value))
            and overlay(config[key], value) or value
    end
    return result
end

return settings
