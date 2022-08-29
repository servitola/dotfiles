local obj={}
obj.__index = obj

obj.name = "FadeLogo"
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

function obj:zoom_and_fade()
   local canvas = self.canvas
   local size = hs.geometry.new(canvas[1].frame)
   local timer = hs.timer.doEvery(
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

function obj:start()
   self:show()
   obj._timer = hs.timer.doAfter(self.run_time, hs.fnutils.partial(self.zoom and self.zoom_and_fade or self.hide, self))
end

return obj
