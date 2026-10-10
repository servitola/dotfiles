-- Run: hs -c 'return dofile(os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/Displays.spoon/tests/test_parking.lua")'
local root = os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/Spoons/Displays.spoon/"
local P = dofile(root .. "window_parking.lua")

local failures, checks = {}, 0
local function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        table.insert(failures, string.format("%s: got %s, want %s", label, tostring(got), tostring(want)))
    end
end

-- Real numbers from the spike: the TV as a secondary screen.
local TV = { x = 1728, y = 0, w = 1920, h = 1080 }
local TOL = 4

-- A normal window landed exactly — that's how Forkgram behaved.
eq(P.classify_park_result({ x = 1728, y = 0, w = 1920, h = 1080 }, TV, TOL),
   "ok", "точное попадание")
eq(P.classify_park_result({ x = 1730, y = 2, w = 1918, h = 1078 }, TV, TOL),
   "ok", "попадание в пределах допуска")

-- A window accepted the position but rejected the size — that's how the Finder dialog behaved.
eq(P.classify_park_result({ x = 1728, y = 0, w = 404, h = 350 }, TV, TOL),
   "size_rejected", "позиция да, размер нет")

-- The window didn't move at all.
eq(P.classify_park_result({ x = 100, y = 200, w = 404, h = 350 }, TV, TOL),
   "wrong_screen", "не переехало")

-- Centering a window that doesn't resize.
local c = P.centered_frame({ x = 1728, y = 0, w = 404, h = 350 }, TV)
eq(c.x, 1728 + (1920 - 404) / 2, "центр по X")
eq(c.y, (1080 - 350) / 2,        "центр по Y")
eq(c.w, 404, "центрирование не меняет ширину")
eq(c.h, 350, "центрирование не меняет высоту")

-- Registry -----------------------------------------------------------------
local function fake_screen(uuid)
    local s = {}
    function s:getUUID() return uuid end
    return s
end

local function fake_window(id, frame, uuid)
    local w = {}
    function w:id() return id end
    function w:frame() return frame end
    function w:screen() return fake_screen(uuid) end
    return w
end

local alive = {}
local R = P.new_registry({ get_window = function(id) return alive[id] end })

local w1 = fake_window(11, { x = 10, y = 20, w = 300, h = 400 }, "uuid-int")
alive[11] = w1

eq(R:is_parked(w1), false, "новое окно не припарковано")
local entry = R:record(w1)
eq(entry.frame.x, 10, "record сохранил x")
eq(entry.screen_uuid, "uuid-int", "record сохранил экран")
eq(R:is_parked(w1), true, "после record окно припарковано")

-- A repeated record doesn't overwrite the original frame: otherwise a
-- second hotkey press would remember the already-fullscreen frame on the
-- TV, and "back" would return the window to nowhere.
local moved = fake_window(11, { x = 1728, y = 0, w = 1920, h = 1080 }, "uuid-tv")
alive[11] = moved
R:record(moved)
eq(R.entries[11].frame.x, 10, "повторный record не затирает исходную рамку")

-- take returns the entry and unparks.
local taken = R:take(moved)
eq(taken.frame.x, 10, "take вернул исходную рамку")
eq(R:is_parked(moved), false, "после take не припарковано")
eq(R:take(moved), nil, "повторный take пустой")

-- prune discards dead windows.
local w2 = fake_window(22, { x = 0, y = 0, w = 100, h = 100 }, "uuid-int")
alive[22] = w2
R:record(w2)
eq(#R:ids(), 1, "одна запись до prune")
alive[22] = nil
R:prune()
eq(#R:ids(), 0, "prune выбросил мёртвое окно")

-- ids are sorted: unpark_all must be deterministic.
local w3 = fake_window(33, { x = 0, y = 0, w = 1, h = 1 }, "u")
local w4 = fake_window(5,  { x = 0, y = 0, w = 1, h = 1 }, "u")
alive[33], alive[5] = w3, w4
R:record(w3); R:record(w4)
local ids = R:ids()
eq(ids[1], 5,  "ids отсортированы: первый")
eq(ids[2], 33, "ids отсортированы: второй")

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
