hsreload_keys = hsreload_keys or {{"cmd", "shift", "ctrl"}, "R"}
if string.len(hsreload_keys[2]) > 0 then
    hs.hotkey.bind(hsreload_keys[1], hsreload_keys[2], "Reload Configuration", function() hs.reload() end)
end

-- Register Hammerspoon console
-- hsconsole_keys = hsconsole_keys or {"alt", "Z"}
-- if string.len(hsconsole_keys[2]) > 0 then
--     spoon.ModalMgr.supervisor:bind(hsconsole_keys[1], hsconsole_keys[2], "Toggle Hammerspoon Console", function() hs.toggleConsole() end)
-- end

-- Register AClock
if spoon.AClock then
    hsaclock_keys = hsaclock_keys or {"alt", "T"}
    if string.len(hsaclock_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(hsaclock_keys[1], hsaclock_keys[2], "Toggle Floating Clock", function()
            spoon.AClock:toggleShow()
        end)
    end
end

-- Register browser tab typist: Type URL of current tab of running browser in markdown format. i.e. [title](link)
hstype_keys = hstype_keys or {"alt", "V"}
if string.len(hstype_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hstype_keys[1], hstype_keys[2], "Type Browser Link", function()
        local safari_running = hs.application.applicationsForBundleID("com.apple.Safari")
        local chrome_running = hs.application.applicationsForBundleID("com.google.Chrome")
        if #safari_running > 0 then
            local stat, data = hs.applescript('tell application "Safari" to get {URL, name} of current tab of window 1')
            if stat then
                hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")")
            end
        elseif #chrome_running > 0 then
            local stat, data = hs.applescript(
                                   'tell application "Google Chrome" to get {URL, title} of active tab of window 1')
            if stat then
                hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")")
            end
        end
    end)
end