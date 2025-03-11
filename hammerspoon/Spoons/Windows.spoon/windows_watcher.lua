local window_watcher = nil
function setup_window_watcher()
    window_watcher = hs.window.filter.new(true)
    window_watcher:subscribe(hs.window.filter.windowDestroyed, function(window, app, event)

        -- local window_id = window:id()
        -- local was_dialog = false

        -- for i, id in ipairs(active_small_dialogs) do
        --     if id == window_id then
        --         table.remove(active_small_dialogs, i)
        --         was_dialog = true
        --         break
        --     end
        -- end

        -- if was_dialog and #active_small_dialogs == 0 then
        --     hs.timer.doAfter(0.5, restore_right_panel_windows)
        -- end
    end)

    window_watcher:subscribe(hs.window.filter.windowCreated,
        function(window, app, event)
            -- if is_small_dialog(window) then
            --     hs.timer.doAfter(0.3, function()
            --         set_window_top_right_small(window)
            --     end)
            -- end
        end)
end
