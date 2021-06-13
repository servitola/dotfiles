--- === Griddle ===
---
--- Use the keyboard as a mouse by selecting successively smaller grids on the screen
---
--- Download: [https://github.com/msolomon/griddle/raw/master/Griddle.spoon.zip](https://github.com/msolomon/griddle/raw/master/Griddle.spoon.zip)
---
--- Griddle is used by entering Griddle mode using a hotkey.
--- An overlay will then appear over the screen, dividing it into a 3x3 grid with a key shortcut corresponding to each.
--- Pressing the key shortcut moves the mouse to that grid location and the grid is replaced with a new smaller grid.
--- This process is repeated until the mouse is in the desired location,
--- then another key (usually `f`) is pressed to click the mouse and the grid disappears.
---
--- This allows the user to click arbitrary screen locations without using the physical mouse.
--- With a bit of practice, this can be quite efficient.
--- Double/triple click, right click, click-and-drag, and multiple monitors are all supported.
---

local obj = {}
obj.__index = obj
obj.spoonPath = (debug.getinfo(1, 'S').source:sub(2)):match('(.*/)')

-- Metadata
obj.name = 'Griddle'
obj.version = '0.1'
obj.author = 'Mike Solomon <mike@msol.io>'
obj.twitter = '@msol'
obj.homepage = 'https://github.com/msolomon/griddle'
obj.license = 'GPL-3.0 https://www.gnu.org/licenses/gpl-3.0.txt'

local MultiClicker = dofile(obj.spoonPath..'/multiclicker.lua')
local util = dofile(obj.spoonPath..'/util.lua')

--- Griddle.absoluteShortcuts
--- Variable
--- A table mapping keys to locations on the on-screen grid.
---
--- Griddle is typically used by entering Griddle mode using a hotkey,
--- then choosing successively more specific grid locations using these absolute shortcuts.
--- Once the mouse is in the correct location, the user clicks using the `leftClick` key.
---
--- Grid locations are named by row and column:
---
--- `tl | tc | tr`
---
--- `---+----+---`
---
--- `cl | cc | cr`
---
--- `---+----+---`
---
--- `bl | bc | br`
---
--- `tl` is top left,
--- `tc` is top center,
--- `tr` is top right,
--- `cl` is center left,
--- `cc` is center center,
--- `cr` is center right,
--- `bl` is bottom left,
--- `bc` is bottom center,
--- `br` is bottom right.
---
--- Keys are chosen using their name as a string.
--- Bindings may be omitted using `nil`.
--- Multiple bindings are possible by specifying a table instead.
---
--- By default, keys are chosen for the 3x3 grid underneath the index,
--- middle and ring finger of the right hand home-row on a QWERTY keyboard:
---
--- `{tl = 'u', tc = 'i', tr = 'o', cl = 'j', cc = 'k', cr = 'l', bl = {'n', 'm'}, bc = ',', br = '.'}`
obj.absoluteShortcuts = {
  tl = 'u',
  tc = 'i',
  tr = 'o',
  cl = 'j',
  cc = 'k',
  cr = 'l',
  bl = {'n', 'm'},
  bc = ',',
  br = '.',
}

--- Griddle.relativeShortcuts
--- Variable
--- A table mapping keys to directions relative to the present mouse location.
---
--- The mouse location may be refined by using these keys to move the cursor a short distance.
--- Directions are chosen using the same style 3x3 grid as specified in `absoluteShortcuts`.
---
--- By default, keys are chosen for the 3x3 grid underneath the pinky, ring, and middle finger
--- of the right hand home-row on a QWERTY keyboard.
--- The default also supports WASD movement:
--- `{tl = 'q', tc = 'w', tr = 'e', cl = 'a', cc = nil, cr = 'd', bl = 'z', bc = {'x', 's'}, br = 'c'}`
obj.relativeShortcuts = {
  tl = 'q',
  tc = 'w',
  tr = 'e',
  cl = 'a',
  cc = nil,
  cr = 'd',
  bl = 'z',
  bc = {'x', 's'},
  br = 'c',
}

--- Griddle.otherShortcuts
--- Variable
--- A table mapping keys to other actions in Griddle mode:
--- `leftClick`, which clicks the left mouse button. Defaults to `f`.
--- `rightClick`, which clicks the right mouse button. DDefaults to `g`.
--- `nextMonitor`, which moves the grid to the next monitor. Defaults to `;`.
--- `exit`, which exits Griddle mode. Defaults to `{'return', 'escape', 'capslock', 'space'}`.
obj.otherShortcuts = {
  leftClick = 'f',
  rightClick = 'g',
  nextMonitor = ';',
  exit = {'return', 'escape', 'capslock', 'space'},
}

-- Other settings

--- Griddle.exitAfterLeftClick
--- Variable
--- A boolean determining whether to exit Griddle mode after pressing `leftClick`. Defaults to `true`.
obj.exitAfterLeftClick = true
--- Griddle.exitAfterRightClick
--- Variable
--- A boolean determining whether to exit Griddle mode after pressing `rightClick`. Defaults to `false`.
obj.exitAfterRightClick = false -- often you want to do a nearby menu click after a right click
--- Griddle.fineMoveDistance
--- Variable
--- The number of pixels to move when using `relativeShortcuts`. Defaults to 8.
obj.fineMoveDistance = 8

local anchor = util.anchor

-- Represents all the logic but fixed to a given screen
local function Grid(screen, screenSize, params)
  params = params or {}
  params = util.iconcat(obj, params)
  local self = {
    screen = screen,
    screenSize = screenSize
  }
  local overlay = hs.canvas.new(screenSize) -- holds grid and inner labels
  self.overlay = overlay
  local fullFrame = screen:fullFrame()
  local outerOverlay = hs.canvas.new(fullFrame) -- holds grid and outer labels
  self.outerOverlay = outerOverlay
  local screenW = screenSize.w
  local screenH = screenSize.h
  
  local labelsOutside = params.labelsOutside == true or false
  local margin = params.margin or 5
  local textSizeFraction = params.textSizeFraction or 10
  local minimumTextSize = params.minimumTextSize or 16
  local lineStrokeThickness = params.lineStrokeThickness or 1
  local lineFillThickness = params.lineFillThickness or 3
  local opacity = params.opacity or 1 / 2
  local lineThickness = math.max(lineStrokeThickness, lineFillThickness)
  
  local lt = lineThickness -- line thickness
  local hlt = lineThickness / 2 -- half line thickness
  local ho = (fullFrame.h / 2 - screenH / 2) -- height offset
  local wo = (fullFrame.w / 2 - screenW / 2) -- width offset
  local m = margin -- margin
  
  -- return the coordinates of the center of the given sector
  function self.selectSector(sector)
    local _pos_to_phone = {
      tl = 1,
      tc = 2,
      tr = 3,
      cl = 4,
      cc = 5,
      cr = 6,
      bl = 7,
      bc = 8,
      br = 9,
    }
    local sectors = calculateSectors(screenSize)
    local pos = sectors[_pos_to_phone[sector]]
    return pos
  end
  
  function self.moveTo(center, corner)
    screen = thisScreen()
    center = util.roundFrame(screen.screen:localToAbsolute(center))
    overlay:topLeft(center)
    if corner then
      corner = util.roundFrame(screen.screen:localToAbsolute(corner))
      outerOverlay:topLeft(corner)
    end
  end
  
  function mkLine(frame)
    return {
      type = 'rectangle',
      frame = frame,
      fillColor = {red = 1, green = 1, blue = 1, alpha = opacity},
      strokeColor = {red = 0, green = 0, blue = 0, alpha = opacity},
      strokeWidth = lineStrokeThickness,
    }
  end
  
  function styleText(text, size)
    local style = {
      font = {name = hs.styledtext.defaultFonts.system, size = size},
      paragraphStyle = {alignment = 'center'},
      -- backgroundColor = { red = 1, alpha = 1/4 },
      color = {red = 1, green = 1, blue = 1, alpha = opacity},
      strokeColor = {red = 0, green = 0, blue = 0, alpha = opacity},
      strokeWidth = -2
    }
    return hs.styledtext.new(text, style)
  end
  
  function mkText(text, x, y, size)
    local styled = styleText(text, size)
    local size = overlay:minimumTextSize(styled)
    local frame = {w = size.w, h = size.h, x = x, y = y}
    return {type = 'text', frame = frame, text = styled}
  end
  
  -- divide space into a phone-like grid:
  -- 123
  -- 456
  -- 789
  function calculatePositions(w, h, xOffset, yOffset)
    xOffset = xOffset or 0
    yOffset = yOffset or 0
    local pos = {}
    local p = 0
    for i = 0, 2, 1 do
      for j = 0, 2, 1 do
        p = p + 1
        pos[p] = {x = xOffset + w * j / 2, y = yOffset + h * i / 2}
      end
    end
    return pos
  end
  
  -- centers of sectors
  function calculateSectors(frame)
    return util.iconcat(frame, calculatePositions(frame.w * 2 / 3, frame.h * 2 / 3, frame.w / 6, frame.h / 6))
  end
  
  -- add 3x3 grid
  function addSectorGrid(overlay, w, h)
    overlay:appendElements(
      mkLine({x = 0, y = '0%', h = '100%', w = lineFillThickness}),
      mkLine({x = w / 3 - hlt, y = '0%', h = '100%', w = lineFillThickness}),
      mkLine({x = w * 2 / 3 - hlt, y = '0%', h = '100%', w = lineFillThickness}),
      mkLine({x = w - lineThickness, y = '0%', h = '100%', w = lineFillThickness}),
      
      mkLine({x = '0%', y = 0, h = lineFillThickness, w = '100%'}),
      mkLine({x = '0%', y = h / 3 - hlt, h = lineFillThickness, w = '100%'}),
      mkLine({x = '0%', y = h * 2 / 3 - hlt, h = lineFillThickness, w = '100%'}),
    mkLine({x = '0%', y = h - lineThickness, h = lineFillThickness, w = '100%'}))
  end
  
  function addKeyOverlayInside(overlay, w, h)
    local size = math.max(math.min(w, h) / textSizeFraction, minimumTextSize)
    local absoluteShortcuts = params.absoluteShortcuts
    overlay:appendElements(
      anchor(mkText(absoluteShortcuts.tl, w / 6, h / 3 - hlt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.tc, w * 3 / 6, h / 3 - hlt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.tr, w * 5 / 6, h / 3 - hlt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.cl, w / 6, h * 2 / 3 - hlt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.cc, w * 3 / 6, h * 2 / 3 - hlt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.cr, w * 5 / 6, h * 2 / 3 - hlt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.bl, w / 6, h - lt, size), 'bc'),
      anchor(mkText(absoluteShortcuts.bc, w * 3 / 6 - lt, h, size), 'bc'),
    anchor(mkText(absoluteShortcuts.br, w * 5 / 6 - lt, h, size), 'bc'))
  end
  
  function addKeyOverlayOutside(overlay, w, h)
    local size = math.max(math.min(w, h) / textSizeFraction * 2, minimumTextSize)
    local absoluteShortcuts = params.absoluteShortcuts
    -- TODO: weird bug where re-centering with "t" results moves outer overlay slightly
    overlay:appendElements(
      anchor(mkText(absoluteShortcuts.tl, wo - m, ho - m, size), 'br'),
      anchor(mkText(absoluteShortcuts.tc, wo + w / 2, ho - m, size), 'bc'),
      anchor(mkText(absoluteShortcuts.tr, wo + w + m, ho - m, size), 'bl'),
      anchor(mkText(absoluteShortcuts.cl, wo - m, ho + h / 2, size), 'cr'),
      -- anchor(mkText(absoluteShortcuts.cc, wo+w/2, ho+h/2 - hlt, size), 'bc'), -- don't show
      anchor(mkText(absoluteShortcuts.cr, wo + w + m, ho + h / 2, size), 'cl'),
      anchor(mkText(absoluteShortcuts.bl, wo - m, ho + h, size), 'tr'),
      anchor(mkText(absoluteShortcuts.bc, wo + w / 2, ho + h, size), 'tc'),
    anchor(mkText(absoluteShortcuts.br, wo + w + m, ho + h, size), 'tl'))
  end
  
  addSectorGrid(overlay, screenW, screenH)
  if labelsOutside then
    addKeyOverlayOutside(outerOverlay, screenW, screenH)
  else
    addKeyOverlayInside(overlay, screenW, screenH)
  end
  
  function self.show(speed)
    if (not overlay:isShowing()) then -- show() doesn't seem idempotent w.r.t opacity
      overlay:show(speed or 0.2)
      if labelsOutside then outerOverlay:show(speed or 0.2) end
    end
  end
  
  function self.hide(speed)
    overlay:hide(speed or 0.2)
    if labelsOutside then outerOverlay:hide(speed or 0.2) end
  end
  
  return self
end

-- Makes the "shade" overlay that darkens the screen around the grid
local function mkShade(screenSize)
  local shade = hs.canvas.new(screenSize)
  shade:hide()
  shade:appendElements(
    {action = 'build', type = 'rectangle'}, -- whole screen canvas
    {-- this is the hole in the overlay. mutate it to change its frame
      type = 'rectangle',
      frame = {x = 0, y = 0, h = 0, w = 0},
      action = 'clip',
      reversePath = true
    },
    {-- this is the actual shade
      type = 'rectangle',
      frame = screenSize,
      fillColor = {red = 0, green = 0, blue = 0, alpha = 15 / 100},
    }
    
  )
  
  return shade
end

-- Detects all physical screens and builds one Grid for each zoom level therein
local function buildScreens()
  local screens = {}
  for _, screen in ipairs(hs.screen.allScreens()) do
    local size = screen:fullFrame()
    local grids = {
      Grid(screen, {x = 0, y = 0, w = size.w, h = size.h}),
      Grid(screen, {x = 0, y = 0, w = size.w / 3, h = size.h / 3}),
      Grid(
        screen,
        {x = 0, y = 0, w = size.w / 9, h = size.h / 9},
      {labelsOutside = true}),
      Grid(
        screen,
        {x = 0, y = 0, w = size.w / 27, h = size.h / 27},
      {lineFillThickness = 2, lineStrokeThickness = 1, opacity = 3 / 4, labelsOutside = true})
      
    }
    
    screens[screen:id()] = {
      screen = screen,
      shade = mkShade(size),
      level = 1, -- tracks which focus level we are at
      grids = grids
    }
  end
  return screens
end

--- Griddle:bindHotkeys()
--- Method
--- Bind a hotkey to enter Griddle mode.
--- Accepts a table like `{ enter = {{"cmd", "shift"}, "j"} }`
--- `enter` and `exit` may both be defined, but typically only `enter` is necessary.
function obj:bindHotkeys(hotkeys)
  if (hotkeys.enter) then
    hs.hotkey.bindSpec(hotkeys.enter, function() obj:enter() end)
  end
  if (hotkeys.exit) then
    hs.hotkey.bindSpec(hotkeys.exit, function() obj:exit() end)
  end
end

--- Griddle:enter()
--- Method
--- Enter Griddle mode on the sceen with a focused window.
---
--- May not be called before `Griddle:start()`.
---
--- Accepts one optional argument that specifies the time to fade in in seconds. Defaults to `0.2`.
function obj:enter()
  -- This is a dummy definition to enable docs generation. It's redefined inside obj:start()
end

--- Griddle:exit()
--- Method
--- Exit Griddle mode.
---
--- May not be called before `Griddle:start()`.
---
--- Accepts one optional argument that specifies the time to fade out in seconds. Defaults to `0.2`.
function obj:exit()
  -- This is a dummy definition to enable docs generation. It's redefined inside obj:start()
end

--- Griddle:start()
--- Method
--- Enable Griddle and bind any configured hotkeys.
--- Returns a function you can call to enter Griddle mode.
function obj:start()
  local params = obj
  local fineMoveDistance = params.fineMoveDistance
  local keys = hs.hotkey.modal.new()
  local screens = buildScreens()
  
  -- exit after waiting for more clicks, to allow double clicking
  local exiter = hs.timer.delayed.new(hs.eventtap.doubleClickInterval(), function() exitIfKeysUp() end)
  local leftClicker = MultiClicker('leftMouse')
  local rightClicker = MultiClicker('rightMouse')
  
  -- An init() call happens at the end of this
  
  function thisScreen()
    local showingScreen = -- find the screen we're showing a grid on
    hs.fnutils.find(screens,
      function(screen)
        -- TODO: doesn't work while animating/fading in
        return hs.fnutils.find(screen.grids, function(grid) return grid.overlay:isShowing() end)
      end
    )
    return showingScreen or screens[hs.screen.mainScreen():id()] -- or guess which screen we're on
  end
  
  function screensChanged()
    for _, screen in ipairs(hs.screen.allScreens()) do
      local s = screens[screen:id()]
      if s == nil then return true end
    end
    return false
  end
  
  -- macOS hides the mouse in certain circumstances, this ensures it is shown
  function showMouse()
    hs.mouse.setAbsolutePosition(hs.mouse.getAbsolutePosition())
  end
  
  -- TODO: fix docstring and move to here--it doesn't work because this definition is nested.
  function obj:enter()
    speed = speed or 0.2
    if screensChanged() then
      screens = buildScreens()
    end
    local screen = thisScreen()
    if screen.level ~= 1 then -- hide any showing grid, in case we enter while already entered
      screen.shade:hide(0)
      screen.grids[screen.level].hide(0)
    end
    screen.level = 1
    local grid = screen.grids[screen.level]
    grid.moveTo(util.iconcat(grid.screenSize, {x = 0, y = 0}))
    grid.show(speed)
    showMouse()
    keys:enter()
  end
  
  -- move the grid to the next monitor
  function nextMonitor()
    local speed = 0 -- if we animate this in, isShowing() doesn't detect it as showing during the animation
    local showingScreen = thisScreen()
    local nextScreen = screens[showingScreen.screen:next():id()]
    if showingScreen ~= nextScreen then
      showingScreen.shade:hide(speed)
      showingScreen.grids[showingScreen.level].hide(speed)
      nextScreen.level = 1
      nextScreen.grids[nextScreen.level].show(speed)
    end
  end
  
  -- TODO: fix docstring and move to here--it doesn't work because this definition is nested.
  function obj:exit(speed)
    speed = speed or 0.2
    keys:exit()
    local screen = thisScreen()
    screen.grids[screen.level].hide(speed)
    screen.shade:hide(speed)
    for _, screen in pairs(screens) do -- this works around some bugs if you move grids between screens
      screen.shade:hide(speed)
      local grids = screen.grids
      for _, grid in pairs(grids) do
        grid.hide(speed)
      end
    end
  end
  
  -- don't exit this mode while a key is held down
  function exitIfKeysUp()
    if leftClicker.clicked.size() == 0 and leftClicker.clicked.size() == 0 then
      obj:exit()
    else
      exiter:start()
    end
  end
  
  -- TODO: when a click is held down, maybe "drag" the cursor slightly to "pick up" any items underneath?
  function leftClick()
    if params.exitAfterLeftClick then
      exiter:start()
    end
    leftClicker.clickDown()
  end
  
  function rightClick()
    if params.exitAfterRightClick then
      exiter:start()
    end
    rightClicker.clickDown()
  end
  
  function sendMouseTo(point)
    hs.mouse.setAbsolutePosition(point)
    leftClicker.dragged()
    rightClicker.dragged()
  end
  
  -- zooms the grid in by one step, or until it bottoms out
  function zoomInOneLevel(screen)
    local outer = screen.grids[screen.level]
    screen.level = screen.level + 1
    local inner = screen.grids[screen.level]
    if (inner) then
      outer.hide()
    else
      screen.level = screen.level - 1
      inner = screen.grids[screen.level]
    end
    return inner
  end
  
  function moveGridTo(newPos, grid, screen)
    local currentScreenSize = screen.screen:fullFrame()
    local outerOverlayCorner = anchor({w = currentScreenSize.w, h = currentScreenSize.h, x = newPos.x, y = newPos.y}, 'cc')
    local centeredPos = anchor(newPos, 'cc')
    grid.moveTo(centeredPos, outerOverlayCorner)
    screen.shade:elementAttribute(2, 'frame', centeredPos)
  end
  
  function selectSector(screen, shortcut)
    local outer = screen.grids[screen.level]
    local relativeCenter = outer.selectSector(shortcut)
    local inner = zoomInOneLevel(screen)
    local offset = screen.screen:absoluteToLocal(outer.overlay:topLeft())
    local newPos = {
      h = inner.screenSize.h,
      w = inner.screenSize.w,
      x = relativeCenter.x + offset.x,
      y = relativeCenter.y + offset.y
    }
    
    moveGridTo(newPos, inner, screen)
    screen.shade:show()
    inner.show()
    sendMouseTo(screen.screen:localToAbsolute(newPos))
  end
  
  function mkAdjustFine(shortcut, fineMoveDistance)
    local moveTable = {
      tl = {x = -1, y = -1},
      tc = {x = 0, y = -1},
      tr = {x = 1, y = -1},
      cl = {x = -1, y = 0},
      cc = {x = 0, y = 0},
      cr = {x = 1, y = 0},
      bl = {x = -1, y = 1},
      bc = {x = 0, y = 1},
      br = {x = 1, y = 1},
    }
    
    return function()
      local screen = thisScreen()
      local point = hs.mouse.getAbsolutePosition()
      local multiplier = moveTable[shortcut]
      local newAbsPoint = {
        x = point.x + multiplier.x * fineMoveDistance,
        y = point.y + multiplier.y * fineMoveDistance
      }
      if screen.level > 1 then -- don't move the grid if we're zoomed all the way out
        local grid = screen.grids[screen.level]
        local relativeCenter = grid.selectSector('cc')
        local newPoint = screen.screen:absoluteToLocal(newAbsPoint)
        local newPos = {
          h = grid.screenSize.h,
          w = grid.screenSize.w,
          x = newPoint.x,
          y = newPoint.y
        }
        
        moveGridTo(newPos, grid, screen)
        screen.shade:show()
        grid.show()
      end
      sendMouseTo(newAbsPoint)
    end
  end
  
  -- initialize everything, especially shortcuts
  function init()
    function forEachShortcut(shortcuts, f)
      for shortcut, shortcutKeys in pairs(shortcuts) do
        util.forEach(shortcutKeys, function(key)
          f(shortcut, key)
        end)
      end
    end
    
    function bindKey(shortcuts, f, g)
      util.forEach(shortcuts, function(key) keys:bind({}, key, f, g) end)
    end
    bindKey(params.otherShortcuts.leftClick, leftClick, leftClicker.clickUp)
    bindKey(params.otherShortcuts.rightClick, rightClick, rightClicker.clickUp)
    bindKey(params.otherShortcuts.exit, function() obj:exit() end)
    bindKey(params.otherShortcuts.nextMonitor, nextMonitor)
    
    function mkFineAdjust(shortcut)
      return function() selectSector(thisScreen(), shortcut) end
    end
    
    forEachShortcut(params.absoluteShortcuts, function(shortcut, key)
      local fineAdjust = mkFineAdjust(shortcut)
      keys:bind(nil, key, fineAdjust, nil, fineAdjust)
    end)
    
    forEachShortcut(params.relativeShortcuts, function(shortcut, key)
      local selectSectorByShortcut = mkAdjustFine(shortcut, fineMoveDistance)
      keys:bind(nil, key, selectSectorByShortcut, nil, selectSectorByShortcut)
    end)
  end
  
  init()
end

return obj

