local obj = {}
obj.__index = obj

-- Metadata
obj.name = "YouTrackTicket"
obj.version = "1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.youTrackUrl = nil  -- set by the config: the server, without a trailing slash
obj.project = nil      -- set by the config: the project new tickets go to

-- Internal function to create the webview
function obj:createWebview()
    local screen = hs.screen.mainScreen()
    local main = spoon.PowerWindows:slotRect("main", screen)
    local x, y, width, height = main.x, main.y, main.w, main.h

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
    local createTicketUrl = obj.youTrackUrl .. "/newIssue?project=" .. obj.project .. "&c=Type%20Task&c=State%20In%20Progress"

    webview:url(createTicketUrl)
    webview:show()
    webview:hswindow():focus()
end

return obj
