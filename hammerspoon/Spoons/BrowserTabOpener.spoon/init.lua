--- === BrowserTabOpener ===
---
--- One key for a site: jump to its open tab, press again for the next one, open it if there is none.
local obj = {}
obj.__index = obj

obj.name = "BrowserTabOpener"
obj.version = "0.1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/BrowserTabOpener.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local core = dofile(hs.spoons.scriptPath() .. "core.lua")
local log = hs.logger.new("BrowserTabOpener", "info")

--- BrowserTabOpener.browser
--- Variable
--- Bundle id of the browser (`"com.google.Chrome"`). `nil`: the system default browser.
obj.browser = nil

--- BrowserTabOpener.tabs
--- Variable
--- Your sites by name: `github = { pattern = "github.com", url = "https://github.com" }`,
--- with an optional `prefer`. `open("github")` and `bindHotkeys` use the names.
obj.tabs = {}

--- BrowserTabOpener.videoPlaying
--- Constant
--- A ready `prefer` condition: a video is playing on the page.
obj.videoPlaying = "(video => !!video && !video.paused)(document.querySelector('video'))"

local running = {}  -- referenced: GC kills a running hs.task
local told = {}     -- each warning once per load: a hotkey would repeat it on every press

local function run(path, arguments, done)
    local task
    task = hs.task.new(path, function(exitCode, output, problem)
        running[task] = nil
        if done then done(exitCode, output or "", problem or "") end
    end, arguments)
    running[task] = true
    task:start()
end

local function tell(key, message, onScreen)
    if told[key] then return end
    told[key] = true
    log.w(message)
    if onScreen then hs.alert.show("BrowserTabOpener: " .. message, 6) end
end

local function appName(bundle)
    return hs.application.nameForBundleID(bundle) or bundle
end

function obj:_bundle()
    return self.browser or hs.urlevent.getDefaultHandler("https")
end

local DENIED = "macOS does not let Hammerspoon control %s, so every press opens a new tab. "
    .. "Allow it in System Settings → Privacy & Security → Automation → Hammerspoon."

--- BrowserTabOpener:open(name) -> self
--- BrowserTabOpener:open(pattern, url[, options]) -> self
--- Method
--- Switches to a tab whose address contains `pattern`; called again, to the next such tab.
--- With no such tab, or in a browser without tab scripting, opens `url`. With one argument,
--- opens the site of that name from `tabs`.
---
--- `options.prefer` is JavaScript: a matching tab where it is true wins over the others.
--- The browser has to allow JavaScript from Apple Events for it; otherwise it is ignored.
function obj:open(pattern, url, options)
    if url == nil and options == nil then
        local ok, site = pcall(core.site, pattern, self.tabs[pattern])
        if not ok then error("BrowserTabOpener: " .. site .. " — open(name) takes a site from tabs, open(pattern, url) takes both", 2) end
        pattern, url, options = site.pattern, site.url, site.options
    end
    local ok, problem = pcall(core.check, pattern, url, options)
    if not ok then error("BrowserTabOpener: " .. problem, 2) end
    local bundle = self:_bundle()
    local scriptOk, script = pcall(core.script, bundle)
    if not scriptOk then error("BrowserTabOpener: " .. script, 2) end

    local condition = core.condition(options and options.prefer)
    run("/usr/bin/osascript", { "-e", script, pattern, condition }, function(exitCode, output, failure)
        local status, note = core.result(exitCode, output)
        if note then tell("prefer", "prefer is ignored — " .. appName(bundle) .. " says: " .. note) end
        if status == "ok" then return end
        if status == "failed" then
            if core.problem(failure) == "denied" then
                tell("denied", DENIED:format(appName(bundle)), true)
            else
                log.d(bundle .. ": " .. failure)
            end
        end
        -- open, not hs.urlevent.openURLWithBundle: for Chromium browsers that one can start
        -- a second process fighting the running one over its profile.
        run("/usr/bin/open", { "-b", bundle, url })
    end)
    return self
end

--- BrowserTabOpener:bindHotkeys(mapping) -> self
--- Method
--- A hotkey per site of `tabs`: `{ github = { { "ctrl", "alt" }, "g" } }`.
function obj:bindHotkeys(mapping)
    local actions = {}
    for name in pairs(mapping) do
        local ok, problem = pcall(core.site, name, self.tabs[name])
        if not ok then error("BrowserTabOpener: " .. problem, 2) end
        actions[name] = function() self:open(name) end
    end
    hs.spoons.bindHotkeysToSpec(actions, mapping)
    return self
end

local CHECK = [[
tell application id "%s"
    set report to "tabs: " & (count of tabs of front window) & " in the front window"
    try
        execute active tab of front window javascript "1"
        return report & linefeed & "prefer: JavaScript from Apple Events is allowed"
    on error problem
        return report & linefeed & "prefer: not available — " & problem
    end try
end tell
]]

--- BrowserTabOpener:check() -> self
--- Method
--- Prints to the Hammerspoon console what works with the current browser: tab switching,
--- the macOS permission, JavaScript for `prefer`. Run it when a key only opens new tabs.
function obj:check()
    local bundle = self:_bundle()
    local ok, problem = pcall(core.script, bundle)
    if not ok then error("BrowserTabOpener: " .. problem, 2) end
    local function say(line) log.i("check: " .. line) end

    say("browser: " .. appName(bundle) .. " (" .. bundle .. ")" .. (self.browser and "" or ", the system default"))
    if not hs.application.pathForBundleID(bundle) then
        say("this browser is not installed")
        return self
    end
    run("/usr/bin/osascript", { "-e", CHECK:format(bundle) }, function(exitCode, output, failure)
        if exitCode == 0 then
            for line in output:gmatch("[^\n]+") do say(line) end
        elseif core.problem(failure) == "denied" then
            say(DENIED:format(appName(bundle)))
        else
            say("tabs: this browser cannot switch tabs from a script; a key only opens the address (" .. failure:gsub("%s+$", "") .. ")")
        end
    end)
    return self
end

return obj
