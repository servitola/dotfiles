local M = {}

local function focusSet(set)
    return function()
        hs.closeConsole()
        spoon.PowerWindows:focusSet(set)
    end
end

-- Literal register() calls: lint.py finds registered actions by reading them.
function M.register(register)
    register("window.focus_work", focusSet("work"))
    register("window.focus_personal", focusSet("personal"))
    register("window.focus_comms", focusSet("comms"))
    register("window.hide_all_except_work", focusSet("only-work"))
end

return M
