-- Constants of this machine

local home = os.getenv("HOME")
local path = home .. "/projects/dotfiles/constants.env"

local fh = assert(io.open(path, "r"), "constants: cannot read " .. path)
local K = {}
for line in fh:lines() do
    local key, value = line:match("^([%w_]+)=(.*)$")
    if key then K[key] = value:gsub("%$HOME", home) end
end
fh:close()

return K
