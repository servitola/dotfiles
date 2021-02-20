local obj = {}
obj.__index = obj

obj.GRID = {
    width = 6,
    height = 7
}

obj.right_side_app_titles = {'Telegram'}

function obj:setWindow(x, y, height, width, window)

    if window == null then
        window = hs.window.frontmostWindow()
    end

    local screen = window:screen()

    cell = hs.grid.get(window, screen)
    cell.x = x
    cell.y = y
    cell.h = height
    cell.w = width

    hs.grid.set(window, cell, screen)
end

function obj:bindWindowsHotkeys(mapping)
    hs.inspect(mapping)

    hs.hotkey.bind(mapping.down[1], mapping.down[2], function()
        self:set_all_windows_positions()
    end)

    hs.hotkey.bind(mapping.right[1], mapping.right[2], function()
        self:setWindow(4, 0, 5, 2)
    end)

    hs.hotkey.bind(mapping.left[1], mapping.left[2], function()
        self:setWindow(0, 0, 7, 4)
    end)

    hs.hotkey.bind(mapping.up[1], mapping.up[2], function()
        self:setWindow(0, 0, 7, 6)
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
    -- local logger = hs.logger.new("window", 'verbose')
    -- local app = window:application()
    -- logger.d(" ")
    -- logger.d("App Title: ")
    -- logger.d(app:title())
    -- logger.d("Bundle Id:")
    -- logger.d(app:bundleID())
    -- logger.d("Win Title:")
    -- logger.d(window:title())
    -- logger.d("Win Id:")
    -- logger.d(window:id())
    -- logger.d(" ")
end

return obj