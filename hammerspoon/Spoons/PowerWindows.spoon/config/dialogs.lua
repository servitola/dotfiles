-- Small windows that are dialogs: they go to the top right corner, not to their
-- app's slot. A window matching any line is a dialog. Add a line:
-- { bundle ID or "*" for any app, conditions }.
--   title / notTitle   Lua pattern the title must / must not match
--   maxSize            { width, height }: the window is strictly smaller
--   maxTitle           the title is at most this many characters
-- Beats overrides and catalog slots; loses to `rule` and to any `false`.
-- Titles assume an English macOS; the lines without one match in any
-- language.
return {
    -- Any app, by title.
    { "*", title = "^Save",   maxSize = { 800, 600 } },
    { "*", title = "^Open",   maxSize = { 800, 600 } },
    { "*", title = "^Export", maxSize = { 800, 600 } },
    { "*", title = "^Import", maxSize = { 800, 600 } },
    { "*", title = "^Print",  maxSize = { 800, 600 } },
    { "*", title = "^Alert",  maxSize = { 500, 300 } },
    { "*", title = "Dialog",  maxSize = { 500, 300 } },
    { "*", title = "Warning", maxSize = { 500, 300 } },

    -- One app, by title.
    { "com.apple.finder",   title = "^Copy",          maxSize = { 600, 250 } },
    { "com.apple.finder",   title = "^Move",          maxSize = { 600, 250 } },
    { "com.apple.Safari",   title = "^Downloads$" },
    { "com.apple.Terminal", notTitle = "^Terminal$",  maxSize = { 500, 300 } },

    -- One app, any small window with a short title.
    { "com.apple.finder",            maxSize = { 500, 300 }, maxTitle = 29 },
    { "com.apple.systempreferences", maxSize = { 500, 300 }, maxTitle = 29 },
    { "com.apple.DiskUtility",       maxSize = { 500, 300 }, maxTitle = 29 },
    { "com.apple.Preview",           maxSize = { 500, 300 }, maxTitle = 29 },
    { "com.apple.TextEdit",          maxSize = { 500, 300 }, maxTitle = 29 },
}
