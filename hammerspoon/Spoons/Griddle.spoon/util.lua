-- round to the nearest quantum
local function round(exact, quantum)
  quantum = quantum or 2
  local quant, frac = math.modf(exact / quantum)
  return quantum * (quant + (frac > 0.5 and 1 or 0))
end

-- concats two tables by returning a new table (immutabe concat)
local function iconcat(a, b)
  local new = {}
  for k, v in pairs(a) do
    new[k] = v
  end
  for k, v in pairs(b) do
    new[k] = v
  end
  return new
end

-- run a function with everything in a list, or a single item if a list isn't given
local function forEach(list, f)
  local sequence = list
  if type(sequence) ~= 'table' then sequence = {list} end
  for _, item in pairs(sequence) do
    f(item)
  end
end

local _anchor_table = {
  tl = {x = 0, y = 0},
  tc = {x = -.5, y = 0},
  tr = {x = -1, y = 0},
  cl = {x = 0, y = -.5},
  cc = {x = -.5, y = -.5},
  cr = {x = -1, y = -.5},
  bl = {x = 0, y = -1},
  bc = {x = -.5, y = -1},
  br = {x = -1, y = -1},
}
-- tl means 'top left center', br means 'bottom right center'
local function anchor(frame, at)
  function innerAnchor(frame, at)
    local correctBy = _anchor_table[at]
    local newPos = {x = frame.x + correctBy.x * frame.w, y = frame.y + correctBy.y * frame.h}
    return iconcat(frame, newPos)
  end
  
  -- allow passing in objects with a frame property instead
  if (frame['frame'] ~= nil) then
    frame.frame = innerAnchor(frame['frame'], at)
    return frame
  else
    return innerAnchor(frame, at)
  end
end

-- round a rectangle to the nearest integer
local function roundFrame(frame)
  return {x = round(frame.x, 2), y = round(frame.y, 2), h = round(frame.h, 2), w = round(frame.w, 2)}
end

return {
  round = round,
  roundFrame = roundFrame,
  anchor = anchor,
  forEach = forEach,
  iconcat = iconcat
}
