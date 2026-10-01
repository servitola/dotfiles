--- === ScreenGlow ===
---
--- Soft pulsing glow along every screen edge while an agent drives the desktop.
--- `pulse(seconds, phase, text)` starts or extends it (phase = think | act | wait),
--- `beat()` flashes on activity, `stop()` fades it out; a watchdog stops it at
--- the deadline so a dead agent never leaves the screen glowing.

local obj = {}
obj.__index = obj

-- Loaded up front: lazy-loading several extensions inside one `hs -c` call
-- floods the ipc print hook ("already recursing") into a stack overflow.
local _ = { hs.canvas, hs.image, hs.sound, hs.menubar, hs.styledtext, hs.eventtap, hs.window, hs.screen, hs.timer }

obj.name = "ScreenGlow"
obj.version = "0.1.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/ScreenGlow.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"
obj.phases = {
    think = { hex = "#fe8019" },
    act   = { hex = "#8ec07c" },
    wait  = { hex = "#fb4934" },
}
obj.layers = 15
obj.layer_width = 2.5
obj.layer_alpha = 0.11
obj.corner_radius = 52
obj.alpha_min = 0.4
obj.alpha_max = 0.85
obj.period = 2.4
obj.fade_in = 1.4
obj.fade_out = 0.8
obj.beat_decay = 0.5
obj.subtitle_font = 34
obj.spotlight_alpha = 0.4
obj.spotlight_radius = 14
obj.focus_ring_width = 3
obj.focus_ring_pad = 4
obj.wallpaper_breath = 0.3
obj.wallpaper_tint = 0.35
obj.ripple_duration = 0.6
obj.ripple_radius = 44
obj.sound_start = "Glass"
obj.sound_stop = "Pop"

local TICK = 0.03

obj._canvases = {}
obj._pulse_timer = nil
obj._watchdog = nil
obj._screen_watcher = nil
obj._menubar = nil
obj._t = 0
obj._fading_out = nil
obj._beat_at = nil
obj._phase = "think"
obj._started_at = nil
obj._subtitle = nil
obj._click_tap = nil
obj._ripples = {}
obj._spot = {}
obj._veils = {}
obj._spot_timer = nil
obj._wallpaper_color = nil

local function ease(x)
    return x * x * (3 - 2 * x)
end

local function hex_to_rgb(hex)
    return tonumber(hex:sub(2, 3), 16) / 255, tonumber(hex:sub(4, 5), 16) / 255, tonumber(hex:sub(6, 7), 16) / 255
end

function obj:_color(alpha)
    local r, g, b = hex_to_rgb(self.phases[self._phase].hex)
    local wp = self._wallpaper_color
    if wp and self._phase == "think" then
        local k = self.wallpaper_tint
        r, g, b = r * (1 - k) + wp.red * k, g * (1 - k) + wp.green * k, b * (1 - k) + wp.blue * k
    end
    return { red = r, green = g, blue = b, alpha = alpha }
end

function obj:_sample_wallpaper()
    local url = hs.screen.primaryScreen():desktopImageURL()
    local img = url and hs.image.imageFromURL(url)
    if not img then return nil end
    img:setSize({ w = 4, h = 4 })
    local sum = { red = 0, green = 0, blue = 0 }
    for x = 0, 3 do
        for y = 0, 3 do
            local c = img:colorAt({ x = x, y = y })
            sum.red, sum.green, sum.blue = sum.red + c.red, sum.green + c.green, sum.blue + c.blue
        end
    end
    return { red = sum.red / 16, green = sum.green / 16, blue = sum.blue / 16 }
end

local function overlay_canvas(frame, level)
    local c = hs.canvas.new(frame)
    c:level(level)
    c:behavior({ "canJoinAllSpaces", "stationary", "ignoresCycle" })
    c:canvasMouseEvents(false, false, false, false)
    c:clickActivating(false)
    return c
end

function obj:_build_veils()
    for _, c in ipairs(self._veils) do c:delete() end
    self._veils = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        local c = overlay_canvas(screen:fullFrame(), hs.canvas.windowLevels.desktopIcon)
        c[1] = { type = "rectangle", action = "fill", fillColor = { hex = "#000000", alpha = 1 } }
        c:alpha(0)
        c:show()
        table.insert(self._veils, c)
    end
end

function obj:_build_spotlight()
    for _, e in ipairs(self._spot) do e.canvas:delete() end
    self._spot = {}
    for _, screen in ipairs(hs.screen.allScreens()) do
        local f = screen:fullFrame()
        local c = overlay_canvas(f, hs.canvas.windowLevels.overlay)
        c[1] = { type = "rectangle", action = "build", frame = { x = 0, y = 0, w = f.w, h = f.h } }
        c[2] = { type = "rectangle", action = "fill", reversePath = true,
                 fillColor = { hex = "#000000", alpha = self.spotlight_alpha },
                 roundedRectRadii = { xRadius = self.spotlight_radius, yRadius = self.spotlight_radius },
                 frame = { x = 0, y = 0, w = 0, h = 0 } }
        -- soft halo under a crisp ring, both hugging the focused window
        c[3] = { type = "rectangle", action = "stroke", strokeWidth = self.focus_ring_width * 5,
                 strokeColor = self:_color(0.22),
                 roundedRectRadii = { xRadius = self.spotlight_radius + 6, yRadius = self.spotlight_radius + 6 },
                 frame = { x = 0, y = 0, w = 0, h = 0 } }
        c[4] = { type = "rectangle", action = "stroke", strokeWidth = self.focus_ring_width,
                 strokeColor = self:_color(0.95),
                 roundedRectRadii = { xRadius = self.spotlight_radius + 4, yRadius = self.spotlight_radius + 4 },
                 frame = { x = 0, y = 0, w = 0, h = 0 } }
        c:alpha(0)
        c:show()
        table.insert(self._spot, { canvas = c, frame = f })
    end
    self:_track_focus()
end

function obj:_track_focus()
    local win = hs.window.focusedWindow()
    local wf = win and win:frame()
    for _, e in ipairs(self._spot) do
        local hole = wf and { x = wf.x - e.frame.x, y = wf.y - e.frame.y, w = wf.w, h = wf.h }
            or { x = 0, y = 0, w = 0, h = 0 }
        e.canvas[2].frame = hole
        local pad = self.focus_ring_pad
        local ring = { x = hole.x - pad, y = hole.y - pad, w = hole.w + 2 * pad, h = hole.h + 2 * pad }
        e.canvas[3].frame = ring
        e.canvas[4].frame = ring
    end
end

function obj:_build()
    self:_destroy()
    for _, screen in ipairs(hs.screen.allScreens()) do
        local f = screen:fullFrame()
        local c = hs.canvas.new({ x = f.x, y = f.y, w = f.w, h = f.h })
        c:level(hs.canvas.windowLevels.overlay)
        c:behavior({ "canJoinAllSpaces", "stationary", "ignoresCycle" })
        c:canvasMouseEvents(false, false, false, false)
        c:clickActivating(false)
        -- Each layer fills the ring between a rect past the screen edge and a
        -- rounded inset; stacked translucent rings feather inward and the
        -- outermost one covers the square screen corner. Stroked rounded
        -- rects left the corner bare and their offsets read as steps.
        local n = 0
        for i = 1, self.layers do
            local inset = i * self.layer_width
            local r = math.max(self.corner_radius - inset, self.layer_width)
            n = n + 1
            c[n] = { type = "rectangle", action = "build",
                     frame = { x = -100, y = -100, w = f.w + 200, h = f.h + 200 } }
            n = n + 1
            c[n] = {
                type = "rectangle",
                action = "fill",
                reversePath = true,
                fillColor = self:_color(self.layer_alpha),
                roundedRectRadii = { xRadius = r, yRadius = r },
                frame = { x = inset, y = inset, w = f.w - 2 * inset, h = f.h - 2 * inset },
            }
        end
        c:show()
        c:alpha(0)
        table.insert(self._canvases, c)
    end
end

function obj:_destroy()
    for _, c in ipairs(self._canvases) do c:delete() end
    self._canvases = {}
end

function obj:_tick()
    self._t = self._t + TICK
    local phase = (1 - math.cos(2 * math.pi * self._t / self.period)) / 2
    local a = self.alpha_min + (self.alpha_max - self.alpha_min) * phase
    if self._beat_at then
        local age = self._t - self._beat_at
        a = math.min(1, a + 0.5 * math.exp(-age / self.beat_decay))
    end
    local envelope = ease(math.min(self._t / self.fade_in, 1))
    if self._fading_out then
        local left = 1 - (self._t - self._fading_out) / self.fade_out
        if left <= 0 then return self:_teardown() end
        envelope = envelope * ease(left)
    end
    for _, c in ipairs(self._canvases) do c:alpha(a * envelope) end
    for _, e in ipairs(self._spot) do e.canvas:alpha(envelope) end
    for _, c in ipairs(self._veils) do c:alpha(self.wallpaper_breath * phase * envelope) end
    if self._subtitle then self._subtitle:alpha(envelope) end
    self:_tick_ripples()
    if self._menubar and math.floor(self._t / TICK) % math.floor(1 / TICK) == 0 then
        self:_refresh_menubar()
    end
end

function obj:_show_subtitle(text)
    if self._subtitle then self._subtitle:delete() end
    self._subtitle = nil
    if not text or text == "" then return end
    local f = hs.screen.primaryScreen():fullFrame()
    local size = self.subtitle_font
    local h = size * 2.2
    local w = math.min(f.w * 0.8, size * 2 + utf8.len(text) * size * 0.58)
    local c = hs.canvas.new({ x = f.x + (f.w - w) / 2, y = f.y + f.h - h - 110, w = w, h = h })
    c:level(hs.canvas.windowLevels.overlay)
    c:behavior({ "canJoinAllSpaces", "stationary", "ignoresCycle" })
    c:canvasMouseEvents(false, false, false, false)
    c[1] = { type = "rectangle", action = "strokeAndFill", roundedRectRadii = { xRadius = h / 2, yRadius = h / 2 },
             fillColor = { hex = "#1d2021", alpha = 0.85 },
             strokeColor = self:_color(0.8), strokeWidth = 2 }
    c[2] = { type = "text", frame = { x = 0, y = (h - size * 1.3) / 2, w = w, h = size * 1.4 },
             text = hs.styledtext.new(text, { font = { name = ".AppleSystemUIFont", size = size },
                 color = { hex = "#fbf1c7" }, paragraphStyle = { alignment = "center" } }) }
    c:show()
    self._subtitle = c
end

function obj:_ripple(point)
    local r = self.ripple_radius
    local c = hs.canvas.new({ x = point.x - r, y = point.y - r, w = 2 * r, h = 2 * r })
    c:level(hs.canvas.windowLevels.overlay)
    c:behavior({ "canJoinAllSpaces", "stationary", "ignoresCycle" })
    c:canvasMouseEvents(false, false, false, false)
    c[1] = { type = "circle", action = "stroke", radius = 2, center = { x = r, y = r },
             strokeColor = self:_color(1), strokeWidth = 3 }
    c:show()
    table.insert(self._ripples, { canvas = c, born = self._t })
end

function obj:_tick_ripples()
    for i = #self._ripples, 1, -1 do
        local rp = self._ripples[i]
        local k = (self._t - rp.born) / self.ripple_duration
        if k >= 1 then
            rp.canvas:delete()
            table.remove(self._ripples, i)
        else
            rp.canvas[1].radius = 2 + (self.ripple_radius - 4) * ease(k)
            rp.canvas[1].strokeWidth = 3 * (1 - k)
            rp.canvas:alpha(1 - k)
        end
    end
end

-- hs.sound must stay referenced until playback ends or GC cuts it short.
function obj:_play(name)
    if not name then return end
    self._sound = hs.sound.getByName(name)
    if self._sound then self._sound:volume(1):play() end
end

function obj:_refresh_menubar()
    local elapsed = math.floor(os.time() - self._started_at)
    self._menubar:setTitle(string.format("🤖 %d:%02d", elapsed // 60, elapsed % 60))
end

function obj:pulse(seconds, phase, text)
    seconds = tonumber(seconds) or 45
    if text then self:_show_subtitle(text) end
    if self._watchdog then self._watchdog:stop() end
    self._watchdog = hs.timer.doAfter(seconds, function() self:stop() end)
    self._fading_out = nil
    if phase and self.phases[phase] and phase ~= self._phase then
        self._phase = phase
        if #self._canvases > 0 then self:_build() end
    elseif #self._canvases == 0 then
        self._phase = phase or "think"
    end
    if #self._canvases > 0 then return end
    self._t = 0
    self._started_at = os.time()
    self._wallpaper_color = self:_sample_wallpaper()
    self:_build()
    self:_build_veils()
    self:_build_spotlight()
    self._spot_timer = hs.timer.doEvery(0.25, function() self:_track_focus() end)
    self._pulse_timer = hs.timer.doEvery(TICK, function() self:_tick() end)
    self._screen_watcher = hs.screen.watcher.new(function()
        self:_build(); self:_build_veils(); self:_build_spotlight()
    end):start()
    self._menubar = hs.menubar.new():setClickCallback(function() self:stop() end)
    self:_refresh_menubar()
    self._click_tap = hs.eventtap.new({ hs.eventtap.event.types.leftMouseDown }, function(e)
        if #self._canvases > 0 then self:_ripple(e:location()) end
        return false
    end):start()
    self:_play(self.sound_start)
end

function obj:beat()
    if #self._canvases == 0 then return end
    self._beat_at = self._t
end

function obj:stop()
    if #self._canvases == 0 or self._fading_out then return end
    if self._watchdog then self._watchdog:stop() end
    self._watchdog = nil
    self._fading_out = self._t
    self:_play(self.sound_stop)
end

function obj:_teardown()
    -- explicit stops: ipairs over a list with a nil watchdog stopped early
    -- and left the click tap alive after the glow was gone
    for _, key in ipairs({ "_pulse_timer", "_watchdog", "_screen_watcher", "_click_tap", "_spot_timer" }) do
        if self[key] then self[key]:stop() end
    end
    if self._menubar then self._menubar:delete() end
    if self._subtitle then self._subtitle:delete() end
    for _, rp in ipairs(self._ripples) do rp.canvas:delete() end
    for _, e in ipairs(self._spot) do e.canvas:delete() end
    for _, c in ipairs(self._veils) do c:delete() end
    self._ripples, self._spot, self._veils, self._spot_timer = {}, {}, {}, nil
    self._pulse_timer, self._watchdog, self._screen_watcher, self._click_tap = nil, nil, nil, nil
    self._menubar, self._subtitle = nil, nil
    self._fading_out, self._beat_at, self._started_at = nil, nil, nil
    self:_destroy()
end

function obj:active()
    return #self._canvases > 0
end

return obj
