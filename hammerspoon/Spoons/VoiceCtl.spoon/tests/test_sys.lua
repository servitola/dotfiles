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
like(V:run("sys", "заблокируй"), "^DRY sys lock$", "lock")
like(V:run("sys", "спи"), "^DRY sys sleep$", "sleep")
like(V:run("sys", "погаси экран"), "^DRY sys display%-sleep$", "display sleep")
like(V:run("sys", "яркость больше"), "^DRY sys brightness%-up$", "brightness up")
like(V:run("text", "вставь без формата"), "^DRY text paste$", "paste bypass")
like(V:run("text", "переведи на английский"), "^DRY text translate%-en$", "translate en")
like(V:run("tv", "громче"), "^DRY tv ", "tv passthrough")
V.dry = false

-- info безопасен и обязан работать живьём.
-- Проверяем структуру, а не конкретное приложение: набор запущенного меняется.
local out = V:run("info", "")
like(out, "^OK front=", "info живой и начинается с фронта")
like(out, "%[", "info перечисляет окна")
-- Одна строка, без переводов.
checks = checks + 1
if out:find("\n") then table.insert(failures, "info вернул многострочный вывод") end

-- Запрещённое не должно существовать.
checks = checks + 1
local vpn = V:run("vpn", "включи")
if not vpn:find("^ERR unknown verb") then
    table.insert(failures, "глагол vpn не должен существовать, получено: " .. vpn)
end

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
