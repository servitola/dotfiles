--- === BirmanLayer ===
---
--- Ilya Birman's typography layout on the right Option key, over whatever keyboard layouts you use
--- (unofficial: not Ilya Birman's layout and not affiliated with him)
---
--- The ⌥ layers are positional and a dead key composes by the character the next key types, so it works
--- on any layout; only the opt-in `baseFixups` names layouts. The layout is Ilya Birman's work,
--- https://ilyabirman.ru/typography-layout/

local obj = {}
obj.__index = obj

obj.name = "BirmanLayer"
obj.version = "3.9.1"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/BirmanLayer.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local TABLE = dofile(hs.spoons.resourcePath("typography_table.lua"))

--- BirmanLayer.overrides
--- Variable
--- Changes to Birman's table, keyed by `"*"` (every input source) or one input source id as
--- `hs.keycodes.currentSourceID()` prints it. Same shape as the Spoon's own table, merged over it:
--- `{ keys = { g = { opt = "©" } }, dead = { acute = { compose = { ["ы"] = "ы́" } } } }`.
--- A cell is text, `{ dead = "acute" }`, `false` (types nothing) or `{ pass = true }` (Apple's own).
--- See docs/configuration.md. Defaults to `{}`. Read by `BirmanLayer:start()`.
obj.overrides = {}

--- BirmanLayer.baseFixups
--- Variable
--- Type Birman's plain and Shift characters on the few keys where Apple's ABC and Russian – PC differ
--- from him (ISO keyboards only). Defaults to `false`. Read by `BirmanLayer:start()`.
obj.baseFixups = false

--- BirmanLayer.rightOptionOnly
--- Variable
--- `true`: the layer sits on the right ⌥ only, like AltGr on Windows, and the left ⌥ stays Apple's.
--- `false`: on both ⌥ keys, as in Birman's Mac layout. Defaults to `true`. Read by `BirmanLayer:start()`.
obj.rightOptionOnly = true

--- BirmanLayer.excludedBundles
--- Variable
--- List of application bundle IDs in which the layer stays silent (games, virtual machines,
--- remote desktops — anything that reads key codes instead of text). Defaults to `{}`.
--- Read by `BirmanLayer:start()`.
obj.excludedBundles = {}

--- BirmanLayer.excludedLayouts
--- Variable
--- List of input source IDs, as `hs.keycodes.currentSourceID()` reports them, in which the layer stays out
--- and the Option keys keep that layout's own ⌥ layer, e.g. `{ "com.apple.keylayout.Greek" }` for Apple's
--- Greek tonos letters and symbols. Defaults to `{}`. Read by `BirmanLayer:start()`.
obj.excludedLayouts = {}

--- BirmanLayer.deadKeyTimeout
--- Variable
--- Seconds a dead key waits for the next key before it is dropped silently. Defaults to `3`.
--- Read by `BirmanLayer:start()`.
obj.deadKeyTimeout = 3

--- BirmanLayer.logger
--- Variable
--- Logger object used within the Spoon. Can be accessed to set the default log level for the
--- messages coming from the Spoon.
obj.logger = hs.logger.new("BirmanLayer")

local RIGHT_ALT, LEFT_ALT = 0x40, 0x20
-- Right ⌘/⌃ belong to a Caps-Lock Hyper; left ⌘/⌃ make a shortcut.
local BLOCKERS = 0x10 | 0x2000 | 0x08 | 0x01
local SHIFTS = 0x02 | 0x04
local ESCAPE = 53
-- "RALT" in ASCII; tags the layer's own posted events.
local MARK = 0x52414C54
local props = hs.eventtap.event.properties

local tap, watcher, dead, excluded
local overrides, latinTable, cyrillicTable, perSource, fixupCodes = {}, nil, nil, {}, {}
local excludedSet, excludedSources, deadTimeout, fixupsOn, rightOnly = {}, {}, 3e9, false, true

local function layerKey(flags)
    if rightOnly then return flags & RIGHT_ALT ~= 0 and flags & LEFT_ALT == 0 end
    return flags & (RIGHT_ALT | LEFT_ALT) ~= 0
end

function obj._currentSource() return hs.keycodes.currentSourceID() end

-- His Russian tables apply to any layout whose first letter key (kVK 0) types Cyrillic.
function obj._typesCyrillic()
    local char = hs.eventtap.event.newKeyEvent(0, true):getCharacters()
    if not char or char == "" then return false end
    local codepoint = utf8.codepoint(char, 1, 1, true)
    return codepoint >= 0x400 and codepoint <= 0x4FF
end
function obj._now() return hs.timer.absoluteTime() end

function obj._frontBundle()
    local app = hs.application.frontmostApplication()
    return app and app:bundleID()
end

local function post(event)
    event:setProperty(props.eventSourceUserData, MARK):post()
end

function obj._emit(text)
    for _, isDown in ipairs({ true, false }) do
        post(hs.eventtap.event.newKeyEvent(0, isDown):setFlags({}):setUnicodeString(text))
    end
end

function obj._forward(event) post(event:copy()) end

local function isLeaf(value)
    return type(value) ~= "table" or type(value.dead) == "string" or value.pass == true
end

local function copy(value)
    if isLeaf(value) then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = copy(v) end
    return out
end

local function merge(into, from)
    for k, v in pairs(from) do
        if type(into[k]) == "table" and not isLeaf(into[k]) and not isLeaf(v) then
            merge(into[k], v)
        else
            into[k] = copy(v)
        end
    end
end

local function withOverlay(overlay)
    local t = copy(TABLE)
    t.cyrillic = nil
    if overlay then merge(t, overlay) end
    return t
end

latinTable, cyrillicTable = withOverlay(), withOverlay(TABLE.cyrillic)

-- Key names are QWERTY positions, as in the picture, whatever layout is active.
local KEY_CODES = {
    a = 0, s = 1, d = 2, f = 3, h = 4, g = 5, z = 6, x = 7, c = 8, v = 9, section = 10, b = 11, q = 12, w = 13,
    e = 14, r = 15, y = 16, t = 17, ["1"] = 18, ["2"] = 19, ["3"] = 20, ["4"] = 21, ["6"] = 22, ["5"] = 23,
    ["="] = 24, ["9"] = 25, ["7"] = 26, ["-"] = 27, ["8"] = 28, ["0"] = 29, ["]"] = 30, o = 31, u = 32,
    ["["] = 33, i = 34, p = 35, l = 37, j = 38, ["'"] = 39, k = 40, [";"] = 41, ["\\"] = 42, [","] = 43,
    ["/"] = 44, n = 45, m = 46, ["."] = 47, space = 49, ["`"] = 50,
}

local function keyCode(name, where)
    if type(name) == "number" then return name end
    local code = KEY_CODES[name]
    if not code then error(("BirmanLayer.overrides%s: no key named %q"):format(where, tostring(name)), 0) end
    return code
end

local function codeKeyed(rows, where)
    local out = {}
    for name, row in pairs(rows) do out[keyCode(name, where)] = row end
    return out
end

local function normalize(t, source)
    if t.keys then t.keys = codeKeyed(t.keys, "[" .. source .. "].keys") end
    for id, rows in pairs(t.fixups or {}) do t.fixups[id] = codeKeyed(rows, "[" .. source .. "].fixups") end
    for state, body in pairs(t.dead or {}) do
        if body.keys then body.keys = codeKeyed(body.keys, "[" .. source .. "].dead." .. state .. ".keys") end
    end
    return t
end

local function collectFixupCodes(t)
    for _, rows in pairs(t.fixups or {}) do
        for code in pairs(rows) do fixupCodes[code] = true end
    end
end

local function tableFor(source)
    local key = source or ""
    local t = perSource[key]
    if not t then
        t = obj._typesCyrillic() and cyrillicTable or latinTable
        if overrides[key] then
            t = copy(t)
            merge(t, overrides[key])
        end
        perSource[key] = t
    end
    return t
end

local function clear() dead = nil end

local function enter(state)
    dead = { state = state, deadline = obj._now() + deadTimeout }
end

local function expire()
    if dead and obj._now() > dead.deadline then clear() end
end

local function produce(out)
    if type(out) == "table" then enter(out.dead) elseif out then obj._emit(out) end
end

local function layer(flags, code, shift, repeating)
    if not layerKey(flags) or flags & BLOCKERS ~= 0 then return false end
    local source = obj._currentSource()
    if excludedSources[source or ""] then return false end
    local row = tableFor(source).keys[code]
    local out = row and row[shift and "shift_opt" or "opt"]
    if out == nil or (type(out) == "table" and out.pass) then return false end
    -- A held dead key must not re-enter its state on every repeat.
    if not (repeating and type(out) == "table") then produce(out) end
    return true
end

local function fixup(flags, code, shift)
    if not (fixupsOn and fixupCodes[code]) or flags & (RIGHT_ALT | LEFT_ALT | BLOCKERS) ~= 0 then return false end
    local source = obj._currentSource()
    if excludedSources[source or ""] then return false end
    local rows = tableFor(source).fixups[source]
    local out = rows and rows[code] and rows[code][shift and "shift" or "base"]
    if out == nil then return false end
    produce(out)
    return true
end

local function insideDead(event, flags, code, shift)
    local source = obj._currentSource()
    local t = tableFor(source)
    local body, state = t.dead[dead.state], dead.state
    clear()
    if excludedSources[source or ""] then return false end
    if flags & BLOCKERS ~= 0 then return false end
    if code == ESCAPE then return true end
    local out
    local alt = flags & (RIGHT_ALT | LEFT_ALT) ~= 0
    if body and (layerKey(flags) or not alt) then
        if alt then
            local row = body.keys and body.keys[code]
            out = row and row[shift and "shift_opt" or "opt"]
        else
            local row = body.keys and body.keys[code]
            out = row and row[shift and "shift" or "base"]
            if out == nil then out = body.compose and body.compose[event:getCharacters()] end
        end
    end
    if out ~= nil and not (type(out) == "table" and out.pass) then
        produce(out)
        return true
    end
    obj._emit(t.terminators[state] or "")
    -- Consume and re-post: an event let through here would reach the app before the posted terminator.
    if not (layer(flags, code, shift, false) or fixup(flags, code, shift)) then obj._forward(event) end
    return true
end

function obj._onEvent(event)
    if event:getType() ~= hs.eventtap.event.types.keyDown then
        clear()
        return false
    end
    return obj._handle(event)
end

function obj._handle(event)
    if excluded or event:getProperty(props.eventSourceUserData) == MARK then return false end
    local flags = event:rawFlags()
    local code, shift = event:getKeyCode(), flags & SHIFTS ~= 0
    local repeating = event:getProperty(props.keyboardEventAutorepeat) ~= 0
    expire()
    if not dead then return layer(flags, code, shift, repeating) or fixup(flags, code, shift) end
    if repeating then return true end
    return insideDead(event, flags, code, shift)
end

function obj._appActivated(bundleID)
    clear()
    excluded = excludedSet[bundleID or ""] == true
end

--- BirmanLayer:init()
--- Method
--- Called by `hs.loadSpoon()`. Installs nothing: the key tap starts only in `BirmanLayer:start()`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The BirmanLayer object
function obj:init()
    return self
end

--- BirmanLayer:state()
--- Method
--- Reports whether the layer is running and which dead key, if any, is waiting.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table with `running` (boolean) and `dead` (`nil`, or a table with `state` — the dead key's
---    name, e.g. `"acute"`)
function obj:state()
    expire()
    return {
        running = tap ~= nil and tap:isEnabled(),
        dead = dead and { state = dead.state } or nil,
    }
end

--- BirmanLayer:start()
--- Method
--- Starts the key tap and the application watcher; calling it again restarts the layer with the current settings
---
--- Parameters:
---  * None
---
--- Returns:
---  * The BirmanLayer object
---
--- Notes:
---  * Reads `overrides`, `rightOptionOnly`, `baseFixups`, `excludedBundles`, `excludedLayouts` and `deadKeyTimeout`; a key name in
---    `overrides` that is not a QWERTY key position raises an error here
---  * Hammerspoon needs the Accessibility permission, and nothing is typed while macOS secure
---    input is on (password fields, some terminals)
function obj:start()
    self:stop()
    overrides, perSource, fixupCodes = {}, {}, {}
    for source, override in pairs(self.overrides) do overrides[source] = normalize(copy(override), source) end
    latinTable, cyrillicTable = withOverlay(), withOverlay(TABLE.cyrillic)
    if overrides["*"] then
        merge(latinTable, overrides["*"])
        merge(cyrillicTable, overrides["*"])
    end
    fixupsOn = self.baseFixups == true
    rightOnly = self.rightOptionOnly ~= false
    collectFixupCodes(latinTable)
    for _, override in pairs(overrides) do collectFixupCodes(override) end
    excludedSet = {}
    for _, id in ipairs(self.excludedBundles) do excludedSet[id] = true end
    excludedSources = {}
    for _, id in ipairs(self.excludedLayouts) do excludedSources[id] = true end
    deadTimeout = self.deadKeyTimeout * 1e9
    obj._appActivated(obj._frontBundle())
    local types = hs.eventtap.event.types
    tap = hs.eventtap.new({ types.keyDown, types.leftMouseDown, types.rightMouseDown, types.otherMouseDown },
        obj._onEvent):start()
    watcher = hs.application.watcher.new(function(_, kind, app)
        if kind == hs.application.watcher.activated then obj._appActivated(app and app:bundleID()) end
    end):start()
    self.logger.i("started")
    return self
end

--- BirmanLayer:stop()
--- Method
--- Stops the key tap and the application watcher and drops any pending dead key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The BirmanLayer object
function obj:stop()
    clear()
    if tap then tap:stop(); tap = nil end
    if watcher then watcher:stop(); watcher = nil end
    return self
end

return obj
