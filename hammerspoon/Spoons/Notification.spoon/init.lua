local obj = {}
obj.name = "Notification"
obj.version = "1.0"
obj.author = "servitola"

-- Keep track of active notifications
local activeNotifications = {}
local maxNotifications = 3

-- Wood texture path
local woodTexturePath = "~/projects/dotfiles/hammerspoon/lib/wood.jpg"

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

-- Function to add wood texture
local function addWoodTexture(canvas, theme)
    local frame = canvas:frame()
    local image = hs.image.imageFromPath(woodTexturePath)

    if image then
        -- Get image dimensions
        local imageSize = image:size()
        -- Scale factor to make the texture more detailed (showing smaller area)
        local scaleFactor = 0.5  -- Show half the size for more detail

        -- Calculate scaled dimensions
        local scaledWidth = frame.w / scaleFactor
        local scaledHeight = frame.h / scaleFactor

        -- Calculate random position within the image, ensuring we have enough space for our scaled view
        local maxX = math.max(0, imageSize.w - scaledWidth)
        local maxY = math.max(0, imageSize.h - scaledHeight)
        local x = math.random(0, maxX)
        local y = math.random(0, maxY)

        -- Create a temporary canvas for main texture
        local tempCanvas = hs.canvas.new({ x = 0, y = 0, w = scaledWidth, h = scaledHeight })
        tempCanvas:appendElements({
            type = "image",
            image = image,
            imageAlignment = "topLeft",
            imageScaling = "none",
            frame = { x = -x, y = -y, w = imageSize.w, h = imageSize.h }
        })

        -- macOS style corner radius (12px)
        local cornerRadius = 12

        -- Add more refined layered shadow for depth (more layers, softer spread)
        for i = 1, 6 do
            local alpha = 0.04 - (i * 0.005)  -- Gradually decreasing opacity
            local spread = i * 1.5  -- Gradually increasing spread
            canvas:appendElements({
                type = "rectangle",
                action = "fill",
                fillColor = { red = 0, green = 0, blue = 0, alpha = alpha },
                roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
                frame = { x = spread, y = spread, w = frame.w - (spread * 2), h = frame.h - (spread * 2) }
            })
        end

        -- Create clipping path with macOS style corners
        canvas:appendElements({
            type = "rectangle",
            action = "clip",
            roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            frame = { x = 0, y = 0, w = frame.w, h = frame.h }
        })

        -- Add the wood texture background
        canvas:appendElements({
            type = "image",
            image = tempCanvas:imageFromCanvas(),
            imageAlignment = "topLeft",
            imageScaling = "scaleToFit",
            frame = { x = 0, y = 0, w = frame.w, h = frame.h }
        })

        -- Add subtle inner shadow for depth
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = { red = 0, green = 0, blue = 0, alpha = 0.15 },
            roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            frame = { x = 0, y = 0, w = frame.w, h = 3 }  -- Top edge shadow
        })

        -- Add subtle highlight at bottom for depth
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = { red = 1, green = 1, blue = 1, alpha = 0.07 },
            roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            frame = { x = 0, y = frame.h - 3, w = frame.w, h = 3 }  -- Bottom edge highlight
        })

        -- Reset clipping
        canvas:appendElements({
            type = "resetClip"
        })

        -- Add refined vignette effect (more natural fade)
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = { red = 0, green = 0, blue = 0, alpha = 0.15 },
            roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            frame = { x = 0, y = 0, w = frame.w, h = frame.h }
        })

        -- Add subtle warm overlay to enhance wood texture
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = { red = 1, green = 0.95, blue = 0.9, alpha = 0.05 },  -- Very subtle warm tint
            roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            frame = { x = 0, y = 0, w = frame.w, h = frame.h }
        })

        -- Add subtle macOS-style border with refined opacity
        canvas:appendElements({
            type = "rectangle",
            action = "stroke",
            strokeColor = { red = 1, green = 1, blue = 1, alpha = 0.12 },
            strokeWidth = 1,
            roundedRectRadii = { xRadius = cornerRadius, yRadius = cornerRadius },
            frame = { x = 0, y = 0, w = frame.w, h = frame.h }
        })
    end
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

-- Physics-inspired easing functions
local function easeInOutQuad(t)
    return t < 0.5 and 2 * t * t or 1 - math.pow(-2 * t + 2, 2) / 2
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
local function getVerticalPosition(position)
    return 60 + (position - 1) * 75  -- Stack notifications with gap
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
    local steps = 45
    local duration = 0.6
    local stepTime = duration / steps
    local initialAlpha = notif.canvas:alpha()
    local initialX = notif.canvas:topLeft().x
    local screen = hs.screen.mainScreen()
    local slideDistance = screen:frame().w - initialX + 100

    for i = steps, 0, -1 do
        local progress = i / steps
        local easedProgress = easeInOutQuad(progress)
        local alpha = math.pow(progress, 1.2) * initialAlpha
        local xOffset = initialX + (1 - easedProgress) * slideDistance

        hs.timer.doAfter((steps - i) * stepTime, function()
            if notif.canvas then
                notif.canvas:alpha(alpha)
                notif.canvas:topLeft({ x = xOffset, y = notif.canvas:topLeft().y })
                if i == 0 then
                    notif.canvas:delete()
                    -- Remove from active notifications
                    for j, n in ipairs(activeNotifications) do
                        if n == notif then
                            table.remove(activeNotifications, j)
                            break
                        end
                    end
                    updateNotificationPositions()
                end
            end
        end)
    end
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

function obj.show(text, options)
    -- Default options
    options = options or {}
    local width = options.width or 400
    local height = options.height or (options.actions and 85 or 65)
    local padding = options.padding or 22
    local timeout = options.timeout or 2
    local priority = options.priority or "normal"
    local progress = options.progress
    local actions = options.actions

    -- Get screen dimensions
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()

    -- Calculate position
    local finalX = frame.w - width - padding

    -- Create canvas for notification
    local canvas = hs.canvas.new({
        x = finalX,
        y = getVerticalPosition(#activeNotifications + 1),
        w = width,
        h = height
    })

    -- Add click handler for the entire canvas
    canvas:mouseCallback(function(c, m, i, x, y)
        if m == "mouseUp" then
            if actions then
                local h = canvas:frame().h
                local w = canvas:frame().w
                if y >= h * 0.75 and y <= h * 0.9 then
                    local buttonWidth = w * 0.9 / #actions
                    for i, action in ipairs(actions) do
                        local buttonX = w * 0.05 + (i-1) * buttonWidth
                        if x >= buttonX and x <= buttonX + buttonWidth then
                            if action.callback then
                                action.callback()
                            end
                            break
                        end
                    end
                end
            end
            -- Always try to remove notification on click
            for j, notif in ipairs(activeNotifications) do
                if notif.canvas == c then
                    hideWithFade(notif)
                    break
                end
            end
        end
    end)

    -- Add wood texture
    addWoodTexture(canvas, {})

    -- Add text with premium styling
    canvas:appendElements({
        type = "text",
        text = text,
        textColor = { red = 0.1, green = 0.1, blue = 0.1, alpha = 0.9 },
        textFont = ".AppleSystemUIFont",  -- Medium weight for better readability
        textSize = 30,
        textAlignment = "center",
        frame = { x = 0, y = "50%", w = "100%", h = "100%" },
        transformation = hs.canvas.matrix.translate(1, -16)
    })

    -- Add main text with warm but bright color
    canvas:appendElements({
        type = "text",
        text = text,
        textColor = { 
            red = 0.98,    -- Brighter warm white
            green = 0.96, 
            blue = 0.92,
            alpha = 0.98   -- More opaque for better visibility
        },
        textFont = ".AppleSystemUIFont",  -- Medium weight for better readability
        textSize = 30,
        textAlignment = "center",
        frame = { x = 0, y = "50%", w = "100%", h = "100%" },
        transformation = hs.canvas.matrix.translate(0, -17)
    })

    -- Add progress bar if specified
    if progress then
        addProgressBar(canvas, progress, {})
    end

    -- Add action buttons if specified
    if actions then
        canvas = addActionButtons(canvas, actions, {})
    end

    -- Show notification with animation
    local notif = showWithFade(canvas, finalX, priority)
    notif.createdAt = os.time()  -- Add timestamp for stale detection

    -- Auto-hide after timeout seconds if timeout is not 0
    if timeout > 0 then
        -- Use hs.timer for more reliable cleanup
        hs.timer.doAfter(timeout, function()
            -- Check if notification still exists
            for i, n in ipairs(activeNotifications) do
                if n == notif then
                    hideWithFade(notif)
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
