-- WiFi state banners — single sticky banner per WiFi session that
-- morphs through transitions instead of stacking multiple notifications.
--
-- Lifecycle (all updates share banner id "wifi-state" so the daemon
-- rewrites the existing window in place instead of stacking):
--   no SSID → SSID                "Connected: X" (green)
--   SSID    → no SSID             "Looking for network…" (orange, animated,
--                                  auto-dismisses in 10s if nothing came back)
--   waiting → SSID (within 10s)   morphs into "Switched: X → Y"
--   waiting → 10s elapsed         banner fades out, slate cleared
--   SSID    → other SSID          "Switched: X → Y" (indigo)

local notify = require("notify")
local log = hs.logger.new("WiFi", "info")

local M = {}
local BANNER_ID = "wifi-state"
local SEARCH_TIMEOUT = 10  -- how long the "looking for network" banner lives

-- Hammerspoon's hs.wifi.currentNetwork() requires Location Services
-- permission for Hammerspoon (System Settings → Privacy & Security →
-- Location Services → Hammerspoon).
local function currentSSID()
    return hs.wifi.currentNetwork()
end

-- Tracked state.
-- `knownSSID` mirrors what we last saw the system on (nil = no WiFi).
-- `pendingLostSSID` remembers the network we just lost, so a reconnect
-- within SEARCH_TIMEOUT can morph the searching banner into "Switched: X→Y"
-- with the original network name preserved.
local knownSSID = currentSSID()
local pendingLostSSID = nil
local pendingTimer = nil
log.i("initial SSID: " .. tostring(knownSSID))

local function clearPending()
    pendingLostSSID = nil
    if pendingTimer then pendingTimer:stop(); pendingTimer = nil end
end

local function announceConnected(ssid)
    notify.show({
        id          = BANNER_ID,
        title       = "Connected",
        message     = ssid,
        symbol      = "wifi",
        symbolColor = "#34c759",
        tint        = "green",
        animate     = true,
        duration    = 3,
    })
end

local function announceSearching(fromSSID)
    notify.show({
        id          = BANNER_ID,
        title       = "Looking for network…",
        message     = "lost " .. fromSSID,
        symbol      = "wifi.exclamationmark",
        symbolColor = "#ff9500",
        tint        = "orange",
        animate     = true,
        duration    = SEARCH_TIMEOUT,
    })
end

local function announceSwitched(fromSSID, toSSID)
    notify.show({
        id                = BANNER_ID,
        title             = "Switched WiFi",
        message           = fromSSID .. "  →  " .. toSSID,
        -- Dual-icon transition: orange "lost" badge on the left, indigo
        -- "connected" badge on the right, with an animated arrow between.
        symbolBefore      = "wifi.exclamationmark",
        symbolBeforeColor = "#ff9500",
        symbol            = "wifi",
        symbolColor       = "#5856d6",
        tint              = "indigo",
        animate           = true,
        duration          = 4,
    })
end

M.watcher = hs.wifi.watcher.new(function(_, event, _)
    if event ~= "SSIDChange" then return end

    local nextSSID = currentSSID()
    if nextSSID == knownSSID then return end

    log.i(string.format("SSID change: %s → %s",
                        tostring(knownSSID), tostring(nextSSID)))

    if knownSSID == nil and nextSSID ~= nil then
        -- Coming back online.
        if pendingLostSSID and pendingLostSSID ~= nextSSID then
            announceSwitched(pendingLostSSID, nextSSID)
        elseif pendingLostSSID == nextSSID then
            -- Reconnected to the same network after a blip.
            announceConnected(nextSSID)
        else
            announceConnected(nextSSID)
        end
        clearPending()
    elseif knownSSID ~= nil and nextSSID == nil then
        -- Dropped. Remember what we lost, arm a clear timer.
        pendingLostSSID = knownSSID
        announceSearching(knownSSID)
        if pendingTimer then pendingTimer:stop() end
        pendingTimer = hs.timer.doAfter(SEARCH_TIMEOUT, clearPending)
    elseif knownSSID ~= nil and nextSSID ~= nil then
        -- Direct switch between two networks without a nil step.
        announceSwitched(knownSSID, nextSSID)
        clearPending()
    end

    knownSSID = nextSSID
end)

M.watcher:watchingFor({ "SSIDChange" })
M.watcher:start()

return M
