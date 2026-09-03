-- Run: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/VoiceCtl.spoon/tests/test_app.lua")'
local failures, checks = {}, 0
local function like(got, pattern, label)
    checks = checks + 1
    if type(got) ~= "string" or not got:find(pattern) then
        table.insert(failures, string.format("%s: got %s, want match %s", label, tostring(got), pattern))
    end
end

local V = spoon.VoiceCtl
if not V then return "FAIL: spoon.VoiceCtl not loaded" end

V.dry = true
like(V:run("app", "форк"), "^DRY app Fork$", "dry app форк")
like(V:run("app", "войсинк"), "^DRY app VoiceInk$", "dry app войсинк")
like(V:run("app", "абракадабра"), "^NOTFOUND", "dry app nonsense")
like(V:run("нетакогоглагола", "x"), "^ERR", "unknown verb")
V.dry = false

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
