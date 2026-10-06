local M = { _fns = {} }

function M.register(name, fn)
    if type(name) ~= "string" or name == "" then
        error("action name must be a non-empty string, got " .. tostring(name), 2)
    end
    if type(fn) ~= "function" then
        error("action '" .. name .. "' must be a function, got " .. type(fn), 2)
    end
    if M._fns[name] then
        error("action '" .. name .. "' is already registered", 2)
    end
    M._fns[name] = fn
end

function M.get(name)
    return M._fns[name]
end

function M.names()
    local out = {}
    for name in pairs(M._fns) do table.insert(out, name) end
    table.sort(out)
    return out
end

return M
