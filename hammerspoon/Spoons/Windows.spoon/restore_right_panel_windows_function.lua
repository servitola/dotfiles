function restore_right_panel_windows()
    if not right_panel_windows_adjusted or #active_small_dialogs > 0 then
        return
    end

    for id, frame in pairs(right_panel_windows_positions) do
        local window = hs.window.get(id)
        if window then
            window:setFrame(frame, animation_duration)
        end
    end

    right_panel_windows_adjusted = false
    right_panel_windows_positions = {}
end
