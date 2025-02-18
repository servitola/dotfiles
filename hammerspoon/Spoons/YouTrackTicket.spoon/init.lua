local obj = {}
obj.__index = obj

-- Metadata
obj.name = "YouTrackTicket"
obj.version = "1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.youTrackUrl = "https://yt.ctrader.com"

-- Window positioning constants
local margin = 0.005
local spacing = margin * 2
local leftX = margin
local topY = margin
local vertical_line = 0.73
local bottomY = 1 - margin * 1.5

-- Internal function to create the webview
function obj:createWebview()
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()

    -- Position window on the left side like Windows.spoon
    local width = frame.w * vertical_line - frame.w * spacing
    local height = frame.h * (bottomY - topY)
    local x = frame.x + frame.w * leftX
    local y = frame.y + frame.h * topY

    if self.webview then
        return self.webview
    end

    self.webview = hs.webview.new({x = x, y = y, w = width, h = height})
    self.webview:windowStyle({"titled", "closable", "resizable"})
    self.webview:shadow(true)
    self.webview:allowTextEntry(true)
    self.webview:windowTitle("Create YouTrack Ticket")

    -- Handle window closing
    self.webview:windowCallback(function(action)
        if action == "closing" then
            self.webview = nil
        end
        return false
    end)

    return self.webview
end

function obj:toggle()
    if self.webview and self.webview:hswindow() and self.webview:hswindow():isVisible() then
        self.webview:hide()
    else
        self:show()
    end
end

function obj:show()
    if self.webview then
        self.webview:show()
        self.webview:hswindow():focus()
        return
    end

    local webview = self:createWebview()
    local createTicketUrl = obj.youTrackUrl .. "/newIssue?project=CTXM&c=Type%20Task&c=State%20In%20Progress"

    webview:url(createTicketUrl)
    webview:show()
    webview:hswindow():focus()
end

return obj
