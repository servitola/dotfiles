local notify = require("notify")
local constants = require("constants")

-- ~/.local/bin/rec → ~/Applications/rec.app; `rec toggle` launches the recorder through `open`,
-- so TCC attributes Screen Recording and Microphone to rec, not to Hammerspoon.
local REC = os.getenv("HOME") .. "/.local/bin/rec"
local bar, timer

local function hideBar()
    if timer then timer:stop(); timer = nil end
    if bar then bar:delete(); bar = nil end
end

local function refresh()
    hs.task.new(REC, function(_, out)
        local ok, st = pcall(hs.json.decode, out)
        if not (ok and st and st.recording) then hideBar() return end
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
    hs.task.new(REC, function(code, out, err)
        if code ~= 0 then
            notify.show({ title = "rec", message = ((err ~= "" and err) or out):sub(1, 120), symbol = "record.circle", tint = "red", duration = 6 })
            return
        end
        local ok, r = pcall(hs.json.decode, out)
        if not (ok and r) then return end
        if r.action == "started" then
            notify.show({ title = "rec " .. r.mode, message = "recording", symbol = "record.circle.fill", tint = "red", duration = 1.5 })
            showBar()
        else
            hideBar()
            notify.show({ title = "rec saved", message = r.path:match("[^/]+$"), symbol = "checkmark.circle", tint = "green", duration = 4 })
        end
    end, { "toggle", mode, "--out", constants.DIR_REC }):start()
end

showBar() -- a recording that outlived a Hammerspoon reload keeps its timer; idle hides it on the first poll

return function(register)
    register("rec.audio", function() toggle("audio") end)
    register("rec.video", function() toggle("video") end)
    register("rec.video_mic", function() toggle("video-mic") end)
end
