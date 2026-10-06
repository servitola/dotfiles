local M = {}

-- Every browser pops video out into a separate window, and its title is the only
-- hook to catch it by. Engines name it differently; both variants were captured from
-- a live window on this machine (Zen 2026-08, Chrome 152): Gecko writes
-- "Picture-in-Picture", Chromium — "Picture in Picture".
local GECKO_VIDEO_TITLE = "Picture-in-Picture"
local CHROMIUM_VIDEO_TITLE = "Picture in Picture"

-- Gecko: ⌘⌥⇧] — browser.xhtml, key_togglePictureInPicture, modifiers accel,alt,shift.
-- Verified on a live Zen: the "Picture-in-Picture" window appears.
local GECKO_PIP_CHORD = { mods = { "cmd", "alt", "shift" }, key = "]" }

-- title_suffix — a second net for browsers that stamp their brand into a normal
-- window's title: a title with no brand is a popup, even if the player itself is localized.
-- Zen/Firefox/Chrome/Opera title normal windows with the bare page name,
-- so for them only an exact video_title match is left to rely on.
M.known = {
    Zen = {
        app         = "Zen",
        bundle      = "app.zen-browser.zen",
        video_title = GECKO_VIDEO_TITLE,
        pip_chord   = GECKO_PIP_CHORD,
    },
    Firefox = {
        app         = "Firefox",
        bundle      = "org.mozilla.firefox",
        video_title = GECKO_VIDEO_TITLE,
        pip_chord   = GECKO_PIP_CHORD,
    },
    Vivaldi = {
        app              = "Vivaldi",
        bundle           = "com.vivaldi.Vivaldi",
        video_title      = CHROMIUM_VIDEO_TITLE,
        title_suffix     = " - Vivaldi",
    },
    Yandex = {
        app              = "Yandex",
        bundle           = "ru.yandex.desktop.yandex-browser",
        video_title      = CHROMIUM_VIDEO_TITLE,
        -- «— Yandex Browser» with nbsp before Browser in bytes
        title_suffix     = string.char(226, 128, 148, 32, 89, 97, 110, 100, 101, 120,
                                       194, 160, 66, 114, 111, 119, 115, 101, 114),
    },
    ["Google Chrome"] = {
        app              = "Google Chrome",
        bundle           = "com.google.Chrome",
        video_title      = CHROMIUM_VIDEO_TITLE,
    },
    Opera = {
        app              = "Opera",
        bundle           = "com.operasoftware.Opera",
        video_title      = CHROMIUM_VIDEO_TITLE,
    },
}

-- Tab title that signals video is playing there and it's worth popping out
-- into its own window. This is about the site, not the browser — hence the shared list.
M.video_page_markers = {
    "youtube", "youtu.be", "twitch", "vimeo", "rutube",
    "кинопоиск", "kinopoisk", "netflix",
}

function M.title_looks_like_video(title)
    if not title or title == "" then return false end
    local lower = title:lower()
    for _, marker in ipairs(M.video_page_markers) do
        if lower:find(marker, 1, true) then return true end
    end
    return false
end

function M.by_app(app_title)
    if not app_title then return nil end
    for _, browser in pairs(M.known) do
        if browser.app == app_title then return browser end
    end
    return nil
end

function M.is_video_window(app_title, window_title)
    local browser = M.by_app(app_title)
    if not browser or not window_title or window_title == "" then return false end
    if browser.video_title and window_title == browser.video_title then return true end
    if not browser.title_suffix then return false end
    return window_title:sub(-#browser.title_suffix) ~= browser.title_suffix
end

local chosen = require("constants").APP_BROWSER
M.main = assert(M.by_app(chosen), "browsers: APP_BROWSER is not in M.known: " .. tostring(chosen))

return M
