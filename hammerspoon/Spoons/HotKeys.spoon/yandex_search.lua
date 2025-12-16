-- Internet search helper
local M = {}

function M.searchSelectedText()
    local currentApp = hs.application.frontmostApplication()
    local appName = currentApp:name()

    local selectedText = nil

    -- Try native accessibility API
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

    if selectedText and selectedText ~= "" then
        local encoded = hs.http.encodeForQuery(selectedText)
        local url = string.format("https://www.perplexity.ai/search?q=%s", encoded)
        hs.urlevent.openURL(url)
    end
end

return M
