---
--- Open first needed tab from Yandex Browser
---

local obj = {}
obj.__index = obj

obj.name = "BrowserTabOpener"
obj.version = "1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

function obj:openTab(urlPattern)
    local success, urls, err = hs.osascript.applescript([[
        tell application "Yandex"
            set urlList to ""
            repeat with w in windows
                repeat with t in tabs of w
                    set urlList to urlList & URL of t & ", "
                end repeat
            end repeat
            return text 1 thru -3 of urlList
        end tell
    ]])

    if success then

        for url in string.gmatch(urls, "[^,]+") do
            url = url:match("^%s*(.-)%s*$")
            if string.match(url, urlPattern) then
                hs.application.launchOrFocus("Yandex")
                hs.timer.doAfter(0.1, function()
                    hs.urlevent.openURLWithBundle(url, "ru.yandex.desktop.yandex-browser")
                end)
                return
            end
        end

        hs.application.launchOrFocus("Yandex")
        hs.timer.doAfter(0.1, function()
            hs.urlevent.openURLWithBundle(urlPattern, "ru.yandex.desktop.yandex-browser")
        end)
    else
        hs.alert.show("Error getting Yandex tabs: " .. (err or "unknown error"))
    end
end

return obj
