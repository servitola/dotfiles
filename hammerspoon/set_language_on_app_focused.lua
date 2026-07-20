local lastApp = nil
local switchTimer = nil

local karabinerCli = "/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli"
local currentProfile = nil
local karabinerTask = nil  -- referenced: GC kills running tasks

local function karabiner(args, onOutput)
    karabinerTask = hs.task.new(karabinerCli, function(_, stdOut)
        karabinerTask = nil
        if onOutput and stdOut then onOutput(stdOut) end
    end, args)
    karabinerTask:start()
end

karabiner({ "--show-current-profile-name" }, function(out)
    currentProfile = currentProfile or out:gsub("%s+$", "")
end)

local function setKarabinerProfile(profile)
    if profile == currentProfile then return end
    currentProfile = profile
    karabiner({ "--select-profile", profile })
end

local function setLanguageForApp(bundleId, layout)
    if switchTimer then
        switchTimer:stop()
    end

    switchTimer = hs.timer.doAfter(0.05, function()
        if lastApp == bundleId then return end
        lastApp = bundleId

        if hs.keycodes.currentLayout() == layout then return end
        hs.keycodes.setLayout(layout)

        hs.timer.doAfter(0.02, function()
            local currentLayout = hs.keycodes.currentLayout()
            if currentLayout ~= layout then
                hs.keycodes.setLayout(layout)
            end
        end)
    end)
end

appWatcherHub.register(function(appName, eventType, appObject)
    if not appObject then return end
    local bundleId = appObject:bundleID()
    if not bundleId then return end

    if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.unhidden then
        if bundleId == "ru.keepcoder.Telegram" or bundleId == "one.ayugram.AyuGramDesktop" then
            setLanguageForApp(bundleId, "Ru Birman")
            setKarabinerProfile("Default")
        elseif bundleId == "com.blizzard.heroesofthestorm" or bundleId == "com.nvidia.gfnpc.mall" then
            setLanguageForApp(bundleId, "ABC")
            setKarabinerProfile("Empty")
        else
            setLanguageForApp(bundleId, "En Birman")
            setKarabinerProfile("Default")
        end
    elseif eventType == hs.application.watcher.deactivated then
        if bundleId == "ru.keepcoder.Telegram" or bundleId == "one.ayugram.AyuGramDesktop" then
            lastApp = nil
        end
    end
end)
