local notify = require("notify")

local VPN_BANNERS = {
    connect      = { title = "VPN connected", message = "work", symbol = "lock.shield.fill", symbolColor = "#34c759", tint = "green", animate = true, duration = 2 },
    disconnect   = { title = "VPN off", message = "work", symbol = "lock.open.fill", symbolColor = "#8e8e93", tint = "gray", duration = 2 },
    connected    = { title = "VPN already connected", message = "work", symbol = "lock.shield.fill", tint = "green", duration = 2 },
    disconnected = { title = "VPN already off", message = "work", symbol = "lock.open.fill", tint = "gray", duration = 2 },
}
-- A private Spoon, absent on machines without the work VPN.
local vpn = spoon[require("constants").WORK_VPN_SPOON]
if vpn then
    vpn.notify = function(event, problem)
        notify.show(VPN_BANNERS[event] or { title = "VPN error", message = problem, symbol = "exclamationmark.shield.fill", tint = "red", duration = 5 })
    end
end
local systemHealth = require("actions.lib.system_health")
local clipboardLlm = require("actions.lib.clipboard_llm")

return function(register)
    register("system_health", function() systemHealth.toggle() end)
    register("clipboard_llm", function() clipboardLlm.show() end)
    register("vpn.toggle", function()
        if not vpn then return hs.alert.show("the work VPN Spoon is not installed") end
        vpn:toggle()
    end)
    register("wallpaper_refresh", function() spoon.Fresh4kWallpaper:next() end)
    register("show_youtrack", function() spoon.YouTrackTicket:toggle() end)
    register("show_youtrack_tasks", function() spoon.YouTrackTasks:toggle() end)
    -- appUsageAnalytics is a global assigned in init.lua after the spoons load.
    register("app_usage_stats", function()
        if appUsageAnalytics then appUsageAnalytics.toggle() end
    end)
end
