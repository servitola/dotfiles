-- Запуск: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/VoiceCtl.spoon/tests/test_resolve.lua")'
local here = debug.getinfo(1, "S").source:match("@(.*/)")
local R = dofile(here .. "../resolve.lua")

local failures, checks = {}, 0
local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        table.insert(failures, string.format("%s: got %s, want %s", label, tostring(got), tostring(want)))
    end
end

-- Заглавная кириллица должна опускаться в нижний регистр по codepoint:
-- ch:lower() на многобайтном символе не работает.
eq(R.translit("Форк"), "fork", "translit Форк")
eq(R.translit("ФОРК"), "fork", "translit ФОРК caps")
eq(R.translit("Войсинк"), "voysink", "translit Войсинк")
eq(R.norm("  Visual Studio Code "), "visualstudiocode", "norm strips")

eq(R.dist("fork", "fork"), 0, "dist equal")
eq(R.dist("fork", "forkk"), 1, "dist insert")

local apps = {
    { key = "Fork",               aliases = { "Fork" } },
    { key = "Forkgram",           aliases = { "Forkgram", "Telegram" } },
    -- «войсинк» и «вскод» фаззи-матчем не берутся: транслит даёт voysink/vskod,
    -- расстояние до voiceink/vscode слишком велико. Это работа алиасов —
    -- ровно то, для чего существует aliases.json.
    { key = "VoiceInk",           aliases = { "VoiceInk", "войсинк" } },
    { key = "Visual Studio Code", aliases = { "Visual Studio Code", "VSCode", "Code", "вскод" } },
    { key = "Simulator",          aliases = { "Simulator" } },
}

-- Русская диктовка английских имён.
eq(R.pick("форк", apps).key, "Fork", "pick форк")
eq(R.pick("форкграм", apps).key, "Forkgram", "pick форкграм")
eq(R.pick("войсинк", apps).key, "VoiceInk", "pick войсинк")
eq(R.pick("вскод", apps).key, "Visual Studio Code", "pick вскод")
eq(R.pick("симулятор", apps).key, "Simulator", "pick симулятор")
-- Английская диктовка.
eq(R.pick("code", apps).key, "Visual Studio Code", "pick code")
-- Опечатка ASR.
eq(R.pick("форкк", apps).key, "Fork", "pick форкк typo")
-- Ничего похожего.
eq(R.pick("абракадабра", apps), nil, "pick nonsense -> nil")

-- «форк» точно равен Fork (100), но является префиксом Forkgram (90).
-- Разрыв 10 меньше порога, поэтому нужно отдельное правило: точное совпадение
-- уверенно само по себе. Иначе «перейди на форк» вечно отвечает AMBIGUOUS.
local best, list = R.pick("форк", apps)
eq(best.key, "Fork", "exact match wins")
eq(best.confident, true, "exact match is confident despite small gap")
eq(#list >= 2, true, "candidate list still returned")

-- А вот когда оба кандидата — префиксные совпадения с одинаковым счётом,
-- уверенности быть не должно: это честная неоднозначность.
local two = {
    { key = "Music",  aliases = { "Music" } },
    { key = "Museum", aliases = { "Museum" } },
}
eq(R.pick("mus", two).confident, false, "prefix tie is not confident")

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
