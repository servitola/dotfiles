-- Run from the Spoon dir: lua tests/run.lua
package.path = "./?.lua;./tests/?.lua;" .. package.path

local failures, checks = {}, 0

function eq(got, want, label)
    checks = checks + 1
    if got ~= want then
        failures[#failures + 1] = string.format("%s: got %s, want %s", label, tostring(got), tostring(want))
    end
end

local listing = assert(io.popen("ls tests/test_*.lua"))
for path in listing:lines() do
    local name = path:match("tests/(test_[%w_]+)%.lua$")
    local ok, message = pcall(require, name)
    if not ok then failures[#failures + 1] = name .. ": " .. tostring(message) end
end
listing:close()

if #failures > 0 then
    print("FAIL (" .. #failures .. "/" .. checks .. ")\n" .. table.concat(failures, "\n"))
    os.exit(1)
end
print("PASS " .. checks)
