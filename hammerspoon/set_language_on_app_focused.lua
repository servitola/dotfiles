local lastApp = nil
local switchTimer = nil

local function setKarabinerProfile(profile)
    hs.execute(string.format('"/Library/Application Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli" --select-profile "%s"', profile))
end

local function setLanguageForApp(bundleId, layout)
    if switchTimer then
        switchTimer:stop()
    end

    switchTimer = hs.timer.doAfter(0.05, function()
        if lastApp == bundleId then return end
        lastApp = bundleId

        hs.keycodes.setLayout(layout)

        hs.timer.doAfter(0.02, function()
            local currentLayout = hs.keycodes.currentLayout()
            if currentLayout ~= layout then
                hs.keycodes.setLayout(layout)
            end
        end)
    end)
end

appwatcher = hs.application.watcher.new(function(appName, eventType, appObject)
    if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.unhidden then
        bundleId = appObject:bundleID()
        -- print("bundleID: " .. bundleId )
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
        bundleId = appObject:bundleID()
        if bundleId == "ru.keepcoder.Telegram" or bundleId == "one.ayugram.AyuGramDesktop" then
            lastApp = nil
        end
    end
end)
appwatcher:start()
