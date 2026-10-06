-- Run: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/HotKeys.spoon/tests/test_bind.lua")'
-- Uses the live spoon.HotKeys object; hs.hotkey.bind is replaced by a recorder.
local failures, checks = {}, 0
local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        table.insert(failures, string.format("%s: got %s, want %s", label, tostring(got), tostring(want)))
    end
end

local HK = spoon.HotKeys
eq(type(HK.bindChords), "function", "bindChords exists")

local here = debug.getinfo(1, "S").source:match("@(.*/)")
local fired = false
local A = dofile(here .. "../actions.lua")
A.register("test.fire", function() fired = true end)
local saved = HK.actions
HK.actions = A

local recorded = {}
local function recorder(mods, key, fn)
    table.insert(recorded, { mods = mods, key = key, fn = fn })
end

local ok, report = pcall(HK.bindChords, {
    { chord = "⌃⌥⌘F20", fn = "test.fire" },
    { chord = "⌃⌥⌘F19", fn = "test.nope" },
    { chord = "⌃⌥⌘F18", sendKey = "hi" },
}, recorder)

HK.actions = saved
assert(ok, report)

eq(report.bound, 2, "known fn and sendKey are bound")
eq(#report.missing, 1, "one missing action")
eq(report.missing[1].fn, "test.nope", "missing names the fn")
eq(report.missing[1].chord, "⌃⌥⌘F19", "missing names the chord")
eq(#recorded, 2, "recorder saw two binds")
eq(recorded[1].key, "F20", "first bind key")
eq(table.concat(recorded[1].mods, ","), "ctrl,alt,cmd", "first bind mods")
recorded[1].fn()
eq(fired, true, "bound closure calls the registered action")

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
