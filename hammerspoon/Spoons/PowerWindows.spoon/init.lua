--- === PowerWindows ===
---
--- Every window in its place, one key.
local powerWindows = {}

powerWindows.name = "PowerWindows"
powerWindows.version = "0.3.0"
powerWindows.author = "servitola"
powerWindows.homepage = "https://github.com/servitola/PowerWindows.spoon"
powerWindows.license = "MIT - https://opensource.org/licenses/MIT"

local spoonPath = hs.spoons.scriptPath()
local function load(name) return dofile(spoonPath .. name .. ".lua") end

-- Three layers. The config files are the defaults: edit them, or pass your
-- own values to configure{} and an update will not undo them.
local core = load("lib/core")({
    settings = load("config/settings"),
    catalog = load("config/catalog"),
    dialogs = load("config/dialogs"),
})
local domain = load("lib/domain")(powerWindows, core)

function powerWindows:init()
    self.config = core.settings.copy(core.defaults)
    self._skip = {}
    return self
end

--- PowerWindows:configure(config) -> self
--- Method
--- Merge `config` into the current settings: maps key by key, one level deep;
--- lists replaced.
function powerWindows:configure(config)
    local merged = core.settings.merge(
        core.settings.copy(self.config), config
    )
    domain.validate(merged)
    self.config = merged
    return self
end

--- PowerWindows:setOverride(bundle, value)
--- Method
--- Set where `bundle` goes: a slot, `false`, a table, or `nil` to clear.
function powerWindows:setOverride(bundle, value)
    if value ~= nil then core.rules.normalize(value, "override") end
    self.config.overrides[bundle] = value
end

--- PowerWindows:addSkipPredicate(predicate)
--- Method
--- Windows for which `predicate(window)` returns true are never moved
--- automatically; a predicate that errors counts as false.
function powerWindows:addSkipPredicate(predicate)
    table.insert(self._skip, predicate)
end

--- PowerWindows:resolve([window]) -> table or false
--- Method
--- `{ slot, source, keepAspect, device, popup }` for `window` (default:
--- focused), or false.
function powerWindows:resolve(window)
    window = window or domain.query.focused()
    if not window or not window:application() then return false end
    return core.rules.resolve(
        self.config, core.catalog.apps, core.dialogs,
        domain.query.info(window), window
    )
end

--- PowerWindows:slotRect(name[, screen]) -> rect
--- Method
--- Frame of `name` on `screen` (default: main screen): main, side, corner,
--- video, full, halfLeft, halfRight, top60, bottom40 or column.
function powerWindows:slotRect(name, screen)
    local config, screenFrame =
        self:_screenLayout(screen or hs.screen.mainScreen())
    return core.geometry.rect(config, name, screenFrame)
end

--- PowerWindows:start() -> self
--- Method
--- Binds the default chords; starts Globe keys, screen watcher and
--- place-on-launch when enabled. Calling again rebinds.
function powerWindows:start()
    domain.validate(self.config)
    self:stop()
    self:_startHotkeys()
    self:_startGlobe()
    self:_startScreenWatcher()
    self:_startLaunch()
    return self
end

--- PowerWindows:stop() -> self
--- Method
--- Deletes the default chords, disables `bindHotkeys` ones until `start()`,
--- gives the Globe keys back, stops the screen watcher and place-on-launch.
function powerWindows:stop()
    self:_stopHotkeys()
    self:_stopGlobe()
    self:_stopScreenWatcher()
    self:_stopLaunch()
    self:_cancelAll()
    return self
end

--- PowerWindows:focusSet(name) -> boolean
--- Method
--- Applies `config.focusSets[name]`; false if absent, error if `video` is not
--- "main"/"left"/"corner".
function powerWindows:focusSet(name) return domain.focusSets.apply(name) end

return powerWindows
