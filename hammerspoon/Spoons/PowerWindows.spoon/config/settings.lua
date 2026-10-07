-- fractions are shares of the screen.
return {
    hotkeys = true,
    wasd = true,          -- false = arrows only
    -- true = a chord pressed again, the window already there, gives the second
    -- option: left and right the half, fullscreen the native one
    cycle = false,
    keys = {
        mods = { "ctrl", "alt" },
        shiftMods = { "shift", "ctrl", "alt" },
        arrows = {
            left = "left", right = "right",
            fullscreen = "up", arrangeAll = "down",
        },
        shiftedArrows = {
            halfLeft = "left", halfRight = "right",
            top60 = "up", bottom40 = "down",
        },
        letters = {
            left = "a", right = "d",
            fullscreen = "w", arrangeAll = "s",
        },
        shiftedLetters = {
            halfLeft = "a", halfRight = "d",
            top60 = "w", bottom40 = "s",
        },
    },
    -- { key = action }: 🌐⌃key runs the action (docs/macos-keys.md)
    macosKeys = false,

    -- { [bundle] = main/side/corner/stack/dialog, false or a table }
    overrides = {},
    -- function(window, info) -> slot, table, false, or nil to fall through
    rule = false,
    catalog = true,       -- false = ignore config/catalog.lua
    dialogs = true,       -- false = ignore config/dialogs.lua

    split = 0.73,         -- right column start, share of width
    sideHeight = 0.70,    -- upper right slot, share of height
    topShare = 0.60,      -- top60/bottom40 line, share of height
    -- below 1 = share of screen, 1 and up = points;
    -- right edge ÷1.5, bottom ×1.5
    gap = 0.005,
    -- { [screen name], portrait, ultrawide =
    --   { gap, split, sideHeight, topShare, device, dialog } }
    screens = {},

    animation = 0.05,     -- seconds; 0 = one clean move, no motion
    -- true = arrangeAllNow() ~1 s after displays change
    rearrangeOnScreenChange = false,

    focusSets = {},       -- { name = { keep, focus, video, custom } }
    -- lowercase; a front tab titled with one is popped out to PiP by focus sets
    videoTitleMarkers = {
        "youtube", "youtu.be", "twitch", "vimeo", "rutube", "netflix",
    },

    device = {            -- windows with device = true (iOS Simulator)
        width = 0.4,      -- share of screen; wider than the column on purpose
        maxHeight = 0.7,  -- share of screen height, aspect kept
        raise = 0.1,      -- above center in main or full, share of height
    },

    dialog = {
        width = 0.9,      -- max, share of column width
        height = 0.4,     -- max, share of sideHeight
    },

    -- points; this close to a slot = already in it (see cycle)
    tolerance = 4,

    experimental = {
        -- { placeOnLaunch = { bundles, finderFirstWindow } }
    },
}
