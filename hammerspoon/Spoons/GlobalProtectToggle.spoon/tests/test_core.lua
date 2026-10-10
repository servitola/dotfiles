local core = require "core"

local labels = { connect = "Connect", disconnect = "Disconnect" }
eq(core.state("Disconnect\n", labels), "connected", "state: the button offers to disconnect")
eq(core.state("Connect\n", labels), "disconnected", "state: the button offers to connect")
eq(core.state("Connecting...\n", labels), nil, "state: in between is neither")
eq(core.state("", labels), nil, "state: no button name")
eq(core.state("Trennen", { connect = "Verbinden", disconnect = "Trennen" }), "connected", "state: labels in another language")

eq(core.action("toggle", "connected"), "disconnect", "action: toggle when connected")
eq(core.action("toggle", "disconnected"), "connect", "action: toggle when disconnected")
eq(core.action("connect", "disconnected"), "connect", "action: connect when disconnected")
eq(core.action("connect", "connected"), nil, "action: already connected")
eq(core.action("disconnect", "connected"), "disconnect", "action: disconnect when connected")
eq(core.action("disconnect", "disconnected"), nil, "action: already disconnected")

eq(core.problem('execution error: System Events got an error: Can’t get process "GlobalProtect". (-1728)'), "GlobalProtect is not running", "problem: no process")
eq(core.problem("execution error: System Events got an error: osascript is not allowed assistive access. (-25211)"):find("Accessibility", 1, true) ~= nil, true, "problem: Accessibility")
eq(core.problem("execution error: Not authorized to send Apple events to System Events. (-1743)"):find("Automation", 1, true) ~= nil, true, "problem: Automation")
eq(core.problem("execution error: System Events got an error: Can’t get window 1 of process \"GlobalProtect\". Invalid index. (-1719)"):find("panel", 1, true) ~= nil, true, "problem: the panel did not open")
eq(core.problem("something else entirely\n"), "something else entirely", "problem: anything else is shown as is")

eq(pcall(core.checkLabels, labels), true, "labels: both present")
eq(pcall(core.checkLabels, { connect = "Connect" }), false, "labels: disconnect is required")
eq(pcall(core.checkLabels, { connect = "", disconnect = "x" }), false, "labels: not empty")
eq(pcall(core.checkLabels, { connect = "Connect", disconnect = "Connect" }), false, "labels: must differ")
