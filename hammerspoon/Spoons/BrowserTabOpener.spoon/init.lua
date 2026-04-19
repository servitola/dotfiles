local obj = {}
obj.__index = obj

obj._task = nil  -- prevent GC of running hs.task

function obj:openTab(urlPattern)
    local script = string.format([[
        tell application "Yandex"
            set matchedTabs to {}
            set currentMatchPos to 0
            set currentActive to active tab index of front window

            set tabCounter to 0
            repeat with t in tabs of front window
                set tabCounter to tabCounter + 1
                if URL of t contains "%s" then
                    set end of matchedTabs to tabCounter
                    if tabCounter = currentActive then
                        set currentMatchPos to (count of matchedTabs)
                    end if
                end if
            end repeat

            if (count of matchedTabs) = 0 then
                return "none"
            end if

            set nextPos to (count of matchedTabs)
            if currentMatchPos > 1 then
                set nextPos to currentMatchPos - 1
            else if currentMatchPos = 1 then
                set nextPos to (count of matchedTabs)
            end if

            set active tab index of front window to item nextPos of matchedTabs
            activate
            return "ok"
        end tell
    ]], urlPattern:gsub('"', '\\"'))

    self._task = hs.task.new("/usr/bin/osascript", function(exitCode, stdout, stderr)
        self._task = nil
        local result = stdout and stdout:gsub("%s+$", "") or ""

        if exitCode ~= 0 then
            hs.logger.new('BrowserTabOpener'):d("AppleScript error: " .. tostring(stderr))
        end

        if result == "ok" then
            -- Tab found and switched
        else
            hs.application.launchOrFocus("Yandex")
            hs.timer.doAfter(0.1, function()
                hs.urlevent.openURLWithBundle("https://" .. urlPattern, "ru.yandex.desktop.yandex-browser")
            end)
        end
    end, {"-e", script})
    self._task:start()
end

function obj:focusPlayingTab(urlPattern)
    local script = string.format([[
        tell application "Yandex"
            set firstMatchTab to 0
            set playingTab to 0

            set tabCounter to 0
            repeat with t in tabs of front window
                set tabCounter to tabCounter + 1
                if URL of t contains "%s" then
                    if firstMatchTab = 0 then
                        set firstMatchTab to tabCounter
                    end if
                    try
                        set jsResult to (execute t javascript "String(!document.querySelector('video')?.paused)")
                        if jsResult = "true" then
                            set playingTab to tabCounter
                            exit repeat
                        end if
                    end try
                end if
            end repeat

            if playingTab > 0 then
                set active tab index of front window to playingTab
                activate
                return "ok"
            else if firstMatchTab > 0 then
                set active tab index of front window to firstMatchTab
                activate
                return "ok"
            else
                return "none"
            end if
        end tell
    ]], urlPattern:gsub('"', '\\"'))

    self._task = hs.task.new("/usr/bin/osascript", function(exitCode, stdout, stderr)
        self._task = nil
        local result = stdout and stdout:gsub("%s+$", "") or ""

        if exitCode ~= 0 then
            hs.logger.new('BrowserTabOpener'):d("AppleScript error: " .. tostring(stderr))
        end

        if result == "ok" then
            -- Tab found and switched
        else
            hs.application.launchOrFocus("Yandex")
            hs.timer.doAfter(0.1, function()
                hs.urlevent.openURLWithBundle("https://youtube.com", "ru.yandex.desktop.yandex-browser")
            end)
        end
    end, {"-e", script})
    self._task:start()
end

return obj
