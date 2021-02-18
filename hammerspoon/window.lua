local obj = {}
obj.__index = obj

obj.GRID = {
    w = 6,
    h = 7
}

function obj:setWindow(x, y, height, width, win)

    if win == null then
        win = hs.window.frontmostWindow()
    end

    local screen = win:screen()

    cell = hs.grid.get(win, screen)
    cell.x = x
    cell.y = y
    cell.h = height
    cell.w = width

    hs.grid.set(win, cell, screen)
end

function obj:bindWindowsHotkeys(mapping)
    hs.inspect(mapping)

    hs.hotkey.bind(mapping.down[1], mapping.down[2], function()

        local wins = hs.window.visibleWindows()
        for _, win in ipairs(wins) do
            local name = win:title()
            if name == 'Telegram' then
                self:setWindow(4, 0, 5, 2, win)
            else
                self:setWindow(0, 0, 7, 4, win)
            end
        end
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
    hs.grid.setGrid(obj.GRID.w .. 'x' .. obj.GRID.h)
    hs.grid.MARGINX = 0
    hs.grid.MARGINY = 0
    animationDuration = 0.08
end

return obj
