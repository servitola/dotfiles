-- Every chord in the HotKeys layout tables is a live hotkey in the running Hammerspoon.
local hotkeys = spoon.HotKeys
local live = {}
for _, hotkey in ipairs(hs.hotkey.getHotkeys()) do live[hotkey.idx] = true end

local dead, total = {}, 0
local logLevel = hs.hotkey.getLogLevel()
hs.hotkey.setLogLevel("warning")   -- each probe would log its own creation and deletion
for _, entry in ipairs(hotkeys.chords) do
    if entry.fn or entry.app or entry.sendKey then
        total = total + 1
        local mods, key = hotkeys.parseChord(entry.chord)
        local probe = hs.hotkey.new(mods, key, function() end)
        if not (probe and live[probe.idx]) then table.insert(dead, entry.chord) end
        if probe then probe:delete() end
    end
end
hs.hotkey.setLogLevel(logLevel)
for _, missing in ipairs(hotkeys.report.missing) do
    table.insert(dead, missing.chord .. " (no action " .. missing.fn .. ")")
end

for _, chord in ipairs(dead) do print("dead: " .. chord) end
print(("%d of %d chords live"):format(total - #dead, total))
if #dead > 0 then error("dead chords") end
