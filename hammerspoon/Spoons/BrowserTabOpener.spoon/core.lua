-- Everything that needs no Hammerspoon: tested with plain `lua tests/run.lua`.
local core = {}

local OPTIONS = { prefer = "string" }

function core.check(pattern, url, options)
    if type(pattern) ~= "string" or pattern == "" then error("pattern: a non-empty piece of the tab's address, got " .. tostring(pattern), 0) end
    if type(url) ~= "string" or url == "" then error("url: the address to open when no tab matches, got " .. tostring(url), 0) end
    if options == nil then return end
    if type(options) ~= "table" then error("options must be a table, got " .. type(options), 0) end
    for key, value in pairs(options) do
        if not OPTIONS[key] then error("unknown option \"" .. tostring(key) .. "\"", 0) end
        if type(value) ~= OPTIONS[key] then error(key .. " must be a " .. OPTIONS[key] .. ", got " .. type(value), 0) end
    end
end

-- Whatever the expression returns, AppleScript gets the text "true" or "false".
function core.condition(javascript)
    if not javascript then return "" end
    return "String(!!(" .. javascript .. "))"
end

-- The bundle id is the only value written into the script: `tell application id` has to
-- be a literal for AppleScript to load the browser's dictionary. Hence the strict shape.
-- The pattern and the condition travel as arguments and are never parsed as code.
--
-- A condition that cannot run (the browser forbids JavaScript from Apple Events) does not
-- stop the switch; its error text comes back on a second line so it can be shown once.
--
-- Matching tabs are walked from the last one back: new tabs open on the right, so the
-- first press lands on the newest.
local SCRIPT = [[
on run argv
    set urlPattern to item 1 of argv
    set preferred to item 2 of argv
    tell application id "%s"
        if (count of windows) = 0 then return "none"
        set matched to {}
        set conditionFailure to ""
        set currentPosition to 0
        set activeIndex to active tab index of front window
        set tabIndex to 0
        repeat with candidate in tabs of front window
            set tabIndex to tabIndex + 1
            if URL of candidate contains urlPattern then
                if preferred is not "" then
                    try
                        if (execute candidate javascript preferred) is "true" then
                            set active tab index of front window to tabIndex
                            activate
                            return "ok"
                        end if
                    on error failureText
                        set conditionFailure to failureText
                    end try
                end if
                set end of matched to tabIndex
                if tabIndex = activeIndex then set currentPosition to (count of matched)
            end if
        end repeat
        if (count of matched) = 0 then return "none" & linefeed & conditionFailure
        if currentPosition > 1 then
            set nextPosition to currentPosition - 1
        else
            set nextPosition to (count of matched)
        end if
        set active tab index of front window to item nextPosition of matched
        activate
        return "ok" & linefeed & conditionFailure
    end tell
end run
]]

function core.script(bundle)
    if type(bundle) ~= "string" or not bundle:match("^[%w%.%-_]+$") then
        error("browser: a bundle id like \"com.google.Chrome\", got " .. tostring(bundle), 0)
    end
    return SCRIPT:format(bundle)
end

function core.result(exitCode, output)
    if exitCode ~= 0 then return "failed" end
    local status, note = (output or ""):match("^(%a+)\n?([^\n]*)")
    if status ~= "ok" and status ~= "none" then return "failed" end
    return status, note ~= "" and note or nil
end

-- -1743 is macOS refusing Automation; everything else means the browser cannot be scripted
-- this way (Firefox and Zen fail to compile the script at all).
function core.problem(stderr)
    if (stderr or ""):find("-1743", 1, true) then return "denied" end
    return "unsupported"
end

local SITE_FIELDS = { pattern = true, url = true, prefer = true }

function core.site(name, entry)
    if type(entry) ~= "table" then error("no \"" .. tostring(name) .. "\" in tabs", 0) end
    for field in pairs(entry) do
        if not SITE_FIELDS[field] then
            error("tabs." .. tostring(name) .. ": unknown field \"" .. tostring(field) .. "\"; a site is { pattern = …, url = …, prefer = … }", 0)
        end
    end
    local options = entry.prefer ~= nil and { prefer = entry.prefer } or nil
    local ok, problem = pcall(core.check, entry.pattern, entry.url, options)
    if not ok then error("tabs." .. tostring(name) .. ": " .. problem, 0) end
    return { pattern = entry.pattern, url = entry.url, options = options }
end

return core
