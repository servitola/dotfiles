-- media / vol / audio verbs.
return function(V)
    ---------------------------------------------------------------- media
    local function systemKey(name)
        hs.eventtap.event.newSystemKeyEvent(name, true):post()
        hs.eventtap.event.newSystemKeyEvent(name, false):post()
    end

    -- Video players that understand space better than a media key. Reason: YouTube in
    -- a browser responds to the system key via MediaSession unreliably
    -- when Music.app is running alongside — it steals the key.
    local SPACE_APPS = {
        ["Zen"] = true, ["Vivaldi"] = true, ["Yandex"] = true, ["Google Chrome"] = true,
        ["Firefox"] = true, ["Safari"] = true, ["IINA"] = true, ["Iina"] = true,
        ["Forkgram"] = true,
    }

    local function playPause()
        local app = hs.application.frontmostApplication()
        local name = app and app:name()
        if name and SPACE_APPS[name] then
            hs.eventtap.keyStroke({}, "space", 0)
            return "пробел в " .. name
        end
        systemKey("PLAY")
        return "медиа-клавиша"
    end

    local MEDIA = {
        { key = "play",    aliases = { "дальше", "пауза", "плей", "продолжи", "останови", "play", "pause", "стоп" },
          fn = playPause },
        { key = "next",    aliases = { "следующий трек", "следующий", "вперёд трек", "next" },
          fn = function() systemKey("NEXT") return "next" end },
        { key = "prev",    aliases = { "предыдущий трек", "предыдущий", "назад трек", "prev", "previous" },
          fn = function() systemKey("PREVIOUS") return "prev" end },
        { key = "forward", aliases = { "перемотай вперёд", "перемотай", "вперёд", "forward" },
          fn = function() hs.eventtap.keyStroke({}, "right", 0) return "forward" end },
        { key = "back",    aliases = { "перемотай назад", "назад", "back", "rewind" },
          fn = function() hs.eventtap.keyStroke({}, "left", 0) return "back" end },
    }

    V:register("media", function(phrase, ctx)
        local best, answer = V:resolveOr("media", phrase, MEDIA)
        if not best then return answer end
        if ctx.dry then return "DRY media " .. best.key end
        if answer then return answer end
        for _, m in ipairs(MEDIA) do
            if m.key == best.key then return "OK " .. m.fn() end
        end
        return "ERR media " .. best.key
    end)

    ---------------------------------------------------------------- vol
    local WORD_NUMBERS = {
        ["ноль"] = 0, ["десять"] = 10, ["пятнадцать"] = 15, ["двадцать"] = 20,
        ["двадцать пять"] = 25, ["тридцать"] = 30, ["сорок"] = 40, ["пятьдесят"] = 50,
        ["шестьдесят"] = 60, ["семьдесят"] = 70, ["восемьдесят"] = 80,
        ["девяносто"] = 90, ["сто"] = 100, ["половину"] = 50, ["максимум"] = 100,
    }

    -- pairs() iteration order is undefined, and «двадцать пять» also matches
    -- «двадцать» (substring = 75 points). Without a fixed order the volume
    -- would land on 25 sometimes and 20 other times. We take the best score; on a tie
    -- the longer numeral wins — it's always more specific.
    local WORD_ORDER = {}
    for word in pairs(WORD_NUMBERS) do WORD_ORDER[#WORD_ORDER + 1] = word end
    table.sort(WORD_ORDER, function(a, b)
        if #a ~= #b then return #a > #b end
        return a < b
    end)

    local VOL_WORDS = {
        { key = "up",     aliases = { "громче", "прибавь", "louder", "up" } },
        { key = "down",   aliases = { "тише", "убавь", "quieter", "down" } },
        { key = "mute",   aliases = { "выключи звук", "мьют", "заглуши", "mute", "без звука" } },
        { key = "unmute", aliases = { "включи звук", "верни звук", "unmute" } },
    }

    local function currentDevice()
        local dev = hs.audiodevice.defaultOutputDevice()
        if not dev then error("нет устройства вывода") end
        return dev
    end

    V:register("vol", function(phrase, ctx)
        -- Digit first: «30», «на 30 процентов».
        local n = phrase:match("(%d+)")
        if not n then
            -- Threshold 75, not 80: «тридцать процентов» against «тридцать» —
            -- is a substring match, which score rates at exactly 75.
            local bestWord, bestScore = nil, 0
            for _, word in ipairs(WORD_ORDER) do
                local s = V.resolve.score(phrase, word)
                if s > bestScore then bestScore, bestWord = s, word end
            end
            if bestWord and bestScore >= 75 then n = tostring(WORD_NUMBERS[bestWord]) end
        end
        if n then
            local level = math.max(0, math.min(100, tonumber(n)))
            if ctx.dry then return "DRY vol " .. level end
            local dev = currentDevice()
            dev:setMuted(false)
            dev:setOutputVolume(level)
            return "OK громкость " .. level
        end

        local best, answer = V:resolveOr("vol", phrase, VOL_WORDS)
        if not best then return answer end
        if ctx.dry then return "DRY vol " .. best.key end
        if answer then return answer end

        local dev = currentDevice()
        local level = dev:outputVolume() or 50
        if best.key == "up" then
            dev:setMuted(false); dev:setOutputVolume(math.min(100, level + 10))
            return "OK громкость " .. math.floor(math.min(100, level + 10))
        elseif best.key == "down" then
            dev:setOutputVolume(math.max(0, level - 10))
            return "OK громкость " .. math.floor(math.max(0, level - 10))
        elseif best.key == "mute" then
            dev:setMuted(true); return "OK звук выключен"
        else
            dev:setMuted(false); return "OK звук включён"
        end
    end)

    ---------------------------------------------------------------- audio
    -- Device nicknames come from aliases.json (personal), the keys are fixed.
    local LABEL = {
        internal = "ноутбук", external = "Scarlett",
        marshall = "Marshall", bt = "гостиная",
    }

    V:register("audio", function(phrase, ctx)
        local nick = V.aliases.audio or {}
        local OUTS = {
            { key = "internal", aliases = { "встроенные", "ноут", "колонки макбука", "internal", "laptop" } },
            { key = "external", aliases = { "скарлет", "интерфейс", "звуковуха", "external", "scarlett" } },
            { key = "marshall", aliases = { "маршалл", "marshall", "блютус колонка" } },
            { key = "bt",       aliases = { "гостиная", "большие колонки", "berca", "bt", "телек колонки" } },
        }
        for _, out in ipairs(OUTS) do
            for _, extra in ipairs(nick[out.key] or {}) do
                out.aliases[#out.aliases + 1] = extra
            end
        end

        local best, answer = V:resolveOr("audio", phrase, OUTS)
        if not best then return answer end
        if ctx.dry then return "DRY audio " .. best.key end
        if answer then return answer end

        local A = spoon.AudioSwitcher
        if not A then return "ERR AudioSwitcher не загружен" end

        -- internal/external switch synchronously and, when the device is absent,
        -- silently draw a "not found" banner. So we don't take it on faith — we read
        -- the actual output device: otherwise voice reports OK for something that never happened.
        if best.key == "internal" or best.key == "external" then
            local was = hs.audiodevice.defaultOutputDevice()
            was = was and was:name()
            if best.key == "internal" then A:switchToInternal() else A:switchToExternal() end
            local now = hs.audiodevice.defaultOutputDevice()
            now = now and now:name()
            if now == was and best.key ~= nil and was ~= nil then
                -- Device didn't change: either it was already selected, or it wasn't found.
                return "OK вывод " .. (now or "?") .. " (без изменений)"
            end
            return "OK вывод " .. (now or LABEL[best.key])
        end

        -- marshall/bt wait for the device to appear in the background — can't promise readiness.
        if best.key == "marshall" then A:connectAndSwitchToMarshall()
        else A:connectAndSwitchToBT() end
        return "OK переключаю на " .. LABEL[best.key]
    end)
end
