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
like(V:run("win", "влево"), "^DRY win left$", "влево")
like(V:run("win", "вправо"), "^DRY win right$", "вправо")
like(V:run("win", "на весь экран"), "^DRY win full$", "фуллскрин")
like(V:run("win", "половину слева"), "^DRY win half%-left$", "половина слева")
like(V:run("win", "по центру"), "^DRY win center$", "центр")
like(V:run("win", "под работу"), "^DRY win work$", "раскладка work")
like(V:run("win", "под личное"), "^DRY win personal$", "раскладка personal")
like(V:run("win", "под общение"), "^DRY win comms$", "раскладка comms")
like(V:run("win", "разложи всё"), "^DRY win default$", "разложить все")
like(V:run("win", "абракадабра"), "^NOTFOUND", "мусор")
V.dry = false

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
