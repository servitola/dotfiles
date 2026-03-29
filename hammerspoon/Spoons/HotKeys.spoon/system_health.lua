-- System Health Dashboard
-- Shows macOS system status in a Gruvbox-themed webview panel
-- Dismissed with Escape key
-- Fast data shown instantly; slow data (public IP, docker, VPN) loaded async

local M = {}

local healthWebview = nil
local healthEscHotkey = nil
local asyncTasks = nil  -- prevent GC of running hs.task objects

-- Load private config (SSH hosts, etc.) — gitignored
local privateConfig = {}
local selfPath = debug.getinfo(1, "S").source:match("^@(.*/)")
local ok, cfg = pcall(dofile, selfPath .. "system_health_private.lua")
if ok and cfg then privateConfig = cfg end

local function formatBytes(bytes)
    if bytes >= 1073741824 then
        return string.format("%.1f GB", bytes / 1073741824)
    elseif bytes >= 1048576 then
        return string.format("%.0f MB", bytes / 1048576)
    else
        return string.format("%.0f KB", bytes / 1024)
    end
end

local function formatUptime(seconds)
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, mins)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", mins)
    end
end

local function escapeHtml(str)
    if not str then return "" end
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

local function statusDot(ok)
    if ok then
        return '<span style="color:#b8bb26">●</span>'
    else
        return '<span style="color:#fb4934">●</span>'
    end
end

-- Gather data available instantly from native HS APIs and fast system calls
local function gatherFastInfo()
    local info = {}

    -- Internet
    local reachability = hs.network.reachability.forAddress("8.8.8.8")
    local flags = reachability:status()
    info.internetReachable = (flags & 2) > 0 -- kSCNetworkReachabilityFlagsReachable

    -- WiFi
    info.wifi = hs.wifi.currentNetwork() or nil

    -- IP Address
    local primaryIf = hs.network.primaryInterfaces()
    if primaryIf then
        local details = hs.network.interfaceDetails(primaryIf)
        if details and details.IPv4 then
            info.ip = details.IPv4.Addresses and details.IPv4.Addresses[1]
        end
    end

    -- Battery
    info.batteryPercent = hs.battery.percentage()
    info.batteryCharging = hs.battery.isCharging()
    info.batteryPowerSource = hs.battery.powerSource()
    info.batteryTimeRemaining = hs.battery.timeRemaining()

    -- CPU
    local cpu = hs.host.cpuUsage()
    if cpu and cpu.overall then
        info.cpuUser = cpu.overall.user
        info.cpuSystem = cpu.overall.system
        info.cpuIdle = cpu.overall.idle
    end

    -- RAM
    local vm = hs.host.vmStat()
    if vm then
        local pageSize = vm.pageSize or 16384
        info.ramTotal = vm.memSize or 0
        info.ramActive = (vm.pagesActive or 0) * pageSize
        info.ramWired = (vm.pagesWiredDown or 0) * pageSize
        info.ramCompressed = (vm.pagesUsedByVMCompressor or 0) * pageSize
        info.ramFree = (vm.pagesFree or 0) * pageSize
        info.ramUsed = info.ramActive + info.ramWired + info.ramCompressed
    end

    -- RAM Pressure (1=normal, 2=warn, 4=critical)
    local pressureOutput = hs.execute("sysctl -n kern.memorystatus_vm_pressure_level", true)
    local pressureLevel = tonumber(pressureOutput) or 0
    local pressureMap = { [1] = "normal", [2] = "warn", [4] = "critical" }
    info.ramPressure = pressureMap[pressureLevel] or "normal"

    -- Disk
    info.volumes = {}
    local volumes = hs.fs.volume.allVolumes()
    if volumes then
        for path, vol in pairs(volumes) do
            if vol.NSURLVolumeTotalCapacityKey and vol.NSURLVolumeTotalCapacityKey > 0 then
                local isInternal = not vol.NSURLVolumeIsRemovableKey
                table.insert(info.volumes, {
                    name = vol.NSURLVolumeLocalizedNameKey or path,
                    total = vol.NSURLVolumeTotalCapacityKey,
                    free = vol.NSURLVolumeAvailableCapacityKey or 0,
                    internal = isInternal
                })
            end
        end
    end

    -- Audio
    local outputDevice = hs.audiodevice.defaultOutputDevice()
    if outputDevice then
        info.audioDevice = outputDevice:name()
        info.audioVolume = math.floor(outputDevice:volume() or 0)
        info.audioMuted = outputDevice:muted()
    end

    -- Now Playing
    info.musicPlaying = hs.itunes.isPlaying()
    if info.musicPlaying then
        info.musicTrack = hs.itunes.getCurrentTrack()
        info.musicArtist = hs.itunes.getCurrentArtist()
    end

    -- USB
    info.usbDevices = {}
    local usbDevices = hs.usb.attachedDevices()
    if usbDevices then
        for _, dev in ipairs(usbDevices) do
            if dev.productName and dev.productName ~= "" then
                table.insert(info.usbDevices, dev.productName)
            end
        end
    end

    -- Screens
    info.screens = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        table.insert(info.screens, screen:name())
    end

    -- Uptime
    local boottime = hs.execute("sysctl -n kern.boottime", true)
    local bootSec = tonumber(boottime:match("sec%s*=%s*(%d+)")) or 0
    info.uptime = (bootSec > 0) and (os.time() - bootSec) or 0

    -- Top processes by CPU
    info.topCpu = {}
    local psOut = hs.execute("ps -eo pcpu,pmem,comm -r 2>/dev/null | head -4")
    if psOut then
        for pct, mem, cmd in psOut:gmatch("(%d+%.%d+)%s+(%d+%.%d+)%s+(/[^\n]+)") do
            local name = cmd:match(".*/([^/]+)$") or cmd
            name = name:gsub("%.app.*", "")
            table.insert(info.topCpu, { cpu = tonumber(pct), mem = tonumber(mem), name = name })
        end
    end

    -- Top processes by RAM
    info.topMem = {}
    local psMem = hs.execute("ps -eo pmem,pcpu,comm -r 2>/dev/null | sort -rn | head -3")
    if psMem then
        for mem, cpu, cmd in psMem:gmatch("(%d+%.%d+)%s+(%d+%.%d+)%s+(/[^\n]+)") do
            local name = cmd:match(".*/([^/]+)$") or cmd
            name = name:gsub("%.app.*", "")
            table.insert(info.topMem, { mem = tonumber(mem), cpu = tonumber(cpu), name = name })
        end
    end

    -- Thermal state
    info.thermalState = hs.host.thermalState()

    -- DNS
    info.dns = {}
    local dnsOut = hs.execute("scutil --dns 2>/dev/null | grep 'nameserver\\[0\\]' | head -3")
    if dnsOut then
        for ip in dnsOut:gmatch(":%s*([%d%.]+)") do
            local seen = false
            for _, v in ipairs(info.dns) do if v == ip then seen = true end end
            if not seen then table.insert(info.dns, ip) end
        end
    end

    -- Defaults for async sections (shown as loading)
    info.bluetoothDevices = {}
    info.containers = {}

    return info
end

-- Fire slow commands (curl, blueutil, orbctl, docker, ssh) async in parallel.
-- Calls onComplete() when all finish. Returns task table (caller must hold reference).
local function gatherSlowInfoAsync(info, onComplete)
    local pending = 0
    local tasks = {}

    local function asyncCmd(cmd, args, handler)
        pending = pending + 1
        local buf = {out = ""}
        local task = hs.task.new(cmd, function(exitCode)
            handler(buf.out, exitCode)
            pending = pending - 1
            if pending == 0 then onComplete() end
        end, function(_, stdout, _)
            if stdout then buf.out = buf.out .. stdout end
            return true
        end, args)
        table.insert(tasks, task)
        task:start()
    end

    -- Public IP
    asyncCmd("/usr/bin/curl", {"-s", "--max-time", "2", "https://api.ipify.org"}, function(out)
        local ip = out:match("(%d+%.%d+%.%d+%.%d+)")
        if ip then info.publicIp = ip end
    end)

    -- Bluetooth
    asyncCmd("/opt/homebrew/bin/blueutil", {"--connected", "--format", "json"}, function(out)
        info.bluetoothDevices = {}
        for name in out:gmatch('"name"%s*:%s*"([^"]+)"') do
            table.insert(info.bluetoothDevices, name)
        end
    end)

    -- OrbStack
    asyncCmd("/opt/homebrew/bin/orbctl", {"status"}, function(out, exitCode)
        if exitCode == 0 and out then
            info.orbstack = out:match("Running") and "running" or "stopped"
        end
    end)

    -- Docker containers
    asyncCmd("/opt/homebrew/bin/docker", {"ps", "--format", "{{.Names}}"}, function(out, exitCode)
        info.containers = {}
        if exitCode == 0 and out then
            for name in out:gmatch("[^\n]+") do
                if #name > 0 then table.insert(info.containers, name) end
            end
        end
    end)

    if pending == 0 then onComplete() end
    return tasks
end

local function buildHtml(info)
    local sections = {}

    -- Network section
    local netRows = string.format('<div class="item">%s Internet %s</div>',
        statusDot(info.internetReachable),
        info.internetReachable and "Connected" or "Offline")
    if info.wifi then
        netRows = netRows .. string.format('<div class="item">📶 WiFi: %s</div>', escapeHtml(info.wifi))
    end
    if info.publicIp then
        netRows = netRows .. string.format('<div class="item">🌍 Public IP: %s</div>', info.publicIp)
    end
    if info.ip then
        netRows = netRows .. string.format('<div class="item">🌐 Local IP: %s</div>', info.ip)
    end
    if #info.dns > 0 then
        netRows = netRows .. string.format('<div class="item">🔤 DNS: %s</div>', table.concat(info.dns, ", "))
    end
    table.insert(sections, { title = "Network", content = netRows })

    -- Battery section
    if info.batteryPercent then
        local batteryIcon = info.batteryCharging and "⚡" or "🔋"
        local batteryColor = info.batteryPercent > 20 and "#b8bb26" or "#fb4934"
        local timeStr = ""
        if info.batteryTimeRemaining and info.batteryTimeRemaining > 0 then
            timeStr = string.format(" (%s left)", formatUptime(info.batteryTimeRemaining * 60))
        end
        local batContent = string.format(
            '<div class="item">%s <span style="color:%s">%.0f%%</span> %s%s</div>',
            batteryIcon, batteryColor, info.batteryPercent,
            info.batteryPowerSource or "", timeStr)
        table.insert(sections, { title = "Battery", content = batContent })
    end

    -- CPU section
    if info.cpuUser then
        local cpuTotal = info.cpuUser + info.cpuSystem
        local cpuColor = cpuTotal < 50 and "#b8bb26" or (cpuTotal < 80 and "#fabd2f" or "#fb4934")
        local cpuContent = string.format(
            '<div class="item">⚙️ <span style="color:%s">%.0f%%</span> (user: %.0f%% sys: %.0f%%)</div>',
            cpuColor, cpuTotal, info.cpuUser, info.cpuSystem)
        table.insert(sections, { title = "CPU", content = cpuContent })
    end

    -- Top Processes
    if #info.topCpu > 0 then
        local procRows = '<div class="item sub" style="font-family:monospace">'
        for _, p in ipairs(info.topCpu) do
            local cpuColor = p.cpu > 100 and "#fb4934" or (p.cpu > 50 and "#fabd2f" or "#b8bb26")
            local name = #p.name > 20 and p.name:sub(1, 18) .. ".." or p.name
            procRows = procRows .. string.format(
                '<span style="color:%s">%5.1f%%</span> CPU  %4.1f%% RAM  %s<br>',
                cpuColor, p.cpu, p.mem, escapeHtml(name))
        end
        procRows = procRows .. '</div>'
        table.insert(sections, { title = "Top Processes", content = procRows })
    end

    -- Thermal
    if info.thermalState then
        local thermalColors = { nominal = "#b8bb26", fair = "#fabd2f", serious = "#fe8019", critical = "#fb4934" }
        local color = thermalColors[info.thermalState] or "#ebdbb2"
        local thermalContent = string.format(
            '<div class="item">🌡️ Thermal: <span style="color:%s">%s</span></div>',
            color, info.thermalState)
        table.insert(sections, { title = "Thermal", content = thermalContent })
    end

    -- RAM section
    if info.ramUsed then
        local ramPercent = (info.ramUsed / info.ramTotal) * 100
        local ramColor = ramPercent < 70 and "#b8bb26" or (ramPercent < 90 and "#fabd2f" or "#fb4934")
        local pressureColor = info.ramPressure == "normal" and "#b8bb26" or "#fb4934"
        local ramContent = string.format(
            '<div class="item">🧠 <span style="color:%s">%s / %s (%.0f%%)</span></div>' ..
            '<div class="item sub">Active: %s | Wired: %s | Compressed: %s</div>' ..
            '<div class="item sub">Pressure: <span style="color:%s">%s</span></div>',
            ramColor, formatBytes(info.ramUsed), formatBytes(info.ramTotal), ramPercent,
            formatBytes(info.ramActive), formatBytes(info.ramWired), formatBytes(info.ramCompressed),
            pressureColor, info.ramPressure or "unknown")
        table.insert(sections, { title = "RAM", content = ramContent })
    end

    -- Disk section
    local diskContent = ""
    for _, vol in ipairs(info.volumes) do
        local used = vol.total - vol.free
        local usedPercent = (used / vol.total) * 100
        local diskColor = usedPercent < 80 and "#b8bb26" or (usedPercent < 95 and "#fabd2f" or "#fb4934")
        diskContent = diskContent .. string.format(
            '<div class="item">💾 %s: <span style="color:%s">%s free</span> / %s (%.0f%% used)</div>',
            escapeHtml(vol.name), diskColor, formatBytes(vol.free), formatBytes(vol.total), usedPercent)
    end
    if diskContent ~= "" then
        table.insert(sections, { title = "Disk", content = diskContent })
    end

    -- OrbStack / Docker
    if info.orbstack then
        local orbColor = info.orbstack == "running" and "#b8bb26" or "#fb4934"
        local orbContent = string.format(
            '<div class="item">%s OrbStack: <span style="color:%s">%s</span></div>',
            statusDot(info.orbstack == "running"), orbColor, info.orbstack)
        if info.containers and #info.containers > 0 then
            orbContent = orbContent .. string.format(
                '<div class="item sub">🐳 %d containers: %s</div>',
                #info.containers, escapeHtml(table.concat(info.containers, ", ")))
        end
        table.insert(sections, { title = "Docker", content = orbContent })
    end

    -- Audio section
    local audioContent = ""
    if info.audioDevice then
        local volStr = info.audioMuted and "muted" or (info.audioVolume .. "%")
        audioContent = string.format('<div class="item">🔊 %s (%s)</div>',
            escapeHtml(info.audioDevice), volStr)
    end
    if info.musicPlaying and info.musicTrack then
        audioContent = audioContent .. string.format('<div class="item">🎵 %s — %s</div>',
            escapeHtml(info.musicArtist or ""), escapeHtml(info.musicTrack))
    end
    if audioContent ~= "" then
        table.insert(sections, { title = "Audio", content = audioContent })
    end

    -- Bluetooth section
    if #info.bluetoothDevices > 0 then
        local btContent = ""
        for _, name in ipairs(info.bluetoothDevices) do
            btContent = btContent .. string.format('<div class="item">%s %s</div>',
                statusDot(true), escapeHtml(name))
        end
        table.insert(sections, { title = "Bluetooth", content = btContent })
    else
        table.insert(sections, { title = "Bluetooth", content = '<div class="item dim">No devices connected</div>' })
    end

    -- USB section
    if #info.usbDevices > 0 then
        local usbContent = ""
        for _, name in ipairs(info.usbDevices) do
            usbContent = usbContent .. string.format('<div class="item">🔌 %s</div>', escapeHtml(name))
        end
        table.insert(sections, { title = "USB", content = usbContent })
    end

    -- Screens section
    if #info.screens > 0 then
        local screenContent = ""
        for _, name in ipairs(info.screens) do
            screenContent = screenContent .. string.format('<div class="item">🖥 %s</div>', escapeHtml(name))
        end
        table.insert(sections, { title = "Displays", content = screenContent })
    end

    -- Uptime
    table.insert(sections, { title = "Uptime", content = string.format(
        '<div class="item">⏱ %s</div>', formatUptime(info.uptime)) })

    -- VPN
    if info.vpn and info.vpn.month then
        local limit = info.vpn.limit or 1000000000000
        local pct = (info.vpn.month / limit) * 100
        local color
        if pct < 20 then color = "#83a598"      -- gruvbox blue (cyan-ish)
        elseif pct < 40 then color = "#b8bb26"   -- gruvbox green
        elseif pct < 60 then color = "#fabd2f"   -- gruvbox yellow
        elseif pct < 85 then color = "#d3869b"   -- gruvbox magenta
        else color = "#fb4934" end                -- gruvbox red

        local todayStr = info.vpn.today and formatBytes(info.vpn.today) or "—"
        local monthStr = formatBytes(info.vpn.month)
        local limitStr = formatBytes(limit)

        local barWidth = 20
        local filled = math.floor((pct / 100) * barWidth)
        if filled > barWidth then filled = barWidth end
        if filled == 0 and pct > 0 then filled = 1 end
        local bar = string.rep("█", filled) .. string.rep("░", barWidth - filled)

        local vpnContent = string.format(
            '<div class="item">📅 Today: <span style="color:%s">%s</span></div>' ..
            '<div class="item">📊 Month: <span style="color:%s">%s</span> / %s</div>' ..
            '<div class="item" style="font-family:monospace"><span style="color:%s">%s</span> %.1f%%</div>',
            color, todayStr,
            color, monthStr, limitStr,
            color, bar, pct)
        table.insert(sections, { title = info.vpn.label or "VPN", content = vpnContent })
    end

    -- Build HTML
    local sectionsHtml = ""
    for _, s in ipairs(sections) do
        sectionsHtml = sectionsHtml .. string.format(
            '<div class="section"><div class="section-title">%s</div>%s</div>',
            s.title, s.content)
    end

    return [[<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
        background: #1d2021;
        color: #ebdbb2;
        font-family: "JetBrainsMono Nerd Font", "SF Mono", monospace;
        font-size: 12px;
        padding: 16px;
        user-select: none;
        -webkit-user-select: none;
    }
    .header {
        color: #fe8019;
        font-size: 14px;
        font-weight: bold;
        margin-bottom: 12px;
        padding-bottom: 8px;
        border-bottom: 1px solid #3c3836;
    }
    .grid {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 12px;
    }
    .section {
        background: #282828;
        border-radius: 6px;
        padding: 10px 12px;
        border: 1px solid #3c3836;
    }
    .section-title {
        color: #83a598;
        font-size: 11px;
        font-weight: bold;
        text-transform: uppercase;
        letter-spacing: 1px;
        margin-bottom: 6px;
    }
    .item { padding: 2px 0; }
    .item.sub { padding-left: 20px; color: #928374; font-size: 11px; }
    .dim { color: #665c54; }
    .footer {
        text-align: center;
        color: #665c54;
        font-size: 10px;
        margin-top: 12px;
        padding-top: 8px;
        border-top: 1px solid #3c3836;
    }
</style>
</head>
<body>
    <div class="header">System Health</div>
    <div class="grid">]] .. sectionsHtml .. [[</div>
    <div class="footer">Press Esc to close</div>
</body>
</html>]]
end

local function showWebview(html)
    local screen = hs.screen.mainScreen():frame()
    local width = 520
    local height = 560
    local x = screen.x + (screen.w - width) / 2
    local y = screen.y + (screen.h - height) / 2

    healthWebview = hs.webview.new({ x = x, y = y, w = width, h = height })
    healthWebview:windowStyle({ "titled", "closable" })
    healthWebview:shadow(true)
    healthWebview:windowTitle("System Health")
    healthWebview:html(html)
    healthWebview:bringToFront(true)
    healthWebview:show()

    healthWebview:windowCallback(function(action)
        if action == "closing" then
            healthWebview = nil
            asyncTasks = nil
            if healthEscHotkey then healthEscHotkey:disable() end
        end
        return false
    end)

    if not healthEscHotkey then
        healthEscHotkey = hs.hotkey.new({}, "escape", function()
            if healthWebview then
                healthWebview:delete()
                healthWebview = nil
                asyncTasks = nil
            end
            healthEscHotkey:disable()
        end)
    end
    healthEscHotkey:enable()
end

function M.toggle()
    if healthWebview then
        healthWebview:delete()
        healthWebview = nil
        asyncTasks = nil
        if healthEscHotkey then healthEscHotkey:disable() end
        return
    end

    -- Show dashboard immediately with fast data
    local info = gatherFastInfo()
    showWebview(buildHtml(info))

    -- Fire slow calls async; re-render when all complete
    asyncTasks = gatherSlowInfoAsync(info, function()
        asyncTasks = nil
        if healthWebview then
            healthWebview:html(buildHtml(info))
        end
    end)
end

return M
