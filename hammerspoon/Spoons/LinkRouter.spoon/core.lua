-- Everything that needs no Hammerspoon: tested with plain `lua tests/run.lua`.
local core = {}

local BUNDLE = "^[%w%-]+%.[%w%.%-]+$"

-- Lua patterns, not regular expressions: the scheme and host are matched as written.
core.localNetwork = {
    "^https?://localhost[:/]", "^https?://localhost$",
    "^https?://127%.%d+%.%d+%.%d+",
    "^https?://0%.0%.0%.0[:/]",
    "^https?://10%.%d+%.%d+%.%d+",
    "^https?://192%.168%.%d+%.%d+",
    "^https?://172%.1[6-9]%.%d+%.%d+", "^https?://172%.2%d%.%d+%.%d+", "^https?://172%.3[01]%.%d+%.%d+",
    "^https?://[%w%-%.]+%.local[:/]",
}

function core.unescape(text)
    return (text:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end))
end

function core.slackRedirect(url)
    local target = url:match("^https://slack%.redir%.net/.*[?&]url=([^&]+)")
    return target and core.unescape(target)
end

local function list(value)
    return type(value) == "table" and value or { value }
end

local function target(value, browsers, where)
    if type(value) == "function" then return value end
    if type(value) ~= "string" or value == "" then
        error(where .. ": open with a browser name, a bundle id or a function, got " .. tostring(value), 0)
    end
    if browsers[value] then return browsers[value] end
    if value:match(BUNDLE) then return value end
    error(where .. ": \"" .. value .. "\" is neither a name in `browsers` nor a bundle id", 0)
end

local function matcher(value, where)
    if type(value) == "function" then return value end
    local patterns = list(value)
    if #patterns == 0 then error(where .. ": an empty pattern list matches nothing", 0) end
    for _, pattern in ipairs(patterns) do
        if type(pattern) ~= "string" or pattern == "" then
            error(where .. ": a pattern must be a non-empty string, got " .. tostring(pattern), 0)
        end
        local ok, problem = pcall(string.find, "", pattern)
        if not ok then error(where .. ": bad Lua pattern \"" .. pattern .. "\": " .. problem, 0) end
    end
    return function(url)
        for _, pattern in ipairs(patterns) do
            if url:find(pattern) then return true end
        end
        return false
    end
end

local RULE_KEYS = { [1] = true, [2] = true, from = true }

-- Turns the user's settings into checked, ready-to-run rules, or fails with the rule's
-- number in the message: a typo must stop the load, not silently send links elsewhere.
function core.compile(settings)
    local browsers = settings.browsers or {}
    for name, bundle in pairs(browsers) do
        if type(name) ~= "string" or type(bundle) ~= "string" or not bundle:match(BUNDLE) then
            error("browsers." .. tostring(name) .. ": must be a bundle id, got " .. tostring(bundle), 0)
        end
    end
    local compiled = { default = target(settings.default, browsers, "default"), rules = {}, unwrap = {} }
    for index, rule in ipairs(settings.rules or {}) do
        local where = "rules[" .. index .. "]"
        if type(rule) ~= "table" then error(where .. ": must be a table { match, open }", 0) end
        for key in pairs(rule) do
            if not RULE_KEYS[key] then error(where .. ": unknown field \"" .. tostring(key) .. "\"", 0) end
        end
        local from = nil
        if rule.from ~= nil then
            from = {}
            for _, bundle in ipairs(list(rule.from)) do
                if type(bundle) ~= "string" or not bundle:match(BUNDLE) then
                    error(where .. ".from: must be a bundle id or a list of them, got " .. tostring(bundle), 0)
                end
                from[bundle] = true
            end
        end
        compiled.rules[index] = { match = matcher(rule[1], where), open = target(rule[2], browsers, where), from = from }
    end
    for index, unwrap in ipairs(settings.unwrap or {}) do
        if type(unwrap) ~= "function" then error("unwrap[" .. index .. "]: must be a function(url) -> url or nil", 0) end
        compiled.unwrap[index] = unwrap
    end
    return compiled
end

-- Returns the url to open (after unwrapping) and where: a bundle id or a function, plus
-- the number of the rule that decided, or nil when the default did.
function core.route(compiled, url, sender)
    for _, unwrap in ipairs(compiled.unwrap) do
        url = unwrap(url) or url
    end
    for index, rule in ipairs(compiled.rules) do
        if (not rule.from or (sender and rule.from[sender])) and rule.match(url, sender) then
            return url, rule.open, index
        end
    end
    return url, compiled.default, nil
end

return core
