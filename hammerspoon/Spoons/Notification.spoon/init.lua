local obj = {}
obj.name = "Notification"
obj.version = "1.0"
obj.author = "servitola"

-- Keep track of active notifications
local activeNotifications = {}
local maxNotifications = 5  -- Maximum number of visible notifications
local topPadding = 44  -- Match window corner height with dots

-- Wood textures
local woodTextureDir = "~/projects/dotfiles/hammerspoon/lib/wood_textures"
local woodTextures = {}
local numTextures = 50

-- Load wood textures
local function loadWoodTextures()
    for i = 1, numTextures do
        local path = woodTextureDir:gsub("~", os.getenv("HOME")) .. "/wood_" .. string.format("%02d", i) .. ".jpg"
        woodTextures[i] = path
    end
end

-- Get random wood texture
local function getRandomWoodTexture()
    if #woodTextures == 0 then
        loadWoodTextures()
    end
    local index = math.random(1, #woodTextures)
    local path = woodTextures[index]
    return path, "wood_" .. string.format("%02d", index) .. ".jpg"
end

-- Easing functions
local function easeInOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

local function easeOutQuint(t)
    return 1 - math.pow(1 - t, 5)
end

-- Function to create rounded rectangle path
local function createRoundedRectPath(x, y, w, h, r)
    return {
        type = "segments",
        coordinates = {
            { x = x + r, y = y },      -- Top line
            { x = x + w - r, y = y },
            { x = x + w, y = y + r },  -- Right line
            { x = x + w, y = y + h - r },
            { x = x + w - r, y = y + h }, -- Bottom line
            { x = x + r, y = y + h },
            { x = x, y = y + h - r },  -- Left line
            { x = x, y = y + r },
            { x = x + r, y = y }       -- Back to start
        },
        closed = true
    }
end

-- Function to add wood texture to canvas
local function addWoodTexture(canvas, options)
    local cornerRadius = 10

    -- Add outer glow/shadow for depth
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = { white = 0, alpha = 0.2 },
        roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
    })

    -- Create clipping path for rounded corners and texture
    canvas:appendElements({
        type = "rectangle",
        action = "clip",
        roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
    })

    -- Add wood texture
    canvas:appendElements({
        type = "image",
        image = hs.image.imageFromPath(getRandomWoodTexture()),
        frame = { 
            x = 0, 
            y = 0, 
            w = "100%",
            h = "100%"
        },
        imageAlpha = 0.95,
        imageScaling = "scaleToFit"
    })

    -- Reset clipping
    canvas:appendElements({
        type = "resetClip"
    })

    -- Add darker outer border (perfectly aligned)
    canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = { white = 0.2, alpha = 0.4 },
        strokeWidth = 2,
        frame = { x = 0, y = 0, w = "100%", h = "100%" },
        roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
    })

    -- Add inner highlight border for depth
    canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = { white = 1, alpha = 0.15 },
        strokeWidth = 1,
        frame = { x = 1, y = 1, w = "100%-2", h = "100%-2" },
        roundedRectRadii = { xRadius = cornerRadius-1, yRadius = cornerRadius-1 },
    })
end

-- Progress bar support
local function addProgressBar(canvas, progress, theme)
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = theme.border,
        roundedRectRadii = { xRadius = 6, yRadius = 6 },
        frame = { x = "5%", y = "80%", w = tostring(math.min(90 * progress, 90)) .. "%", h = "4%" }
    })
end

-- Action buttons support
local function addActionButtons(canvas, actions, theme)
    local buttonWidth = (90 / #actions)
    for i, action in ipairs(actions) do
        local x = 5 + (i-1) * buttonWidth
        -- Button background
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = {
                red = theme.border.red,
                green = theme.border.green,
                blue = theme.border.blue,
                alpha = 0.1
            },
            roundedRectRadii = { xRadius = 6, yRadius = 6 },
            frame = { x = x .. "%", y = "75%", w = (buttonWidth - 2) .. "%", h = "15%" }
        })
        -- Button text
        canvas:appendElements({
            type = "text",
            text = action.text,
            textColor = theme.text,
            textFont = ".AppleSystemUIFont",
            textSize = 12,
            textAlignment = "center",
            frame = { x = x .. "%", y = "77%", w = (buttonWidth - 2) .. "%", h = "15%" }
        })
    end
    return canvas
end

-- Function to get next available position
local function getNextPosition()
    -- If no notifications, use first position
    if #activeNotifications == 0 then
        return 1
    end

    -- Find first empty slot
    local usedPositions = {}
    for _, notif in ipairs(activeNotifications) do
        usedPositions[notif.position] = true
    end

    -- Check positions from top to bottom
    for i = 1, maxNotifications do
        if not usedPositions[i] then
            return i
        end
    end

    -- If no empty slots, use position 1 and shift others down
    return 1
end

-- Function to get notification vertical position
local function getVerticalPosition(index)
    return topPadding + ((index - 1) * 75)  -- Stack from top down with proper padding
end

-- Function to update notification positions
local function updateNotificationPositions()
    -- Sort notifications by position
    table.sort(activeNotifications, function(a, b)
        return a.position < b.position
    end)

    -- Reassign positions to close gaps
    for i, notif in ipairs(activeNotifications) do
        notif.position = i

        local targetY = getVerticalPosition(i)
        local currentY = notif.canvas:topLeft().y
        local steps = 12
        local duration = 0.15

        for step = 0, steps do
            local progress = step / steps
            local y = currentY + (targetY - currentY) * easeInOutQuad(progress)

            hs.timer.doAfter(step * (duration / steps), function()
                if notif.canvas then
                    notif.canvas:topLeft({ x = notif.canvas:topLeft().x, y = y })
                end
            end)
        end
    end
end

-- Function to smoothly hide notification
local function hideWithFade(notif)
    if not notif or not notif.canvas then return end
    
    local canvas = notif.canvas
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Remove from active notifications first
    for i, n in ipairs(activeNotifications) do
        if n == notif then
            table.remove(activeNotifications, i)
            -- Update positions of remaining notifications
            for j, remaining in ipairs(activeNotifications) do
                if remaining and remaining.canvas then
                    local newY = getVerticalPosition(j)
                    remaining.canvas:topLeft({ x = remaining.canvas:topLeft().x, y = newY })
                end
            end
            break
        end
    end
    
    -- Animate slide out
    local startX = canvas:topLeft().x
    local endX = frame.w + 50
    local distance = endX - startX
    
    local steps = 15
    local duration = 0.2
    local stepTime = duration / steps
    local currentStep = 0
    local fadeTimer = nil
    
    fadeTimer = hs.timer.doEvery(stepTime, function()
        currentStep = currentStep + 1
        local progress = currentStep / steps
        local easedProgress = easeOutQuint(progress)
        
        if canvas then  -- Check if canvas still exists
            local newX = startX + (distance * easedProgress)
            canvas:topLeft({ x = newX, y = canvas:topLeft().y })
            canvas:alpha(0.95 * (1 - progress))
            
            if currentStep >= steps then
                fadeTimer:stop()
                if canvas then  -- Double check before final cleanup
                    canvas:delete()
                    canvas = nil
                end
            end
        else
            fadeTimer:stop()  -- Stop if canvas is gone
        end
    end)
end

-- Function to smoothly show notification
local function showWithFade(canvas, finalX, priority)
    local steps = 12
    local duration = 0.15
    local stepTime = duration / steps

    -- Get next available position
    local position = getNextPosition()
    local verticalPos = getVerticalPosition(position)

    -- Create glow effect
    local glow = hs.canvas.new({
        x = finalX,
        y = verticalPos,
        w = canvas:frame().w,
        h = canvas:frame().h
    })

    -- Add clean glow
    glow:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = {
            red = 1,
            green = 1,
            blue = 1,
            alpha = 0.12
        },
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = "0%", y = "0%", w = "100%", h = "100%" }
    })

    -- Set initial states
    canvas:topLeft({ x = finalX, y = verticalPos })
    canvas:alpha(0)
    glow:alpha(0)

    -- Show both layers
    glow:show()
    canvas:show()

    -- Single animation loop
    for i = 0, steps do
        local progress = i / steps
        local alpha = progress * 0.95

        hs.timer.doAfter(i * stepTime, function()
            if canvas then
                canvas:alpha(alpha)
                glow:alpha(0.12 * (1 - progress))

                if i == steps then
                    glow:delete()
                end
            end
        end)
    end

    -- Add to active notifications
    local notif = {
        canvas = canvas,
        priority = priority or "normal",
        createdAt = os.time(),
        position = position
    }

    -- If position 1 is taken, shift others down
    if position == 1 then
        for _, n in ipairs(activeNotifications) do
            n.position = n.position + 1
        end
    end

    table.insert(activeNotifications, notif)
    updateNotificationPositions()

    -- Remove oldest if too many
    if #activeNotifications > maxNotifications then
        -- Find oldest notification
        local oldest = activeNotifications[1]
        local oldestIdx = 1
        for i, n in ipairs(activeNotifications) do
            if n.createdAt < oldest.createdAt then
                oldest = n
                oldestIdx = i
            end
        end
        table.remove(activeNotifications, oldestIdx)
        hideWithFade(oldest)
    end

    return notif
end

-- Function to clean up stuck notifications
local function cleanupStuckNotifications()
    local now = os.time()
    local needsCleanup = false
    
    -- First pass: mark invalid notifications
    for i = #activeNotifications, 1, -1 do
        local notif = activeNotifications[i]
        if not notif or not notif.canvas or not notif.createdAt or (now - notif.createdAt > 5) then
            if notif and notif.canvas then
                notif.canvas:delete()
            end
            table.remove(activeNotifications, i)
            needsCleanup = true
        end
    end
    
    -- Second pass: reposition remaining notifications if needed
    if needsCleanup then
        for i, notif in ipairs(activeNotifications) do
            if notif and notif.canvas then
                local newY = getVerticalPosition(i)
                notif.canvas:topLeft({
                    x = notif.canvas:topLeft().x,
                    y = newY
                })
            end
        end
    end
end

-- Set up periodic cleanup
hs.timer.new(1, cleanupStuckNotifications, true):start()

-- Add a cleanup function to force remove stale notifications
local function cleanupStaleNotifications()
    local currentTime = os.time()
    local staleTimeout = 10  -- Consider notifications stale after 10 seconds
    
    for i = #activeNotifications, 1, -1 do
        local notif = activeNotifications[i]
        if notif and currentTime - notif.createdAt > staleTimeout then
            if notif.canvas then
                notif.canvas:delete()
            end
            table.remove(activeNotifications, i)
        end
    end
end

-- Add periodic cleanup timer
local cleanupTimer = hs.timer.doEvery(30, cleanupStaleNotifications)  -- Check every 30 seconds

function obj.init()
    -- Load textures into memory
    loadWoodTextures()
    return obj
end

function obj.show(text, options)
    -- Default options
    options = options or {}
    local padding = options.padding or 16  -- Reduced padding to give more room for text
    local timeout = options.timeout or 2
    local priority = options.priority or "normal"
    local source = options.source

    -- Clean up stuck notifications
    cleanupStuckNotifications()

    -- Get screen dimensions
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()
    
    -- Calculate width to match right panel
    local width = math.floor((rightX - vertical_line) * frame.w)
    local height = options.height or (options.actions and 85 or 65)
    
    -- Calculate position
    local finalX = math.floor(vertical_line * frame.w)
    local finalY = getVerticalPosition(#activeNotifications + 1)  -- Start from top

    -- Create canvas for notification
    local canvas = hs.canvas.new({
        x = finalX,
        y = finalY,
        w = width,
        h = height
    })

    -- Get random wood texture
    local texturePath, textureName = getRandomWoodTexture()
    
    -- Create clipping path for rounded corners
    canvas:appendElements({
        type = "rectangle",
        action = "clip",
        roundedRectRadii = { xRadius = 10, yRadius = 10 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })
    
    -- Add wood texture background
    canvas:appendElements({
        type = "image",
        image = hs.image.imageFromPath(texturePath),
        imageScaling = "scaleToFit",
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- Add semi-transparent dark overlay
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = { black = 0.3, alpha = 0.3 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- Reset clipping
    canvas:appendElements({
        type = "resetClip"
    })

    -- Add text
    canvas:appendElements({
        type = "text",
        text = text,
        textColor = { white = 1.0 },
        textSize = 32,
        textFont = ".AppleSystemUIFont",
        textAlignment = "center",
        frame = { x = padding, y = padding - 4, w = width - (padding * 2), h = height - (padding * 1.5) }  -- Adjusted frame height and y-offset
    })

    -- Show notification with animation
    local notif = showWithFade(canvas, finalX, priority)
    notif.createdAt = os.time()  -- Add creation timestamp
    
    -- Auto-hide after timeout seconds if timeout is not 0
    if timeout > 0 then
        hs.timer.doAfter(timeout, function()
            -- Check if notification still exists and is valid
            for i, n in ipairs(activeNotifications) do
                if n == notif and n.canvas then
                    hideWithFade(notif)
                    break
                end
            end
        end)

        -- Safety timer to force-close after timeout + 2 seconds if still exists
        hs.timer.doAfter(timeout + 2, function()
            for i, n in ipairs(activeNotifications) do
                if n == notif and n.canvas then
                    -- Force remove the notification
                    n.canvas:delete()
                    table.remove(activeNotifications, i)
                    -- Reposition remaining notifications
                    for j = i, #activeNotifications do
                        local remaining = activeNotifications[j]
                        if remaining and remaining.canvas then
                            local newY = getVerticalPosition(j)
                            remaining.canvas:topLeft({
                                x = remaining.canvas:topLeft().x,
                                y = newY
                            })
                        end
                    end
                    break
                end
            end
        end)
    end

    return notif
end

function obj.success(text, options)
    options = options or {}
    return obj.show(text, options)
end

function obj.warning(text, options)
    options = options or {}
    return obj.show(text, options)
end

function obj.error(text, options)
    options = options or {}
    return obj.show(text, options)
end

return obj
