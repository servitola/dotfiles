-- Displays.spoon — configuration.
-- Machine-independent: these dotfiles get rolled out to other machines too,
-- so a specific display's UUID and a specific internal screen's name
-- aren't hardcoded here.
return {
    -- The only machine-specific knowledge: what Apple's internal displays are
    -- called. This set has been historically stable and is the same on every
    -- Mac.
    -- The hyphen is escaped: in Lua patterns "-" is a quantifier, which is
    -- why hs.screen.find("Built-in") fails to find the screen.
    INTERNAL_NAME_PATTERNS = { "^Built%-in", "^Color LCD", "^iMac" },

    -- Per-machine override for when auto-classification misses (multiple
    -- external screens with a non-obvious priority). Filled in ONLY through
    -- the private overlay — the UUID is tied to the hardware.
    PREFERRED_EXTERNAL_UUIDS = {},

    -- How many seconds after setFrame to verify the actual result.
    PARK_VERIFY_DELAY = 0.3,

    -- How many seconds to wait for the second screen to appear after mirrorStop().
    EXTEND_TIMEOUT = 8,

    -- Pause between rescuing windows and collapsing the topology into mirror.
    UNPARK_SETTLE_DELAY = 0.4,

    -- How many seconds to wait after the last display-configuration-change
    -- event before laying out windows. A change fires a burst of events, and
    -- macOS keeps moving windows around by itself for a while after — laying
    -- out before that settles would get overwritten.
    RELAYOUT_SETTLE_DELAY = 2.0,

    -- Tolerance when comparing geometry, in pixels.
    GEOMETRY_TOLERANCE = 4,
}
