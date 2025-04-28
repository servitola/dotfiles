local obj = {}
obj.__index = obj

-- Metadata
obj.name = "YouTubeStream"
obj.version = "1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.videoId = "jfKfPfyJRdk"

-- Store webview object
obj.webview = nil

-- Window positioning constants from Windows.spoon/config.lua
local margin = 0.005
local spacing = margin * 2
local vertical_line = 0.73
local horizontal_line = 0.70
local rightX = 1 - margin / 1.5

-- HTML template for the embedded YouTube player
local function getHtmlContent(videoId)
    return [[<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <style>
        body, html {
            margin: 0;
            padding: 0;
            width: 100%;
            height: 100%;
            overflow: hidden;
            background-color: #000;
        }
        .video-container {
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
        }
        iframe {
            width: 100%;
            height: 100%;
            border: none;
        }
    </style>
</head>
<body>
    <div class="video-container">
        <iframe 
            src="https://www.youtube.com/embed/]] .. videoId .. [[?autoplay=1&controls=1&rel=0&showinfo=0&color=white&enablejsapi=1" 
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
            allowfullscreen
            id="player">
        </iframe>
    </div>
    <script src="https://www.youtube.com/iframe_api"></script>
    <script>
        // Add keyboard shortcuts for controlling the player
        document.addEventListener('keydown', function(e) {
            const iframe = document.querySelector('iframe');
            const player = iframe.contentWindow;
            
            // Space: Play/Pause
            if (e.keyCode === 32) {
                player.postMessage('{"event":"command","func":"togglePlayPause","args":[]}', '*');
                e.preventDefault();
            }
            // Left Arrow: Rewind 10 seconds
            else if (e.keyCode === 37) {
                player.postMessage('{"event":"command","func":"seekTo","args":[player.getCurrentTime() - 10]}', '*');
                e.preventDefault();
            }
            // Right Arrow: Forward 10 seconds
            else if (e.keyCode === 39) {
                player.postMessage('{"event":"command","func":"seekTo","args":[player.getCurrentTime() + 10]}', '*');
                e.preventDefault();
            }
            // Up Arrow: Volume Up
            else if (e.keyCode === 38) {
                player.postMessage('{"event":"command","func":"setVolume","args":[Math.min(player.getVolume() + 10, 100)]}', '*');
                e.preventDefault();
            }
            // Down Arrow: Volume Down
            else if (e.keyCode === 40) {
                player.postMessage('{"event":"command","func":"setVolume","args":[Math.max(player.getVolume() - 10, 0)]}', '*');
                e.preventDefault();
            }
        });
    </script>
</body>
</html>]]
end

-- Internal function to create the webview
function obj:createWebview()
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()

    -- Position window at the bottom right according to Windows.spoon logic
    local x = frame.x + (frame.w * vertical_line)
    local y = frame.y + (frame.h * (horizontal_line + spacing))
    local width = frame.w * (rightX - vertical_line)
    local height = frame.h * (1 - horizontal_line - spacing)
    
    -- Calculate aspect ratio for video (16:9)
    local aspect_ratio = 9/16
    local max_available_height = frame.h * (1 - horizontal_line - spacing * 2)
    
    -- Adjust height and width based on aspect ratio
    if height > max_available_height then
        height = max_available_height
        width = height / aspect_ratio
    end

    if self.webview then
        return self.webview
    end

    -- Create and configure webview
    self.webview = hs.webview.new({x = x, y = y, w = width, h = height})
    self.webview:windowStyle({"titled", "closable", "resizable"})
    self.webview:shadow(true)
    self.webview:allowTextEntry(true)
    self.webview:windowTitle("YouTube Stream")

    -- Handle window closing
    self.webview:windowCallback(function(action)
        if action == "closing" then
            -- Stop the stream by loading a blank page before destroying
            self.webview:html("<html><body></body></html>")
            -- Small delay to ensure the blank page loads before destroying
            hs.timer.doAfter(0.1, function()
                if self.webview then
                    self.webview:delete()
                    self.webview = nil
                end
            end)
        end
        return false
    end)

    -- Load the embedded YouTube player HTML
    self.webview:html(getHtmlContent(self.videoId))

    return self.webview
end

-- Toggle the webview visibility
function obj:toggle()
    if self.webview and self.webview:hswindow() and self.webview:hswindow():isVisible() then
        -- If window is visible, hide it and pause the stream
        self.webview:evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"pauseVideo\",\"args\":[]}', '*')")
        hs.timer.doAfter(0.1, function()
            if self.webview then
                self.webview:hide()
            end
        end)
    else
        -- If window is hidden or doesn't exist, show it
        self:show()
        
        -- If window exists and was previously hidden, resume playback
        if self.webview and not self.webview:hswindow():isVisible() then
            hs.timer.doAfter(0.5, function()
                if self.webview then
                    self.webview:evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":[]}', '*')")
                end
            end)
        end
    end
end

-- Show the webview
function obj:show()
    if self.webview then
        self.webview:show()
    else
        self:createWebview()
        self.webview:show()
    end
end

-- Main function to open or focus the YouTube stream
function obj:openYouTubeStream()
    self:show()
end

return obj
