local obj = {}
obj.__index = obj

obj.vertical_line = 0.71
obj.horizontal_line = 0.73

obj.GRID = {
    width = 6,
    height = 10
}

right_side_app_titles = {'Telegram', 'Hammerspoon'}

function moveWindow(x, y, window)
    if window == null then
        return
    end

    local screen = window:screen()

    cell = hs.grid.get(window, screen)
    cell.x = x
    cell.y = y
end

function setWindow(x, y, width, height, window)
    if window == null then
        window = hs.window.frontmostWindow()
    end

    local window_screen = window:screen()
    local screen_size = window:screen():fullFrame()

    window:setFrame({
        x = screen_size.w * x,
        y = screen_size.h * y,
        w = screen_size.w * width,
        h = screen_size.h * height
    })

end

function setWindowLeft(window)
    setWindow(0, 0, obj.vertical_line, 1, window)
end

function setWindowRight(window)
    setWindow(obj.vertical_line, 0, 1 - obj.vertical_line, obj.horizontal_line - 0.022, window)
end

function setWindowBottom(window)
    setWindow(obj.vertical_line, obj.horizontal_line, 1 - obj.vertical_line, 1 - obj.horizontal_line, window)
end

function setWindowFullScreen(window)
    setWindow(0, 0, 1, 1, window)
end

function obj:bindWindowLeft(modifier, key)
    hs.hotkey.bind(modifier, key, setWindowLeft)
end

function obj:bindWindowRight(modifier, key)
    hs.hotkey.bind(modifier, key, setWindowRight)
end

function obj:bindWindowFullScreen(modifier, key)
    hs.hotkey.bind(modifier, key, setWindowFullScreen)
end

function obj:bindAllWindowsToDefault(modifier, key)
    hs.hotkey.bind(modifier, key, set_all_windows_positions)
end

function obj:init()
    hs.grid.setGrid(obj.GRID.width .. 'x' .. obj.GRID.height)
    hs.grid.MARGINX = 0
    hs.grid.MARGINY = 0
end

function getYandexMainWindowId()
    local wins = hs.window.visibleWindows()
    local yandex_main_window_id = nil
    for _, window in ipairs(wins) do
        local app = window:application()
        local window_title = window:title()
        local app_title = app:title()
        local window_id = window:id()

        if app_title == "Yandex" then
            if yandex_main_window_id == nil then
                yandex_main_window_id = window_id
            else
                if yandex_main_window_id > window_id then
                    yandex_main_window_id = window_id
                end
            end
        end
    end
    local logger = hs.logger.new("window", 'verbose')
    logger.d(yandex_main_window_id)

    return yandex_main_window_id
end

function set_all_windows_positions()
    local wins = hs.window.visibleWindows()

    local yandex_main_window_id = getYandexMainWindowId()

    for _, window in ipairs(wins) do
        local app = window:application()
        local window_title = window:title()
        local app_title = app:title()
        local window_id = window:id()

        logWindow(window)

        if hs.fnutils.contains(right_side_app_titles, app_title) then
            setWindowRight(window)
        elseif app_title == "Yandex" and window_id ~= yandex_main_window_id then
            setWindowBottom(window)
        elseif app_title == "qemu-system-x86_64" then
            --setWindow(4, 0, null, null, window)
            --moveWindow(4, 0, window)
        else
            cell = hs.grid.get(window, window:screen())
            if cell.x == 0 and cell.y == 0 and cell.h == obj.GRID.height and cell.w == obj.GRID.width then
                local active_window = hs.window.frontmostWindow()
                if active_window == window then
                    setWindowLeft(window)
                end
            else
                setWindowLeft(window)
            end
        end
    end
end

function logWindow(window)
    local logger = hs.logger.new("window", 'verbose')
    local app = window:application()
    logger.d(" ")
    logger.d("App Title: ")
    logger.d(app:title())
    logger.d("Bundle Id:")
    logger.d(app:bundleID())
    logger.d("Win Title:")
    logger.d(window:title())
    logger.d("Win Id:")
    logger.d(window:id())
    logger.d(" ")
end

return obj
