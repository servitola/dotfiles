-- Run: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/HotKeys.spoon/tests/test_actions.lua")'
local here = debug.getinfo(1, "S").source:match("@(.*/)")

local failures, checks = {}, 0
local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        table.insert(failures, string.format("%s: got %s, want %s", label, tostring(got), tostring(want)))
    end
end

local A = dofile(here .. "../actions.lua")

local called = false
A.register("test.one", function() called = true end)
A.get("test.one")()
eq(called, true, "registered fn is returned by get")
eq(A.get("test.missing"), nil, "unknown name is nil")

local ok, err = pcall(A.register, "test.one", function() end)
eq(ok, false, "duplicate name errors")
eq(tostring(err):find("test.one", 1, true) ~= nil, true, "duplicate error names the action")

ok, err = pcall(A.register, "test.bad", "not a function")
eq(ok, false, "non-function errors")

A.register("test.b", function() end)
A.register("test.a", function() end)
eq(table.concat(A.names(), ","), "test.a,test.b,test.one", "names sorted")

local B = dofile(here .. "../actions.lua")
eq(B.get("test.one"), nil, "each dofile is an independent registry")

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
