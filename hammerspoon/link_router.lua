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
router.rules = {
    { router.localNetwork,                            "dev" },
    { { "workname", "workproject", "xd%.adobe%.com" },      "work" },
}
router:start()
