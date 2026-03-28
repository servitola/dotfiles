-- Internet search helper
local M = {}

function M.searchSelectedText()
    local currentApp = hs.application.frontmostApplication()
    if not currentApp then return end

    local selectedText = nil

    -- Try native accessibility API
    local systemElement = hs.axuielement.systemWideElement()
    local focusedElement = systemElement:attributeValue("AXFocusedUIElement")
    if focusedElement then
        selectedText = focusedElement:attributeValue("AXSelectedText")
    end

    if selectedText and selectedText ~= "" then
        local encoded = hs.http.encodeForQuery(selectedText)
        local url = string.format("https://www.perplexity.ai/search?q=%s", encoded)
        hs.urlevent.openURL(url)
        return
    end

    -- Fallback: copy to clipboard async, then read
    hs.eventtap.keyStroke({"cmd"}, "c")
    hs.timer.doAfter(0.15, function()
        local clipText = hs.pasteboard.getContents()
        if clipText and clipText ~= "" then
            local encoded = hs.http.encodeForQuery(clipText)
            local url = string.format("https://www.perplexity.ai/search?q=%s", encoded)
            hs.urlevent.openURL(url)
        end
    end)
end

return M
