local notify = require("notify")
local constants = require("constants")

-- ~/.local/bin/rec → ~/Applications/rec.app; `rec toggle` launches the recorder through `open`,
-- so TCC attributes Screen Recording and Microphone to rec, not to Hammerspoon.
local REC = os.getenv("HOME") .. "/.local/bin/rec"
local LOG = os.getenv("HOME") .. "/Library/Logs/rec.log"
local bar, timer
local wasRecording, inflight, cancelRequested = false, 0, false

local function hideBar()
    if timer then timer:stop(); timer = nil end
    if bar then bar:delete(); bar = nil end
end

local function lastFinished()
    local f = io.open(LOG, "r")
    if not f then return nil end
    local last
    for line in f:lines() do
        if line:find("finished", 1, true) then last = line end
    end
    f:close()
    if not last then return nil end
    return (last:gsub("^%S+%s+", ""):sub(1, 120))
end

local seenFinished = lastFinished()

local function unhealthy(line)
    if line:find("error=", 1, true) or line:find("mic lost", 1, true) then return true end
    for drops in line:gmatch("drops=(%S+)") do
        if drops ~= "[:]" then return true end
    end
    return false
end

local function announceEnd()
    local line = lastFinished()
    if line == seenFinished then return end
    seenFinished = line
    line = line or "no finished line in rec.log"
    local failed = unhealthy(line)
    notify.show({ title = "rec ended", message = line, symbol = failed and "exclamationmark.triangle" or "checkmark.circle", tint = failed and "red" or "green", duration = 8 })
end

local function refresh()
    hs.task.new(REC, function(_, out)
        if timer == nil then return end
        local ok, st = pcall(hs.json.decode, out)
        local recording = ok and st and st.recording
        if recording and not wasRecording then seenFinished = lastFinished() end
        if wasRecording and not recording and inflight == 0 then announceEnd() end
        wasRecording = recording and true or false
        if not recording then hideBar() return end
        if not bar then
            bar = hs.menubar.new()
            bar:setClickCallback(function() hs.execute(string.format("open -R %q", st.path)) end)
        end
        local s = math.floor(st.elapsed)
        bar:setTitle(hs.styledtext.new(string.format("● %02d:%02d", s // 60, s % 60), { color = { red = 0.9, green = 0.1, blue = 0.1 } }))
        bar:setTooltip(st.mode .. " → " .. st.path)
    end, { "status", "--json" }):start()
end

local function showBar()
    refresh()
    timer = timer or hs.timer.doEvery(1, refresh)
end

local function toggle(mode)
    if inflight > 0 then cancelRequested = true end
    local overlapped = inflight > 0
    inflight = inflight + 1
    local task = hs.task.new(REC, function(code, out, err)
        local cancelled = cancelRequested
        inflight = inflight - 1
        if inflight == 0 then cancelRequested = false end
        if code ~= 0 then
            if cancelled or overlapped then return end
            notify.show({ title = "rec", message = ((err ~= "" and err) or out):sub(1, 120), symbol = "record.circle", tint = "red", duration = 6 })
            return
        end
        local ok, r = pcall(hs.json.decode, out)
        if not (ok and r) then return end
        if r.action == "started" then
            seenFinished = lastFinished()
            notify.show({ title = "rec " .. r.mode, message = "recording", symbol = "record.circle.fill", tint = "red", duration = 1.5 })
            showBar()
            return
        end
        hideBar()
        wasRecording = false
        if r.phase == "starting" or overlapped then
            notify.show({ title = "rec cancelled", symbol = "record.circle", duration = 3 })
            return
        end
        local line = lastFinished()
        seenFinished = line
        if line and unhealthy(line) then
            notify.show({ title = "rec saved", message = line:sub(1, 120), symbol = "exclamationmark.triangle", tint = "red", duration = 8 })
        else
            notify.show({ title = "rec saved", message = r.path:match("[^/]+$"), symbol = "checkmark.circle", tint = "green", duration = 4 })
        end
    end, { "toggle", mode, "--out", constants.DIR_REC })
    if not (task and task:start()) then
        inflight = inflight - 1
        if inflight == 0 then cancelRequested = false end
    end
end

showBar() -- a recording that outlived a Hammerspoon reload keeps its timer; idle hides it on the first poll

return function(register)
    register("rec.audio", function() toggle("audio") end)
    register("rec.video", function() toggle("video") end)
    register("rec.video_mic", function() toggle("video-mic") end)
end
