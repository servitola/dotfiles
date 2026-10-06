-- Games and cloud gaming get the Karabiner "Empty" profile: the Hyper layers would
-- otherwise eat the keys a game binds. BirmanLayer stays silent in the same apps
-- (init.lua hands it `bundles`).
local BUNDLES = {
    ["com.blizzard.heroesofthestorm"] = true,
    ["com.nvidia.gfnpc.mall"] = true,
}

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

appWatcherHub.register(function(_, eventType, appObject)
    if eventType ~= hs.application.watcher.activated and eventType ~= hs.application.watcher.unhidden then return end
    local bundleId = appObject and appObject:bundleID()
    if not bundleId then return end
    setKarabinerProfile(BUNDLES[bundleId] and "Empty" or "Default")
end)

return { bundles = BUNDLES }
