--- === AutoKeyboardLayout ===
---
--- Every app gets its keyboard layout the moment it comes to the front.
local obj = {}
obj.__index = obj

obj.name = "AutoKeyboardLayout"
obj.version = "0.1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/AutoKeyboardLayout.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local core = dofile(hs.spoons.scriptPath() .. "core.lua")
local log = hs.logger.new("AutoKeyboardLayout", "info")

--- AutoKeyboardLayout.primary
--- Variable
--- The layout every app gets: a layout name as System Settings shows it (`"ABC"`), an input
--- method name, or an input source id (`"com.apple.keylayout.ABC"`). `nil`: ordinary apps are
--- left alone.
obj.primary = nil

--- AutoKeyboardLayout.secondary
--- Variable
--- The layout for the apps in `secondaryApps` — the one you chat in. `nil`: those apps are
--- ordinary apps.
obj.secondary = nil

--- AutoKeyboardLayout.secondaryApps
--- Variable
--- Bundle ids of the apps that get `secondary`. Out of the box: the Telegram clients.
obj.secondaryApps = {
    "ru.keepcoder.Telegram",      -- Telegram for macOS
    "com.tdesktop.Telegram",      -- Telegram Desktop and its forks (Forkgram)
    "org.telegram.desktop",       -- Telegram Lite
    "org.telegram.TelegramA",     -- Telegram A
    "one.ayugram.AyuGramDesktop", -- AyuGram
}

--- AutoKeyboardLayout.overrides
--- Variable
--- Bundle id → layout, for an app that is neither: any installed layout, or `false` to leave
--- that app alone. Beats `secondaryApps`.
obj.overrides = {}

--- AutoKeyboardLayout.delay
--- Variable
--- Seconds between an app coming to the front and the switch. A switch made in the same
--- instant the app takes focus does not always stick.
obj.delay = 0.05

-- macOS sometimes reverts a switch made while the app is still taking focus.
local RECHECK = 0.02

local function installed()
    local sources = hs.keycodes.layouts(true)
    for _, id in ipairs(hs.keycodes.methods(true)) do sources[#sources + 1] = id end
    return { layouts = hs.keycodes.layouts(), methods = hs.keycodes.methods(), sources = sources }
end

local READ = {
    layout = hs.keycodes.currentLayout,
    method = hs.keycodes.currentMethod,
    source = hs.keycodes.currentSourceID,
}
local WRITE = {
    layout = hs.keycodes.setLayout,
    method = hs.keycodes.setMethod,
    source = hs.keycodes.currentSourceID,
}

function obj:_switch(wanted)
    local kind = core.kind(wanted, self._installed)
    local function switch()
        if READ[kind]() ~= wanted then WRITE[kind](wanted) end
    end
    switch()
    self._recheck = hs.timer.doAfter(RECHECK, switch)
end

function obj:_focused(bundle)
    if self._pending then self._pending:stop() end
    self._pending = hs.timer.doAfter(self.delay, function()
        -- "activated" and "unhidden" arrive together for one focus change.
        if self._front == bundle then return end
        self._front = bundle
        local wanted = core.resolve(bundle, self)
        if wanted then self:_switch(wanted) end
    end)
end

--- AutoKeyboardLayout:start() -> self
--- Method
--- Checks the configured layouts against the installed ones (a name that is not installed
--- raises), switches the app in front, and then every app as it comes to the front.
function obj:start()
    self:stop()
    self._installed = installed()
    local ok, problem = pcall(core.validate, self, self._installed)
    if not ok then error("AutoKeyboardLayout: " .. problem, 2) end

    local events = hs.application.watcher
    self._watcher = events.new(function(_, event, app)
        local bundle = app and app:bundleID()
        if not bundle then return end
        if event == events.activated or event == events.unhidden then
            self:_focused(bundle)
        elseif event == events.deactivated and self._front == bundle then
            -- Coming back to an app counts as a new focus, even from a panel that is not an app.
            self._front = nil
        end
    end)
    self._watcher:start()

    local front = hs.application.frontmostApplication()
    if front and front:bundleID() then self:_focused(front:bundleID()) end
    log.i("primary " .. tostring(self.primary) .. ", secondary " .. tostring(self.secondary))
    return self
end

--- AutoKeyboardLayout:stop() -> self
--- Method
--- Stops switching. The current layout stays.
function obj:stop()
    if self._watcher then self._watcher:stop() self._watcher = nil end
    if self._pending then self._pending:stop() self._pending = nil end
    if self._recheck then self._recheck:stop() self._recheck = nil end
    self._front = nil
    return self
end

return obj
