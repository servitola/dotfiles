local rules = {}

-- Where a user's rule that raised is reported; a test replaces it.
rules.report = print

rules.SLOTS = {
    main = true, side = true, corner = true, stack = true, dialog = true,
}

function rules.normalize(value, source)
    if value == false then return false end
    if type(value) == "string" then
        assert(rules.SLOTS[value], "PowerWindows: unknown slot " .. value)
        return { slot = value, source = source }
    end
    local resolved = {}
    for key, field in pairs(value) do resolved[key] = field end
    assert(
        rules.SLOTS[resolved.slot],
        "PowerWindows: unknown slot " .. tostring(resolved.slot)
    )
    resolved.source = source
    return resolved
end

local function matches(entry, info)
    if entry[1] ~= "*" and entry[1] ~= info.bundle then return false end
    if entry.identifier and entry.identifier ~= info.identifier then
        return false
    end
    if entry.title and not info.title:find(entry.title) then return false end
    if entry.notTitle and info.title:find(entry.notTitle) then return false end
    if entry.maxTitle
        and (utf8.len(info.title) or #info.title) > entry.maxTitle then
        return false
    end
    if entry.maxSize
        and not (info.w < entry.maxSize[1] and info.h < entry.maxSize[2]) then
        return false
    end
    return true
end

function rules.lookup(entries, info)
    for _, entry in ipairs(entries) do
        if matches(entry, info) then
            if entry[2] == false then return false end
            return {
                slot = entry[2], keepAspect = entry.keepAspect,
                device = entry.device, popup = entry.popup, source = "catalog",
            }
        end
    end
    return nil
end

-- keepAspect and device windows have only these areas (ASPECT_AREA in
-- place.lua, geometry.devicePlace).
local FITTED = { main = true, side = true, corner = true, full = true }

-- The slot a window takes to another screen: where it sits now, else where it
-- belongs.
function rules.carrySlot(detected, resolved)
    if resolved.slot == "dialog" or resolved.slot == "stack" then
        return resolved.slot
    end
    if (resolved.keepAspect or resolved.device) and not FITTED[detected] then
        return resolved.slot
    end
    return detected or resolved.slot
end

function rules.isSmallDialog(dialogs, info)
    for _, entry in ipairs(dialogs) do
        if matches(entry, info) then return true end
    end
    return false
end

function rules.resolve(config, entries, dialogs, info, window)
    if config.rule then
        -- A rule that raises must not stop arrange all at this window.
        local answered, value = pcall(function()
            local answer = config.rule(window, info)
            if answer ~= nil then return rules.normalize(answer, "rule") end
        end)
        if not answered then
            rules.report("PowerWindows: rule: " .. tostring(value))
        elseif value ~= nil then
            return value
        end
    end
    local override = config.overrides and config.overrides[info.bundle]
    if override == false then return false end
    local found
    if config.catalog ~= false then found = rules.lookup(entries, info) end
    -- `false` beats the dialog detector; an override slot beats the catalog's
    -- false.
    if override == nil and found == false then return false end
    if config.dialogs ~= false and rules.isSmallDialog(dialogs, info) then
        return { slot = "dialog", source = "dialog" }
    end
    if override ~= nil then
        if type(override) == "string" and found and found.slot == override then
            found.source = "override"
            return found
        end
        return rules.normalize(override, "override")
    end
    if found ~= nil then return found end
    return { slot = "main", source = "default" }
end

return rules
