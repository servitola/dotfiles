local obj = {}
obj.name = "Notification"
obj.version = "1.0"
obj.author = "servitola"

-- Keep track of active notifications
local activeNotifications = {}
local maxNotifications = 3

-- Color themes
local themes = {
    default = {
        background = { red = 40/255, green = 35/255, blue = 32/255, alpha = 0.95 },
        border = { red = 250/255, green = 189/255, blue = 47/255, alpha = 0.4 },
        text = { red = 1, green = 1, blue = 1, alpha = 1 }
    },
    success = {
        background = { red = 39/255, green = 55/255, blue = 40/255, alpha = 0.95 },
        border = { red = 82/255, green = 205/255, blue = 91/255, alpha = 0.4 },
        text = { red = 1, green = 1, blue = 1, alpha = 1 }
    },
    warning = {
        background = { red = 55/255, green = 47/255, blue = 34/255, alpha = 0.95 },
        border = { red = 255/255, green = 179/255, blue = 0/255, alpha = 0.4 },
        text = { red = 1, green = 1, blue = 1, alpha = 1 }
    },
    error = {
        background = { red = 55/255, green = 34/255, blue = 34/255, alpha = 0.95 },
        border = { red = 255/255, green = 89/255, blue = 89/255, alpha = 0.4 },
        text = { red = 1, green = 1, blue = 1, alpha = 1 }
    }
}

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

function obj.show(text, options)
    -- Default options
    options = options or {}
    local width = options.width or 400
    local height = options.height or (options.actions and 85 or 65)  -- Taller for actions
    local padding = options.padding or 22
    local timeout = options.timeout or 2
    local priority = options.priority or "normal"
    local theme = themes[options.type or "default"]
    local progress = options.progress  -- Optional progress (0-1)
    local actions = options.actions    -- Optional array of {text = "Button", callback = function}

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
            for j, notif in ipairs(activeNotifications) do
                if notif.canvas == c then
                    hideWithFade(notif)
                    break
                end
            end
        end
    end)

    -- Add deeper shadow
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = {
            red = 0,
            green = 0,
            blue = 0,
            alpha = 0.3
        },
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = 3, y = 3, w = "100%", h = "100%" }
    })

    -- Add subtle noise texture
    for i = 1, 50 do
        local x = math.random() * 100
        local y = math.random() * 100
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = {
                red = 1,
                green = 1,
                blue = 1,
                alpha = math.random() * 0.03
            },
            frame = {
                x = x .. "%",
                y = y .. "%",
                w = "1%",
                h = "1%"
            }
        })
    end

    -- Add background
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = theme.background,
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- Add grain overlay
    for i = 1, 8 do
        canvas:appendElements({
            type = "rectangle",
            action = "fill",
            fillColor = {
                red = 1,
                green = 1,
                blue = 1,
                alpha = 0.02
            },
            frame = {
                x = 0,
                y = (i * 12) .. "%",
                w = "100%",
                h = "3%"
            }
        })
    end

    -- Add border with subtle bevel effect
    canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = {
            red = 1,
            green = 1,
            blue = 1,
            alpha = 0.1
        },
        strokeWidth = 1,
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = 1, y = 1, w = "99%", h = "99%" }
    })
    canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = theme.border,
        strokeWidth = 2,
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- Add text with slight shadow for depth
    canvas:appendElements({
        type = "text",
        text = text,
        textColor = {
            red = 0,
            green = 0,
            blue = 0,
            alpha = 0.3
        },
        textFont = ".AppleSystemUIFont",
        textSize = 30,
        textAlignment = "center",
        frame = { x = 0, y = "50%", w = "100%", h = "100%" },
        transformation = hs.canvas.matrix.translate(1, -14)
    })
    canvas:appendElements({
        type = "text",
        text = text,
        textColor = theme.text,
        textFont = ".AppleSystemUIFont",
        textSize = 30,
        textAlignment = "center",
        frame = { x = 0, y = "50%", w = "100%", h = "100%" },
        transformation = hs.canvas.matrix.translate(0, -15)
    })

    -- Add progress bar if specified
    if progress then
        addProgressBar(canvas, progress, theme)
    end

    -- Add action buttons if specified
    if actions then
        canvas = addActionButtons(canvas, actions, theme)
        -- Update click handler to check button clicks
        canvas:mouseCallback(function(c, m, i, x, y)
            if m == "mouseUp" then
                local h = canvas:frame().h
                local w = canvas:frame().w
                -- Check if click is in button area
                if y >= h * 0.75 and y <= h * 0.9 then
                    local buttonWidth = w * 0.9 / #actions
                    for i, action in ipairs(actions) do
                        local buttonX = w * 0.05 + (i-1) * buttonWidth
                        if x >= buttonX and x <= buttonX + buttonWidth then
                            if action.callback then
                                action.callback()
                            end
                            return
                        end
                    end
                end
                -- If not on button, dismiss notification
                for j, notif in ipairs(activeNotifications) do
                    if notif.canvas == c then
                        hideWithFade(notif)
                        break
                    end
                end
            end
        end)
    end

    -- Add dismiss text if notification is persistent
    if timeout == 0 then
        canvas:appendElements({
            type = "text",
            text = "Click to dismiss",
            textColor = {
                red = theme.text.red,
                green = theme.text.green,
                blue = theme.text.blue,
                alpha = 0.6
            },
            textFont = ".AppleSystemUIFont",
            textSize = 12,
            textAlignment = "center",
            frame = { x = 0, y = "85%", w = "100%", h = "100%" }
        })
    end

    -- Show notification with animation
    local notif = showWithFade(canvas, finalX, priority)

    -- Auto-hide after timeout seconds if timeout is not 0
    if timeout > 0 then
        hs.timer.doAfter(timeout, function()
            hideWithFade(notif)
        end)
    end
end

function obj.success(text, options)
    options = options or {}
    options.type = "success"
    return obj.show(text, options)
end

function obj.warning(text, options)
    options = options or {}
    options.type = "warning"
    return obj.show(text, options)
end

function obj.error(text, options)
    options = options or {}
    options.type = "error"
    return obj.show(text, options)
end

return obj
