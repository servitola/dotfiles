-- Run: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/VoiceCtl.spoon/tests/test_resolve.lua")'
local here = debug.getinfo(1, "S").source:match("@(.*/)")
local R = dofile(here .. "../resolve.lua")

local failures, checks = {}, 0
local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        table.insert(failures, string.format("%s: got %s, want %s", label, tostring(got), tostring(want)))
    end
end

-- Uppercase Cyrillic must be lowercased by codepoint:
-- ch:lower() doesn't work on a multibyte character.
eq(R.translit("Форк"), "fork", "translit Форк")
eq(R.translit("ФОРК"), "fork", "translit ФОРК caps")
eq(R.translit("Войсинк"), "voysink", "translit Войсинк")
eq(R.norm("  Visual Studio Code "), "visualstudiocode", "norm strips")

eq(R.dist("fork", "fork"), 0, "dist equal")
eq(R.dist("fork", "forkk"), 1, "dist insert")

local apps = {
    { key = "Fork",               aliases = { "Fork" } },
    { key = "Forkgram",           aliases = { "Forkgram", "Telegram" } },
    -- «войсинк» and «вскод» aren't caught by fuzzy matching: translit gives voysink/vskod,
    -- and the distance to voiceink/vscode is too large. That's what aliases are for —
    -- exactly the reason aliases.json exists.
    { key = "VoiceInk",           aliases = { "VoiceInk", "войсинк" } },
    { key = "Visual Studio Code", aliases = { "Visual Studio Code", "VSCode", "Code", "вскод" } },
    { key = "Simulator",          aliases = { "Simulator" } },
}

-- Russian dictation of English names.
eq(R.pick("форк", apps).key, "Fork", "pick форк")
eq(R.pick("форкграм", apps).key, "Forkgram", "pick форкграм")
eq(R.pick("войсинк", apps).key, "VoiceInk", "pick войсинк")
eq(R.pick("вскод", apps).key, "Visual Studio Code", "pick вскод")
eq(R.pick("симулятор", apps).key, "Simulator", "pick симулятор")
-- English dictation.
eq(R.pick("code", apps).key, "Visual Studio Code", "pick code")
-- ASR typo.
eq(R.pick("форкк", apps).key, "Fork", "pick форкк typo")
-- Nothing that matches.
eq(R.pick("абракадабра", apps), nil, "pick nonsense -> nil")

-- «форк» is an exact match for Fork (100), but also a prefix of Forkgram (90).
-- The gap of 10 is below the threshold, so a separate rule is needed: an exact match
-- is confident on its own. Otherwise «перейди на форк» would forever answer AMBIGUOUS.
local best, list = R.pick("форк", apps)
eq(best.key, "Fork", "exact match wins")
eq(best.confident, true, "exact match is confident despite small gap")
eq(#list >= 2, true, "candidate list still returned")

-- But when both candidates are prefix matches with the same score,
-- there must be no confidence: that's a genuine ambiguity.
local two = {
    { key = "Music",  aliases = { "Music" } },
    { key = "Museum", aliases = { "Museum" } },
}
eq(R.pick("mus", two).confident, false, "prefix tie is not confident")

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
