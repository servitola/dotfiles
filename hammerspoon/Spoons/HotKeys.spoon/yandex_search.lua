-- Internet search helper
local M = {}

local function isElectronApp(appName)
    local electronApps = {
        "Visual Studio Code",
        "VSCode",
        "Cursor",
        "Slack",
        "Discord",
        "Figma",
        "Whisk",
    }
    for _, app in ipairs(electronApps) do
        if appName:find(app, 1, true) then
            return true
        end
    end
    return false
end

function M.searchSelectedText()
    local currentApp = hs.application.frontmostApplication()
    local appName = currentApp:name()

    local selectedText = nil

    if isElectronApp(appName) then
        -- Fallback for Electron apps: use clipboard
        -- First, copy selected text
        hs.eventtap.keyStroke({"cmd"}, "c")
        -- Give a tiny delay for the copy to complete
        hs.timer.usleep(100000) -- 100ms
        -- Read from clipboard
        selectedText = hs.pasteboard.getContents()
    else
        -- Try native accessibility API for non-Electron apps
        local systemElement = hs.axuielement.systemWideElement()
        local focusedElement = systemElement:attributeValue("AXFocusedUIElement")
        if focusedElement then
            selectedText = focusedElement:attributeValue("AXSelectedText")
        end

        -- Fallback to clipboard if no selection found
        if not selectedText or selectedText == "" then
            hs.eventtap.keyStroke({"cmd"}, "c")
            hs.timer.usleep(100000)
            selectedText = hs.pasteboard.getContents()
        end
    end

    if selectedText and selectedText ~= "" then
        local encoded = hs.http.encodeForQuery(selectedText)
        local url = string.format("https://www.perplexity.ai/search?q=%s", encoded)
        hs.urlevent.openURL(url)
    end
end

return M
