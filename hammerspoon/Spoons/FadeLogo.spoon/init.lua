local obj={}
obj.__index = obj

-- Metadata
obj.name = "FadeLogo"
obj.version = "0.3"
obj.author = "Diego Zamboni <diego@zzamboni.org>"
obj.homepage = "https://github.com/Hammerspoon/Spoons"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.image = hs.image.imageFromName(hs.image.systemImageNames.ApplicationIcon)
obj.image_size = hs.geometry.size(150, 150)
obj.image_alpha = 1.0
obj.zoom = true
obj.fade_in_time = 0.3
obj.fade_out_time = 0.4
obj.run_time = 1.5
obj.zoom_scale_factor = 0.9
obj.zoom_scale_timer = 0.01
obj.canvas = nil

function obj:show()
   local frame = hs.screen.mainScreen():frame()
   local imgsz = self.image_size
   self.canvas = hs.canvas.new(frame)
   self.canvas[1] = {
      type = 'image',
      image = self.image,
      frame = {
         x = (frame.w - imgsz.w) / 2,
         y = (frame.h - imgsz.h) / 2,
         w = imgsz.w,
         h = imgsz.h,
      },
      imageAlpha = self.image_alpha,
   }
   self.canvas:show(self.fade_in_time)
end

--- FadeLogo:hide()
--- Method
--- Hide the image without zoom, fading it out over `fade_out_time` seconds
function obj:hide()
   self.canvas:hide(self.fade_out_time)
end

--- FadeLogo:zoom_and_fade()
--- Method
--- Zoom-and-fade the image over `fade_out_time` seconds
function obj:zoom_and_fade()
   local canvas=self.canvas
   local size=hs.geometry.new(canvas[1].frame)
   -- This timer will zoom the image while it is fading
   local timer
   timer=hs.timer.doEvery(
      self.zoom_scale_timer,
      function()
         if canvas:isShowing() then
            size:scale(self.zoom_scale_factor)
            canvas[1].frame = {x = size.x, y = size.y, w = size.w, h = size.h }
         else
            timer:stop()
            timer = nil
         end
   end)
   canvas:hide(self.fade_out_time)
end

--- FadeLogo:start()
--- Method
--- Show the image, wait `run_time` seconds, and then zoom-and-fade it out.
function obj:start(howlong)
   if not howlong then howlong = self.run_time end
   self:show()
   obj._timer = hs.timer.doAfter(howlong, hs.fnutils.partial(self.zoom and self.zoom_and_fade or self.hide, self))
end

return obj
