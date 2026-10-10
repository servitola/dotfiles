-- Everything that needs no Hammerspoon: tested with plain `lua tests/run.lua`.
local core = {}

-- GlobalProtect has no command line and no scripting dictionary: its only control is the
-- panel under the menu bar icon, whose main button reads "Connect" or "Disconnect".
-- Both scripts open the panel, act, and close it again.
core.READ = [[
tell application "System Events" to tell process "GlobalProtect"
    click menu bar item 1 of menu bar 2
    delay 0.2
    set buttonName to name of button 2 of window 1
    click menu bar item 1 of menu bar 2
    return buttonName
end tell
]]

core.PRESS = [[
tell application "System Events" to tell process "GlobalProtect"
    click menu bar item 1 of menu bar 2
    delay 0.2
    click button 2 of window 1
    delay 0.2
    click menu bar item 1 of menu bar 2
end tell
]]

function core.checkLabels(labels)
    for _, key in ipairs({ "connect", "disconnect" }) do
        if type(labels) ~= "table" or type(labels[key]) ~= "string" or labels[key] == "" then
            error("labels." .. key .. " must be the text of GlobalProtect's button", 0)
        end
    end
    if labels.connect == labels.disconnect then error("labels.connect and labels.disconnect must differ", 0) end
end

-- "Disconnect" contains "connect" in some languages too, so the whole name is compared.
function core.state(buttonName, labels)
    local name = (buttonName or ""):gsub("%s+$", "")
    if name == labels.disconnect then return "connected" end
    if name == labels.connect then return "disconnected" end
    return nil
end

function core.action(wanted, state)
    local toggled = state == "connected" and "disconnect" or "connect"
    if wanted == "toggle" or wanted == toggled then return toggled end
    return nil
end

function core.problem(stderr)
    local text = (stderr or ""):gsub("%s+$", "")
    if text:find("-1743", 1, true) then
        return "macOS does not let Hammerspoon send events: System Settings → Privacy & Security → Automation → Hammerspoon → System Events"
    end
    if text:find("assistive access", 1, true) then
        return "macOS does not let Hammerspoon click: System Settings → Privacy & Security → Accessibility → Hammerspoon"
    end
    if text:find("get process", 1, true) then return "GlobalProtect is not running" end
    if text:find("-1719", 1, true) or text:find("-1728", 1, true) then
        return "GlobalProtect's panel did not open or looks different: " .. text
    end
    return text
end

return core
