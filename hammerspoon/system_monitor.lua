local systemMonitor = {}

-- Load Notification spoon
local notification = hs.loadSpoon("Notification")

-- Configuration
local config = {
    memoryThreshold = 80,  -- Show notification when memory pressure is above 80%
    notificationCooldown = 1200,  -- 20 minutes in seconds
    checkInterval = 300  -- Check every 5 minutes
}

-- Store last notification time
local lastNotificationTime = 0

-- Function to get memory pressure
local function getMemoryPressure()
    local handle = io.popen([[
        memory_pressure | grep "System-wide memory free percentage" | awk '{
            free=$5
            pressure=100-free
            printf "%.1f", pressure
        }'
    ]])
    local pressure = tonumber(handle:read("*a")) or 0
    handle:close()

    -- Get detailed memory stats for debugging
    local debug = io.popen([[
        vm_stat | awk '
        /page size of/{ps=$8}
        /Pages free/{free=$3}
        /Pages active/{active=$3}
        /Pages inactive/{inactive=$3}
        /Pages speculative/{spec=$3}
        /Pages wired/{wired=$4}
        /Pages compressed/{compressed=$5}
        END{
            total=(active+inactive+wired+compressed)*ps/1024/1024/1024
            printf "Active: %.1fGB, Wired: %.1fGB, Compressed: %.1fGB\nTotal Used: %.1fGB",
            active*ps/1024/1024/1024,
            wired*ps/1024/1024/1024,
            compressed*ps/1024/1024/1024,
            total
        }'
    ]])
    local debug_out = debug:read("*a")
    debug:close()

    print("Memory Stats:")
    print(debug_out)
    print(string.format("Memory Pressure: %.1f%%", pressure))

    return pressure
end

-- Function to show memory notification
local function showMemoryNotification(pressure)
    notification.show(
        string.format("⚠️  Memory pressure: %.1f%%", pressure),
        {
            backgroundColor = {
                red = 50/255,
                green = 46/255,
                blue = 44/255,
                alpha = 0.95
            },
            borderColor = {
                red = 251/255,
                green = 73/255,
                blue = 52/255,
                alpha = 0.6
            },
            timeout = 2
        }
    )
end

-- Function to check if we can show notification (cooldown check)
local function canShowNotification()
    local now = os.time()
    if now - lastNotificationTime >= config.notificationCooldown then
        lastNotificationTime = now
        return true
    end
    return false
end

-- Function to check memory
local function checkMemory()
    local pressure = getMemoryPressure()
    print(string.format("Memory pressure check: %.1f%%", pressure))

    if pressure >= config.memoryThreshold and canShowNotification() then
        showMemoryNotification(pressure)
    end
end

function systemMonitor.start()
    if systemMonitor.timer then
        systemMonitor.stop()
    end

    -- Start timer for periodic checks
    systemMonitor.timer = hs.timer.new(config.checkInterval, checkMemory)
    systemMonitor.timer:start()

    -- Do initial check
    checkMemory()
end

function systemMonitor.stop()
    if systemMonitor.timer then
        systemMonitor.timer:stop()
        systemMonitor.timer = nil
    end
end

return systemMonitor
