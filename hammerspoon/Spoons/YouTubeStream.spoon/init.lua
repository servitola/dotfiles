local obj = {}
obj.__index = obj

obj.name = "YouTubeStream"
obj.version = "1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.videoId = "jfKfPfyJRdk"

obj.webview = nil

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

function obj:createWebview()
    local screen = hs.screen.mainScreen()
    local corner = spoon.PowerWindows:slotRect("corner", screen)
    local video = spoon.PowerWindows:slotRect("video", screen)
    local x, y, width, height = corner.x, corner.y, corner.w, corner.h

    local aspect_ratio = 9/16
    if height > video.h then
        height = video.h
        width = height / aspect_ratio
    end

    if self.webview then
        return self.webview
    end

    self.webview = hs.webview.new({x = x, y = y, w = width, h = height})
    self.webview:windowStyle({"titled", "closable", "resizable"})
    self.webview:shadow(true)
    self.webview:allowTextEntry(true)
    self.webview:windowTitle("YouTube Stream")

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

    self.webview:html(getHtmlContent(self.videoId))

    return self.webview
end

function obj:toggle()
    if self.webview and self.webview:hswindow() and self.webview:hswindow():isVisible() then
        self.webview:evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"pauseVideo\",\"args\":[]}', '*')")
        hs.timer.doAfter(0.1, function()
            if self.webview then
                self.webview:hide()
            end
        end)
    else
        self:show()

        local hswin = self.webview and self.webview:hswindow()
        if hswin and not hswin:isVisible() then
            hs.timer.doAfter(0.5, function()
                if self.webview then
                    self.webview:evaluateJavaScript("document.querySelector('iframe').contentWindow.postMessage('{\"event\":\"command\",\"func\":\"playVideo\",\"args\":[]}', '*')")
                end
            end)
        end
    end
end

function obj:show()
    if self.webview then
        self.webview:show()
    else
        self:createWebview()
        self.webview:show()
    end
end

function obj:openYouTubeStream()
    self:show()
end

return obj
