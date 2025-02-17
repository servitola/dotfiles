local notification = {}

-- Keep track of active notification
local activeNotification = nil

function notification.show(text, options)
    -- Default options
    options = options or {}
    local width = options.width or 400
    local height = options.height or 65
    local padding = options.padding or 22
    local timeout = options.timeout or 2
    local backgroundColor = options.backgroundColor or {
        red = 50/255,
        green = 46/255,
        blue = 44/255,
        alpha = 0.92
    }
    local borderColor = options.borderColor or {
        red = 250/255,
        green = 189/255,
        blue = 47/255,
        alpha = 0.4
    }
    local textColor = options.textColor or {
        red = 1,
        green = 1,
        blue = 1,
        alpha = 1
    }

    -- Hide previous notification if exists
    if activeNotification then
        activeNotification:hide()
    end

    -- Get screen dimensions
    local screen = hs.screen.mainScreen()
    local frame = screen:frame()

    -- Create canvas for notification
    local canvas = hs.canvas.new({
        x = frame.w - width - padding,
        y = 60,
        w = width,
        h = height
    })

    -- Add background
    canvas:appendElements({
        type = "rectangle",
        action = "fill",
        fillColor = backgroundColor,
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- Add border
    canvas:appendElements({
        type = "rectangle",
        action = "stroke",
        strokeColor = borderColor,
        strokeWidth = 2,
        roundedRectRadii = { xRadius = 12, yRadius = 12 },
        frame = { x = 0, y = 0, w = "100%", h = "100%" }
    })

    -- Add text
    canvas:appendElements({
        type = "text",
        text = text,
        textColor = textColor,
        textFont = ".AppleSystemUIFont",
        textSize = 30,
        textAlignment = "center",
        frame = { x = 0, y = "50%", w = "100%", h = "100%" },
        transformation = hs.canvas.matrix.translate(0, -15)
    })

    -- Show notification
    canvas:show()

    -- Store reference to hide later
    activeNotification = canvas

    -- Auto-hide after timeout seconds
    hs.timer.doAfter(timeout, function()
        canvas:hide()
        if activeNotification == canvas then
            activeNotification = nil
        end
    end)
end

return notification
