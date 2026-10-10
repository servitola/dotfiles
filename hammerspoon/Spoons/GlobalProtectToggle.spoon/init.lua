--- === GlobalProtectToggle ===
---
--- Connect and disconnect the GlobalProtect VPN with a key.
local obj = {}
obj.__index = obj

obj.name = "GlobalProtectToggle"
obj.version = "0.1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/GlobalProtectToggle.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local core = dofile(hs.spoons.scriptPath() .. "core.lua")
local log = hs.logger.new("GlobalProtectToggle", "info")

--- GlobalProtectToggle.labels
--- Variable
--- The text of the main button in GlobalProtect's panel, as your GlobalProtect shows it:
--- `{ connect = "Connect", disconnect = "Disconnect" }`. Change it for another language.
obj.labels = { connect = "Connect", disconnect = "Disconnect" }

local MESSAGES = {
    connect = "VPN: connecting",
    disconnect = "VPN: disconnected",
    connected = "VPN is already connected",
    disconnected = "VPN is already disconnected",
}

--- GlobalProtectToggle.notify
--- Variable
--- Called with what happened: `"connect"` or `"disconnect"` (the button was pressed),
--- `"connected"` or `"disconnected"` (nothing to do), or `"error"` with a message.
--- By default shows an `hs.alert`. Set to your own function, or to `function() end` for silence.
obj.notify = function(event, problem)
    hs.alert.show(event == "error" and "VPN: " .. problem or MESSAGES[event], event == "error" and 6 or 2)
end

local running = {}  -- referenced: GC kills a running hs.task
local busy = false

local function script(source, done)
    local task
    task = hs.task.new("/usr/bin/osascript", function(exitCode, output, problem)
        running[task] = nil
        done(exitCode == 0, output or "", problem or "")
    end, { "-e", source })
    running[task] = true
    task:start()
end

function obj:_fail(problem)
    busy = false
    log.w(problem)
    self.notify("error", problem)
end

function obj:_read(done)
    script(core.READ, function(succeeded, output, failure)
        if not succeeded then return self:_fail(core.problem(failure)) end
        local state = core.state(output, self.labels)
        if not state then
            local seen = output:gsub("%s+$", "")
            return self:_fail("the button reads \"" .. seen .. "\"; it is busy, or set labels to your language")
        end
        done(state)
    end)
end

function obj:_run(wanted)
    local ok, problem = pcall(core.checkLabels, self.labels)
    if not ok then error("GlobalProtectToggle: " .. problem, 3) end
    -- A second press while the panel is open would click whatever is under it by then.
    if busy then return self end
    busy = true
    self:_read(function(state)
        local action = core.action(wanted, state)
        if not action then
            busy = false
            return self.notify(state)
        end
        script(core.PRESS, function(succeeded, _, failure)
            if not succeeded then return self:_fail(core.problem(failure)) end
            busy = false
            self.notify(action)
        end)
    end)
    return self
end

--- GlobalProtectToggle:toggle() -> self
--- Method
--- Connects when disconnected, disconnects when connected.
function obj:toggle() return self:_run("toggle") end

--- GlobalProtectToggle:connect() -> self
--- Method
--- Connects; does nothing when already connected.
function obj:connect() return self:_run("connect") end

--- GlobalProtectToggle:disconnect() -> self
--- Method
--- Disconnects; does nothing when already disconnected.
function obj:disconnect() return self:_run("disconnect") end

--- GlobalProtectToggle:status(callback) -> self
--- Method
--- Calls `callback("connected")` or `callback("disconnected")`. Opens the panel for a moment
--- to read it; on a failure `notify("error", …)` is called instead.
function obj:status(callback)
    local ok, problem = pcall(core.checkLabels, self.labels)
    if not ok then error("GlobalProtectToggle: " .. problem, 2) end
    if busy then return self end
    busy = true
    self:_read(function(state)
        busy = false
        callback(state)
    end)
    return self
end

--- GlobalProtectToggle:bindHotkeys(mapping) -> self
--- Method
--- Hotkeys for `toggle`, `connect`, `disconnect`: `{ toggle = { { "ctrl", "alt" }, "v" } }`.
function obj:bindHotkeys(mapping)
    hs.spoons.bindHotkeysToSpec({
        toggle = function() self:toggle() end,
        connect = function() self:connect() end,
        disconnect = function() self:disconnect() end,
    }, mapping)
    return self
end

return obj
