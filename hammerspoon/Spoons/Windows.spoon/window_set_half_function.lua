function set_window_half_left(window)
    if not window then
        window = hs.window.frontmostWindow()
    end
    if not window then return end

    local half_line = 0.5
    set_window(leftX, topY, half_line - spacing, bottomY - topY, window)
end

function set_window_half_right(window)
    if not window then
        window = hs.window.frontmostWindow()
    end
    if not window then return end

    local half_line = 0.5
    set_window(half_line, topY, rightX - half_line, bottomY - topY, window)
end

function set_window_top_60(window)
    if not window then
        window = hs.window.frontmostWindow()
    end
    if not window then return end

    local split_line = 0.6
    set_window(leftX, topY, rightX - leftX, split_line - spacing, window)
end

function set_window_bottom_40(window)
    if not window then
        window = hs.window.frontmostWindow()
    end
    if not window then return end

    local split_line = 0.6
    set_window(leftX, split_line, rightX - leftX, bottomY - split_line, window)
end
