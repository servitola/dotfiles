local obj = {}
obj.__index = obj

obj.GRID = {
    width = 6,
    height = 7
}

obj.right_side_app_titles = {'Telegram'}

function obj:moveWindow(x, y, window)
    if window == null then
        return
    end

    local screen = window:screen()

    cell = hs.grid.get(window, screen)
    cell.x = x
    cell.y = y
end

function obj:setWindow(x, y, height, width, window)
    if window == null then
        window = hs.window.frontmostWindow()
    end

    local window_screen = window:screen()
    local cres = window_screen:fullFrame()

    local stepw = cres.w/6
    local steph = cres.h/7
    
    local frame = window:frame()

    if height == null then
        height = frame.h / steph
    end

    if width == null then
        width = frame.w / stepw
    end

    window:setFrame({
        x = x * stepw,
        y = y * steph,
        w = width * stepw,
        h = height * steph
    })

end

function obj:bindWindowLeft(modifier, key)
    hs.hotkey.bind(modifier, key, function()
        self:setWindow(0, 0, 7, 4)
    end)
end

function obj:bindWindowRight(modifier, key)
    hs.hotkey.bind(modifier, key, function()
        self:setWindow(4, 0, 5, 2)
    end)
end

function obj:bindWindowFullScreen(modifier, key)
    hs.hotkey.bind(modifier, key, function()
        self:setWindow(0, 0, 7, 6)
    end)
end

function obj:bindAllWindowsToDefault(modifier, key)
    hs.hotkey.bind(modifier, key, function()
        self:set_all_windows_positions()
    end)
end

function obj:init()
    hs.grid.setGrid(obj.GRID.width .. 'x' .. obj.GRID.height)
    hs.grid.MARGINX = 0
    hs.grid.MARGINY = 0
    hs.window.animationDuration = 0.08
end

function obj:getYandexMainWindowId()
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

function obj:set_all_windows_positions()
    local wins = hs.window.visibleWindows()

    local yandex_main_window_id = self:getYandexMainWindowId()

    for _, window in ipairs(wins) do
        local app = window:application()
        local window_title = window:title()
        local app_title = app:title()
        local window_id = window:id()

        logWindow(window)

        if hs.fnutils.contains(self.right_side_app_titles, window_title) then
            self:setWindow(4, 0, 5, 2, window)
        elseif app_title == "Yandex" and window_id ~= yandex_main_window_id then
            self:setWindow(4, 5, 2, 2, window)
        elseif app_title == "qemu-system-x86_64" then
            --self:setWindow(4, 0, null, null, window)
            --self:moveWindow(4, 0, window)
        else
            cell = hs.grid.get(window, window:screen())
            if cell.x == 0 and cell.y == 0 and cell.h == 7 and cell.w == 6 then
                local active_window = hs.window.frontmostWindow()
                if active_window == window then
                    self:setWindow(0, 0, 7, 4, window)
                end
            else
                self:setWindow(0, 0, 7, 4, window)
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
