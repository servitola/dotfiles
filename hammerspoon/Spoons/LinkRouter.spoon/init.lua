--- === LinkRouter ===
---
--- Every link you click opens in the browser its rule names: work sites in one, local
--- servers in another, everything else in your usual one.
local obj = {}
obj.__index = obj

obj.name = "LinkRouter"
obj.version = "0.1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/LinkRouter.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local core = dofile(hs.spoons.scriptPath() .. "core.lua")
local log = hs.logger.new("LinkRouter", "info")

--- LinkRouter.default
--- Variable
--- Where a link goes when no rule matches: a name from `browsers` or a bundle id. Required.
obj.default = nil

--- LinkRouter.browsers
--- Variable
--- Optional short names for bundle ids, so rules read `"work"` instead of `"org.mozilla.firefox"`.
obj.browsers = {}

--- LinkRouter.rules
--- Variable
--- Checked top to bottom, the first match wins. Each rule is `{ match, open }`:
---  * match — a Lua pattern, a list of them, or `function(url, senderBundle) -> boolean`
---  * open — a name from `browsers`, a bundle id, or `function(url)` to handle the link yourself
---  * from (optional) — a bundle id or a list of them: the rule applies only to links clicked in those apps
obj.rules = {}

--- LinkRouter.unwrap
--- Variable
--- Functions `function(url) -> url or nil` run before the rules, to see through redirect
--- wrappers. `LinkRouter.slackRedirect` is a ready one.
obj.unwrap = {}

--- LinkRouter.localNetwork
--- Constant
--- Patterns for localhost, 127/8, 10/8, 172.16/12, 192.168/16 and `*.local`, for a rule's `match`.
obj.localNetwork = core.localNetwork

--- LinkRouter.slackRedirect
--- Constant
--- An `unwrap` for `slack.redir.net` links.
obj.slackRedirect = core.slackRedirect

local compiled = nil
local running = {}  -- referenced: GC kills a running hs.task

-- `open -b`, not hs.urlevent.openURLWithBundle: with some Chromium browsers (Vivaldi 7)
-- the latter starts a second browser process instead of handing the link to the running
-- one; the two fight over the profile lock, no tab appears and the first one hangs.
local function openIn(bundle, url)
    local task
    task = hs.task.new("/usr/bin/open", function(exitCode, _, problem)
        running[task] = nil
        if exitCode ~= 0 then log.e("open -b " .. bundle .. " failed: " .. (problem or "")) end
    end, { "-b", bundle, url })
    running[task] = true
    task:start()
end

local function senderBundle(pid)
    local app = pid and pid > 0 and hs.application.applicationForPID(pid)
    return app and app:bundleID() or nil
end

local function installed(bundle)
    local path = hs.application.pathForBundleID(bundle)
    return path ~= nil and path ~= ""
end

--- LinkRouter:route(url[, senderBundle]) -> url, target, ruleNumber
--- Method
--- What would happen to a link, without opening it: the url after `unwrap`, the bundle id
--- or function it goes to, and the number of the rule that decided (nil: `default`).
function obj:route(url, sender)
    return core.route(compiled or core.compile(self), url, sender)
end

--- LinkRouter:open(url[, senderBundle])
--- Method
--- Route a link as if it had been clicked.
function obj:open(url, sender)
    local final, destination, rule = self:route(url, sender)
    log.d(string.format("%s from %s -> %s (%s)", final, tostring(sender), tostring(destination), rule and "rule " .. rule or "default"))
    if type(destination) == "function" then return destination(final) end
    if not installed(destination) then
        log.w(destination .. " is not installed; opening in the default")
        destination = compiled and compiled.default or core.compile(self).default
        if type(destination) == "function" then return destination(final) end
    end
    openIn(destination, final)
end

--- LinkRouter:start()
--- Method
--- Check the settings, take over http and https links and make Hammerspoon the default
--- browser (macOS asks to confirm the first time).
function obj:start()
    compiled = core.compile(self)
    for _, bundle in pairs(self.browsers) do
        if not installed(bundle) then log.w("browsers: " .. bundle .. " is not installed; its links go to the default") end
    end
    if type(compiled.default) == "string" and not installed(compiled.default) then
        error("default: " .. compiled.default .. " is not installed", 0)
    end
    hs.urlevent.httpCallback = function(_, _, _, url, pid) self:open(url, senderBundle(pid)) end
    if hs.urlevent.getDefaultHandler("http") ~= "org.hammerspoon.Hammerspoon" then
        hs.urlevent.setDefaultHandler("http")
    end
    return self
end

--- LinkRouter:stop()
--- Method
--- Stop routing and hand http and https links back to the default browser.
function obj:stop()
    hs.urlevent.httpCallback = nil
    if compiled and type(compiled.default) == "string" then
        hs.urlevent.setDefaultHandler("http", compiled.default)
    end
    compiled = nil
    return self
end

return obj
