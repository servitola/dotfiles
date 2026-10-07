return function(powerWindows, geometry, query)
    function powerWindows:_stackWindows(screen)
        local list = {}
        for _, window in ipairs(hs.window.visibleWindows()) do
            if query.isOnScreen(window, screen) and window:isStandard()
                and not self:_skipped(window) then
                local resolved = self:resolve(window)
                if resolved and resolved.slot == "stack" then
                    list[#list + 1] = { window = window, resolved = resolved }
                end
            end
        end
        table.sort(list, function(first, second)
            return first.window:id() < second.window:id()
        end)
        return list
    end

    function powerWindows:_placeStack(screen)
        local list = self:_stackWindows(screen)
        if #list == 0 then return end
        if #list == 1 then
            return self:_place(list[1].window, list[1].resolved, "stack")
        end
        local config, screenFrame = self:_screenLayout(screen)
        local cells = geometry.stackCells(config, screenFrame, #list)
        for index, item in ipairs(list) do
            if item.resolved.keepAspect then
                self:_fit(item.window, cells[index], "topLeft")
            else
                self:_set(item.window, cells[index])
            end
        end
    end
end
