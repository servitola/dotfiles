-- Presses every app chord of the HotKeys tables and checks that app comes to the front.
-- Runs on Hammerspoon's timers; results land line by line in /tmp/hotkeys_apps.txt,
-- ending with "done".
local hotkeys = spoon.HotKeys
local out = io.open("/tmp/hotkeys_apps.txt", "w")
local function report(line) out:write(line, "\n"); out:flush() end

-- From the bundles on disk: LaunchServices has not met an app brew installed
-- until it first runs, so pathForBundleID calls it missing.
local installed = {}
for _, dir in ipairs({ "/Applications", "/System/Applications", "/System/Applications/Utilities",
                      "/System/Library/CoreServices", os.getenv("HOME") .. "/Applications" }) do
    if hs.fs.attributes(dir) then
        for name in hs.fs.dir(dir) do
            local info = name:match("%.app$") and hs.plist.read(dir .. "/" .. name .. "/Contents/Info.plist")
            if info and info.CFBundleIdentifier then installed[info.CFBundleIdentifier] = true end
        end
    end
end

local cases = {}
for _, entry in ipairs(hotkeys.chords) do
    if entry.app then
        local bundle = entry.bundle or hotkeys.bundleIds[entry.app]
        if entry.chord:find("⇪") then
            report("skip " .. entry.chord .. " " .. entry.app .. ": right-hand modifiers cannot be posted")
        elseif not bundle then
            report("skip " .. entry.chord .. " " .. entry.app .. ": no bundle id")
        elseif not installed[bundle] then
            report("skip " .. entry.chord .. " " .. entry.app .. ": not installed")
        else
            table.insert(cases, { chord = entry.chord, app = entry.app, bundle = bundle })
        end
    end
end

-- The chord toggles: pressed with its app already in front, it hides it.
local neutral = "com.apple.TextEdit"
local keep = {}
for _, bundle in ipairs({ neutral, "org.hammerspoon.Hammerspoon", "com.apple.finder", "com.apple.dock",
                          "com.apple.loginwindow", "com.apple.systemuiserver", "com.apple.controlcenter" }) do
    keep[bundle] = true
end
local index = 0

-- A fresh Mac's apps grab the front on their own (Tailscale at login, Telegram's
-- window a few seconds after launch), so none stays running between cases.
local function quitOthers()
    for _, app in ipairs(hs.application.runningApplications()) do
        if app:kind() == 1 and not keep[app:bundleID()] then app:kill9() end
    end
end

local function nextCase()
    index = index + 1
    local case = cases[index]
    if not case then report("done"); out:close(); return end
    quitOthers()
    hs.application.launchOrFocusByBundleID(neutral)
    hs.timer.doAfter(1, function()
        local mods, key = hotkeys.parseChord(case.chord)
        -- F13–F19 match only with the fn flag a real keyboard sets, F20 only without it (measured).
        if key:match("^F1%d$") then table.insert(mods, "fn") end
        hs.eventtap.keyStroke(mods, key, 0)
        local waited, pressedAgain, poll = 0, false, nil
        poll = hs.timer.doEvery(0.5, function()
            local front = hs.application.frontmostApplication()
            -- System alerts (a new login item, an app's first-launch request) take the
            -- front, and nobody in the VM answers them.
            if front and front:bundleID() == "com.apple.UserNotificationCenter" then
                hs.execute("killall UserNotificationCenter")
                return
            end
            local app = hs.application.get(case.bundle)
            waited = waited + 0.5
            -- a menu-bar app (VoiceInk) runs without ever coming to the front
            if (front and front:bundleID() == case.bundle) or (app and app:kind() ~= 1) then
                report("ok   " .. case.chord .. " " .. case.app)
            elseif waited >= 10 and not pressedAgain and not app then
                -- the first press can land while another window takes the front
                pressedAgain = true
                hs.application.launchOrFocusByBundleID(neutral)
                hs.timer.doAfter(1, function() hs.eventtap.keyStroke(mods, key, 0) end)
                return
            elseif waited < 20 then
                return
            else
                report("FAIL " .. case.chord .. " " .. case.app .. ": front is " .. (front and front:bundleID() or "nothing"))
            end
            poll:stop()
            nextCase()
        end)
    end)
end

nextCase()
