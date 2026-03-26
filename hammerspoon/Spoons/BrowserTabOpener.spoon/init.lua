local obj = {}
obj.__index = obj

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

            set nextPos to 1
            if currentMatchPos > 0 and currentMatchPos < (count of matchedTabs) then
                set nextPos to currentMatchPos + 1
            else if currentMatchPos = (count of matchedTabs) then
                set nextPos to 1
            end if

            set active tab index of front window to item nextPos of matchedTabs
            activate
            return "ok"
        end tell
    ]], urlPattern:gsub('"', '\\"'))

    local success, result, err = hs.osascript.applescript(script)

    if not success then
        hs.logger.new('BrowserTabOpener'):d("AppleScript error: " .. tostring(err))
    end

    if success and result == "ok" then
        -- Tab found and switched — just focus the browser
    else
        hs.application.launchOrFocus("Yandex")
        hs.timer.doAfter(0.1, function()
            hs.urlevent.openURLWithBundle("https://" .. urlPattern, "ru.yandex.desktop.yandex-browser")
        end)
    end
end

return obj
