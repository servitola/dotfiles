local core = require "core"

local function config(fields)
    local base = { primary = "ABC", secondary = "Russian – PC", secondaryApps = { "org.telegram", "org.chat" }, overrides = {} }
    for key, value in pairs(fields or {}) do base[key] = value end
    return base
end

eq(core.resolve("com.other", config()), "ABC", "resolve: primary for an ordinary app")
eq(core.resolve("org.telegram", config()), "Russian – PC", "resolve: secondary for a listed app")
eq(core.resolve("org.telegram", config({ overrides = { ["org.telegram"] = "Greek" } })), "Greek", "resolve: an override beats the list")
eq(core.resolve("org.telegram", config({ overrides = { ["org.telegram"] = false } })), nil, "resolve: false leaves the app alone")
eq(core.resolve("com.other", config({ overrides = { ["com.other"] = "Greek" } })), "Greek", "resolve: an override beats primary")

local noSecondary = config()
noSecondary.secondary = nil
eq(core.resolve("org.telegram", noSecondary), "ABC", "resolve: no secondary layout, a listed app is ordinary")

local noPrimary = config()
noPrimary.primary = nil
eq(core.resolve("com.other", noPrimary), nil, "resolve: no primary, an ordinary app is left alone")
eq(core.resolve("org.telegram", noPrimary), "Russian – PC", "resolve: secondary without a primary")
eq(core.resolve("com.other", config({ secondaryApps = {} })), "ABC", "resolve: empty list")

local known = {
    layouts = { "ABC", "Russian – PC", "Greek" },
    methods = { "Pinyin – Simplified" },
    sources = { "com.apple.keylayout.ABC", "com.apple.keylayout.RussianWin", "com.apple.inputmethod.SCIM.ITABC" },
}
eq(core.kind("ABC", known), "layout", "kind: layout name")
eq(core.kind("Pinyin – Simplified", known), "method", "kind: input method name")
eq(core.kind("com.apple.keylayout.RussianWin", known), "source", "kind: input source id")
eq(core.kind("Rusian", known), nil, "kind: unknown")

eq(pcall(core.validate, config(), known), true, "validate: good config")
eq(pcall(core.validate, { secondaryApps = {}, overrides = {} }, known), true, "validate: nothing configured")

local ok, message = pcall(core.validate, config({ overrides = { ["org.telegram"] = "Rusian" } }), known)
eq(ok, false, "validate: unknown layout raises")
eq(message:find('"Rusian"', 1, true) ~= nil, true, "validate: names the wrong value")
eq(message:find("org.telegram", 1, true) ~= nil, true, "validate: names the app")
eq(message:find("Russian – PC", 1, true) ~= nil, true, "validate: lists what is installed")

ok, message = pcall(core.validate, config({ primary = "Englsh" }), known)
eq(ok, false, "validate: unknown primary raises")
eq(message:find("primary", 1, true) ~= nil, true, "validate: says it is primary")
ok, message = pcall(core.validate, config({ secondary = "Rusian" }), known)
eq(ok, false, "validate: unknown secondary raises")
eq(message:find("secondary", 1, true) ~= nil, true, "validate: says it is secondary")

eq(pcall(core.validate, config({ primary = 42 }), known), false, "validate: primary must be a string")
eq(pcall(core.validate, config({ overrides = { ["org.telegram"] = true } }), known), false, "validate: true is not a layout")
eq(pcall(core.validate, config({ overrides = { [1] = "ABC" } }), known), false, "validate: a bundle id is a string")
eq(pcall(core.validate, config({ overrides = "ABC" }), known), false, "validate: overrides is a table")
eq(pcall(core.validate, config({ secondaryApps = "org.telegram" }), known), false, "validate: secondaryApps is a list")
eq(pcall(core.validate, config({ secondaryApps = { 7 } }), known), false, "validate: secondaryApps holds bundle ids")
