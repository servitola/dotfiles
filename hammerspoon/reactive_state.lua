-- Reactive State — hs.watchable-based shared state for the entire config
-- Other modules subscribe to state changes and react automatically
-- Includes display watcher for HDMI/monitor plug/unplug detection

local log = hs.logger.new('ReactiveState', 'info')

-- Create the observable state object
-- Any module can read/write: state.currentProject = "Spotware"
-- Any module can watch: hs.watchable.watch("hammerspoon", "currentProject", callback)
state = hs.watchable.new("hammerspoon", true)

-- Initialize state
state.displayCount = #hs.screen.allScreens()
state.displayNames = {}
for _, screen in ipairs(hs.screen.allScreens()) do
    table.insert(state.displayNames, screen:name())
end
state.currentProject = nil
state.meeting = false
state.vpnConnected = false

-- Display watcher — detects HDMI/DisplayPort/Thunderbolt changes
local screenWatcher = hs.screen.watcher.new(function()
    local screens = hs.screen.allScreens()
    local newCount = #screens
    local oldCount = state.displayCount

    if newCount ~= oldCount then
        local names = {}
        for _, screen in ipairs(screens) do
            table.insert(names, screen:name())
        end

        log.i(string.format("Displays changed: %d → %d (%s)",
            oldCount, newCount, table.concat(names, ", ")))

        state.displayCount = newCount
        state.displayNames = names

        -- Notify user
        local action = newCount > oldCount and "connected" or "disconnected"
        hs.notify.new({
            title = "Display " .. action,
            informativeText = table.concat(names, ", "),
            withdrawAfter = 5
        }):send()
    end
end)
screenWatcher:start()

log.i("Reactive state initialized, " .. state.displayCount .. " display(s)")
