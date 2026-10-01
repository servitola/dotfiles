local obj = {}
obj.__index = obj

-- Metadata
obj.name = "YouTrackTasks"
obj.version = "1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.youTrackUrl = "https://REDACTED-TRACKER"

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
    self.webview:windowTitle("My YouTrack Tasks")

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
    local tasksUrl = obj.youTrackUrl .. "/issues?q=for%3A%20me%20State%3A%20%7BTo%20Do%7D%2C%20%7BIn%20Progress%7D%20"

    webview:url(tasksUrl)
    webview:show()
    webview:hswindow():focus()
end

return obj
