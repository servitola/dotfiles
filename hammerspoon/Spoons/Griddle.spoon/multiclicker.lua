-- A stack data structure with helper functions
local function Stack(list)
  local self = {stack = list or {}}
  
  function self.push(item)
    self.stack[#self.stack + 1] = item
  end
  
  function self.pop()
    if #self.stack > 0 then
      return table.remove(self.stack, #self.stack)
    end
  end
  
  function self.peek()
    return self.stack[#self.stack]
  end
  
  function self.size()
    return #self.stack
  end
  
  return self
end

-- Double clicking doesn't work with Hammerspoon's simple APIs, so we need a way to track
-- double/triple clicking ourselves with timers
local function MultiClicker(button)
  local self = {
    clicks = 0,
    clicked = Stack(),
  }
  local clickState = hs.eventtap.event.properties.mouseEventClickState
  local buttonDown = hs.eventtap.event.types[button .. 'Down'] -- e.g. leftMouseDown
  local buttonUp = hs.eventtap.event.types[button .. 'Up'] -- e.g. leftMouseUp
  local dragged = hs.eventtap.event.types[button .. 'Dragged'] -- e.g. leftMouseDragged
  local countResetter = hs.timer.delayed.new(
    hs.eventtap.doubleClickInterval(),
    function()
      if self.clicked.size() == 0 then self.clicks = 0 end
    end
  )
  
  function clickAt(event, clicks, point)
    hs.eventtap.event.newMouseEvent(event, point):setProperty(clickState, clicks):post()
  end
  
  function self.clickDown()
    local point = hs.mouse.getAbsolutePosition()
    local numClicks = self.clicks + 1
    self.clicks = numClicks
    self.clicked.push({
      point = point,
      numClicks = numClicks,
    })
    clickAt(buttonDown, numClicks, point)
  end
  
  function self.clickUp()
    countResetter:start()
    local click = self.clicked.pop()
    if click then
      local point = hs.mouse.getAbsolutePosition()
      if click.point.x ~= point.x or click.point.y ~= point.y then
        clickAt(dragged, click.numClicks, point)
      end
      clickAt(buttonUp, click.numClicks, point)
    end
  end
  
  function self.dragged(point)
    if self.clicked.size() > 0 then
      point = point or hs.mouse.getAbsolutePosition()
      clickAt(dragged, self.clicks, point)
    end
  end
  
  return self
end

return MultiClicker
