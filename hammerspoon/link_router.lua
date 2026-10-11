local browsers = require "browsers"

-- Hammerspoon stays the system browser after a reload; without the Spoon every clicked
-- link would vanish, so hand the role back to the real browser instead.
if not spoon.LinkRouter then
    hs.urlevent.setDefaultHandler("http", browsers.main.bundle)
    return
end

local router = spoon.LinkRouter
router.browsers = {
    main = browsers.main.bundle,
    dev  = browsers.known["Google Chrome"].bundle,
    work = browsers.known.Firefox.bundle,
}
router.default = "main"
local work_patterns = { "xd%.adobe%.com" }
for pattern in require("constants").WORK_LINK_PATTERNS:gmatch("[^,]+") do
    table.insert(work_patterns, pattern)
end
router.rules = {
    { router.localNetwork, "dev" },
    { work_patterns,       "work" },
}
router:start()
