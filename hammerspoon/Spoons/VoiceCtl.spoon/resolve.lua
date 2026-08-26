-- Фаззи-сопоставление сырой ASR-фразы со списком кандидатов.
-- Чистые функции, никаких обращений к hs.* — тестируется без UI.
local M = {}

-- Кириллица → латиница. Ключи длиной 1 codepoint, поэтому порядок в таблице
-- не важен, важна полнота.
local RU = {
    ["а"]="a", ["б"]="b", ["в"]="v", ["г"]="g", ["д"]="d", ["е"]="e",
    ["ё"]="e", ["ж"]="zh", ["з"]="z", ["и"]="i", ["й"]="y", ["к"]="k",
    ["л"]="l", ["м"]="m", ["н"]="n", ["о"]="o", ["п"]="p", ["р"]="r",
    ["с"]="s", ["т"]="t", ["у"]="u", ["ф"]="f", ["х"]="h", ["ц"]="c",
    ["ч"]="ch", ["ш"]="sh", ["щ"]="sch", ["ъ"]="", ["ы"]="y", ["ь"]="",
    ["э"]="e", ["ю"]="yu", ["я"]="ya",
}

-- Опускать регистр приходится по codepoint: ch:lower() работает только на ASCII,
-- на многобайтной кириллице он молча возвращает исходный символ.
local function lowerCodepoint(cp)
    if cp >= 0x410 and cp <= 0x42F then return cp + 32 end  -- А-Я → а-я
    if cp == 0x401 then return 0x451 end                    -- Ё → ё
    return cp
end

function M.translit(s)
    if not s then return "" end
    local out = {}
    for _, cp in utf8.codes(s) do
        local ch = utf8.char(lowerCodepoint(cp))
        out[#out + 1] = RU[ch] or ch:lower()
    end
    return table.concat(out)
end

function M.norm(s)
    return (M.translit(s):gsub("[^a-z0-9]", ""))
end

function M.dist(a, b)
    if a == b then return 0 end
    if #a == 0 then return #b end
    if #b == 0 then return #a end
    local prev = {}
    for j = 0, #b do prev[j] = j end
    for i = 1, #a do
        local cur = { [0] = i }
        local ai = a:byte(i)
        for j = 1, #b do
            local cost = (ai == b:byte(j)) and 0 or 1
            local del, ins, sub = prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + cost
            local m = del < ins and del or ins
            cur[j] = m < sub and m or sub
        end
        prev = cur
    end
    return prev[#b]
end

-- 100 точное, 90 префикс, 80 подстрока, иначе штраф за расстояние.
function M.score(query, candidate)
    local q, c = M.norm(query), M.norm(candidate)
    if #q == 0 or #c == 0 then return 0 end
    if q == c then return 100 end
    if c:sub(1, #q) == q then return 90 end
    if c:find(q, 1, true) then return 80 end
    if q:find(c, 1, true) then return 75 end
    local d = M.dist(q, c)
    local longest = #q > #c and #q or #c
    local s = math.floor(70 * (1 - d / longest))
    return s > 0 and s or 0
end

local MIN_SCORE = 55   -- ниже — считаем, что не нашли
local GAP       = 15   -- разрыв с вторым местом, дающий уверенность

-- candidates: { {key=string, aliases={string,...}}, ... }
-- Возвращает best|nil, top3
function M.pick(query, candidates)
    local scored = {}
    for _, cand in ipairs(candidates) do
        local best = 0
        for _, alias in ipairs(cand.aliases or { cand.key }) do
            local s = M.score(query, alias)
            if s > best then best = s end
        end
        if best > 0 then
            scored[#scored + 1] = { key = cand.key, score = best, value = cand.value }
        end
    end
    table.sort(scored, function(x, y)
        if x.score ~= y.score then return x.score > y.score end
        return x.key < y.key
    end)

    local top = {}
    for i = 1, math.min(3, #scored) do top[i] = scored[i] end

    local first = scored[1]
    if not first or first.score < MIN_SCORE then return nil, top end

    local second = scored[2]
    -- Точное совпадение уверенно само по себе. Без этого правила «форк» вечно
    -- отвечает AMBIGUOUS: Fork даёт 100, а Forkgram 90 как префикс, разрыв 10.
    if first.score >= 100 then
        first.confident = true
    else
        first.confident = (not second) or (first.score - second.score >= GAP)
    end
    return first, top
end

return M
