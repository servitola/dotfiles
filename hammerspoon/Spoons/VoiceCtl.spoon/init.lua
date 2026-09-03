-- VoiceCtl — single point of control for the Mac from the voice topic.
-- All the smarts live here, so the model has only one step left:
-- pick a verb and pass the raw phrase.
local obj = {}
obj.dry = false

local log = hs.logger.new('VoiceCtl', 'info')
local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")

obj.resolve = dofile(spoonPath .. "resolve.lua")

local ALIASES_PATH = os.getenv("HOME") ..
    "/projects/dotfiles/claude-code/detached_skills/voice-mac/aliases.json"

local function loadAliases()
    local f = io.open(ALIASES_PATH, "r")
    if not f then return {} end
    local raw = f:read("a"); f:close()
    local ok, data = pcall(hs.json.decode, raw)
    return ok and data or {}
end

obj.aliases = {}
obj._verbs = {}

function obj:register(verb, fn)
    self._verbs[verb] = fn
end

-- App candidates: bundleID map from HotKeys (authoritative names),
-- plus running apps, plus installed apps. 60s cache — enumerating /Applications
-- costs tens of milliseconds, and that's noticeable on the hot path.
local appCache, appCacheAt = nil, 0

function obj:appCandidates()
    local now = os.time()
    if appCache and (now - appCacheAt) < 60 then return appCache end

    local byKey = {}
    local function add(name, bundleID)
        if not name or name == "" then return end
        local entry = byKey[name]
        if not entry then
            entry = { key = name, aliases = { name }, value = bundleID }
            byKey[name] = entry
        elseif bundleID and not entry.value then
            entry.value = bundleID
        end
    end

    local okIds, ids = pcall(dofile,
        os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/HotKeys.spoon/app_bundle_ids.lua")
    if okIds and type(ids) == "table" then
        for name, bundleID in pairs(ids) do add(name, bundleID) end
    end

    for _, app in ipairs(hs.application.runningApplications()) do
        local name = app:name()
        if name then add(name, app:bundleID()) end
    end

    for _, dir in ipairs({ "/Applications", os.getenv("HOME") .. "/Applications" }) do
        -- hs.fs.dir returns an iterator AND a state object. Assigning only
        -- the first value breaks it: generic-for is left without state and crashes.
        if hs.fs.attributes(dir, "mode") == "directory" then
            for entry in hs.fs.dir(dir) do
                local name = entry:match("^(.*)%.app$")
                if name then add(name, nil) end
            end
        end
    end

    -- Personal app aliases layered on top: «код» → Visual Studio Code.
    for name, list in pairs(self.aliases.apps or {}) do
        local entry = byKey[name]
        if entry then
            for _, alias in ipairs(list) do entry.aliases[#entry.aliases + 1] = alias end
        end
    end

    appCache = {}
    for _, entry in pairs(byKey) do appCache[#appCache + 1] = entry end
    appCacheAt = now
    return appCache
end

-- The single entry point. Returns exactly one string.
function obj:run(verb, phrase)
    local fn = self._verbs[verb]
    if not fn then
        local known = {}
        for name in pairs(self._verbs) do known[#known + 1] = name end
        table.sort(known)
        return "ERR unknown verb '" .. tostring(verb) .. "'; known: " .. table.concat(known, " ")
    end

    local ctx = { resolve = self.resolve, aliases = self.aliases, dry = self.dry, spoon = self }
    local ok, result = pcall(fn, phrase or "", ctx)
    if not ok then
        log.e(verb .. ": " .. tostring(result))
        return "ERR " .. tostring(result):gsub("%s+", " ")
    end
    return tostring(result)
end

-- Helper for verbs: resolve the target or return a ready-made response string.
-- Returns entry, nil on success, or nil, "AMBIGUOUS ..."/"NOTFOUND ..." otherwise.
function obj:resolveOr(verb, phrase, candidates)
    local best, top = self.resolve.pick(phrase, candidates)
    if not best then
        return nil, "NOTFOUND " .. verb .. ": " .. phrase
    end
    if not best.confident then
        local names = {}
        for _, c in ipairs(top) do names[#names + 1] = c.key .. "(" .. c.score .. ")" end
        return best, "AMBIGUOUS " .. table.concat(names, " | ")
    end
    return best, nil
end

function obj:init()
    self.aliases = loadAliases()
    dofile(spoonPath .. "verbs_app.lua")(self)
    dofile(spoonPath .. "verbs_win.lua")(self)
    dofile(spoonPath .. "verbs_media.lua")(self)
    dofile(spoonPath .. "verbs_web.lua")(self)
    dofile(spoonPath .. "verbs_sys.lua")(self)
    return self
end

return obj
