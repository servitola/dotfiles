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
like(V:run("media", "дальше"), "^DRY media play$", "дальше = play/pause")
like(V:run("media", "пауза"), "^DRY media play$", "пауза = play/pause")
like(V:run("media", "следующий трек"), "^DRY media next$", "next")
like(V:run("media", "перемотай вперёд"), "^DRY media forward$", "forward")
like(V:run("vol", "30"), "^DRY vol 30$", "vol absolute")
like(V:run("vol", "тридцать процентов"), "^DRY vol 30$", "vol словом")
like(V:run("vol", "громче"), "^DRY vol up$", "vol up")
like(V:run("vol", "выключи звук"), "^DRY vol mute$", "mute")
like(V:run("audio", "маршалл"), "^DRY audio marshall$", "audio marshall")
like(V:run("audio", "встроенные"), "^DRY audio internal$", "audio internal")

-- «двадцать пять» не должно молча превращаться в «двадцать»: длинные числительные
-- разбираются раньше коротких, иначе результат зависит от порядка обхода таблицы.
like(V:run("vol", "двадцать пять"), "^DRY vol 25$", "составное числительное")
V.dry = false

-- Живая проверка громкости с возвратом: единственный безопасный побочный эффект.
--
-- Пауза между установкой и возвратом обязательна. Виртуальное устройство
-- (BE-RCA (eqMac)) доводит громкость асинхронно: два setOutputVolume подряд
-- читаются как «последний победил», но через пару секунд устройство
-- откатывается на первое значение и возврат теряется. Проверено живьём —
-- без паузы тест молча оставлял громкость 25 вместо исходной.
local SETTLE = 400000  -- мкс, замерено: 400 мс хватает, 0 мс — нет
local dev = hs.audiodevice.defaultOutputDevice()
local before = dev and dev:outputVolume()
if before then
    V:run("vol", "25")
    hs.timer.usleep(SETTLE)
    checks = checks + 1
    local after = hs.audiodevice.defaultOutputDevice():outputVolume()
    if math.abs(after - 25) > 2 then
        table.insert(failures, "vol 25 live: got " .. tostring(after))
    end

    dev:setOutputVolume(before)
    hs.timer.usleep(SETTLE)
    checks = checks + 1
    local restored = hs.audiodevice.defaultOutputDevice():outputVolume()
    if math.abs(restored - before) > 2 then
        table.insert(failures, string.format("громкость не вернулась: %s вместо %s",
            tostring(restored), tostring(before)))
    end
else
    table.insert(failures, "живая проверка пропущена: устройство без регулировки громкости")
end

if #failures > 0 then
    return "FAIL (" .. #failures .. "/" .. checks .. "): " .. table.concat(failures, "; ")
end
return "PASS " .. checks
