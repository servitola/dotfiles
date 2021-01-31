local obj = {}
obj.__index = obj

obj.GRID = {
    w = 6,
    h = 7
}

function obj:setWindow(x, y, height, width)
    if hs.window.focusedWindow() then
        local win = hs.window.frontmostWindow()
        local id = win:id()
        local screen = win:screen()

        cell = hs.grid.get(win, screen)

        cell.x = x
        cell.y = y
        cell.h = height
        cell.w = width

--        os.execute("sleep 1")

        -- cell.x = x
        -- cell.y = y
        -- cell.h = height
        -- cell.w = width

        -- if cell['y'] ~= 0 and cell['y'] + cell['h'] ~= self.GRID['h'] then
        --     cell['h'] = self.GRID['h']
        --     cell['y'] = 0
        -- end

        -- if cell['x'] ~= 0 and cell['x'] + cell['w'] ~= self.GRID['w'] then
        --     cell['w'] = self.GRID['w']
        --     cell['x'] = 0
        -- end

        hs.grid.set(win, cell, screen)
    end
end

function obj:bindWindowsHotkeys(mapping)
    hs.inspect(mapping)

    hs.hotkey.bind(mapping.down[1], mapping.down[2], function()
        self:setWindow(4, 5, 2, 2)
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

function obj:openApp(name)
    local app = hs.application.get(name)
    if app then
        if app:isFrontmost() then
            app:hide()
        else
            app:mainWindow():focus()
        end
    else
        hs.application.launchOrFocus(name)
    end
end

function obj:bindHotkey(mapping)
    hs.inspect(mapping)

    hs.hotkey.bind(mapping.chord[1], mapping.chord[2], function()
        self:openApp(mapping.appname)
    end)

    -- hs.hotkey.bind(mapping.chord[0], mapping.chord[1], function()
    --     self:openApp(mapping.appname)
    -- end)

end

function obj:init()
    hs.grid.setGrid(obj.GRID.w .. 'x' .. obj.GRID.h)
    hs.grid.MARGINX = 0
    hs.grid.MARGINY = 0
end

return obj
