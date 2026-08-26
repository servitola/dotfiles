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
like(V:run("web", "ютуб"), "^DRY web youtube%.com$", "сайт ютуб")
like(V:run("web", "гитхаб"), "^DRY web github%.com$", "сайт гитхаб")
like(V:run("web", "что играет"), "^DRY web playing$", "что играет")
like(V:run("web", "найди рецепт борща"), "^DRY web search:рецепт борща$", "поиск")
like(V:run("tg", "настя"), "^DRY tg ", "чат настя")

-- Голый домен, которого нет в алиасах, должен открываться как есть.
like(V:run("web", "wikipedia.org"), "^DRY web wikipedia%.org$", "голый домен")
V.dry = false

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
