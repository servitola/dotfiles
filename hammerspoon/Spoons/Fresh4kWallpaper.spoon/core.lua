-- Everything that needs no Hammerspoon: tested with plain `lua tests/run.lua`.
local core = {}

local PREFIX = "Fresh4kWallpaper-"
local IMAGE_EXTENSIONS = { png = true, jpg = true, jpeg = true, webp = true, heic = true }
local DAY = 24 * 60 * 60

local function extension(name)
    return (name:match("%.(%w+)$") or ""):lower()
end

function core.parseSource(source)
    if type(source) ~= "string" then error("a source is \"owner/repo\" or \"owner/repo/path\", got " .. type(source)) end
    local owner, repo, path = source:match("^([^/]+)/([^/]+)/?(.*)$")
    if not owner then error("a source is \"owner/repo\" or \"owner/repo/path\", got \"" .. source .. "\"") end
    return { repo = owner .. "/" .. repo, path = (path:gsub("/+$", "")) }
end

-- One request lists every file of a repository; cached, it replaces a request per folder on
-- every change and keeps an anonymous user far from GitHub's 60 requests an hour.
function core.treeURL(repo)
    return "https://api.github.com/repos/" .. repo .. "/git/trees/HEAD?recursive=1"
end

function core.rawURL(repo, path, encode)
    return "https://raw.githubusercontent.com/" .. repo .. "/HEAD/" .. encode(path)
end

-- The API follows a renamed repository, raw.githubusercontent.com does not: the name the
-- tree answers with is the one downloads have to use.
function core.canonicalRepo(treeUrl)
    return treeUrl and treeUrl:match("/repos/([^/]+/[^/]+)/git/trees/")
end

function core.cacheName(repo)
    return (repo:gsub("/", "__")) .. ".txt"
end

function core.images(tree)
    local paths = {}
    for _, item in ipairs(tree or {}) do
        local hidden = item.path:sub(1, 1) == "." or item.path:find("/.", 1, true)
        if item.type == "blob" and not hidden and IMAGE_EXTENSIONS[extension(item.path)] then
            paths[#paths + 1] = item.path
        end
    end
    return paths
end

function core.under(paths, folder)
    if folder == "" then return paths end
    local prefix, kept = folder .. "/", {}
    for _, path in ipairs(paths) do
        if path:sub(1, #prefix) == prefix then kept[#kept + 1] = path end
    end
    return kept
end

-- Some collections mark files with a leading underscore and later drop it;
-- history and the blocklist must recognise the picture either way.
function core.key(path)
    return (path:match("([^/]+)$"):gsub("^_", ""))
end

function core.unseen(paths, seen)
    local fresh = {}
    for _, path in ipairs(paths) do
        if not seen[core.key(path)] then fresh[#fresh + 1] = path end
    end
    return fresh
end

function core.serialize(repo, paths)
    return repo .. "\n" .. table.concat(paths, "\n") .. "\n"
end

function core.parse(text)
    local lines = {}
    for line in (text or ""):gmatch("[^\n]+") do lines[#lines + 1] = line end
    if #lines == 0 then return nil end
    return { repo = table.remove(lines, 1), paths = lines }
end

function core.isStale(fetchedAt, now, days)
    return fetchedAt == nil or now - fetchedAt > days * DAY
end

function core.shuffle(list, random)
    for i = #list, 2, -1 do
        local j = random(i)
        list[i], list[j] = list[j], list[i]
    end
    return list
end

function core.tail(lines, limit)
    local kept = {}
    for i = math.max(1, #lines - limit + 1), #lines do kept[#kept + 1] = lines[i] end
    return kept
end

-- A new name every time: macOS caches the desktop picture by path and keeps
-- showing the old one when a file is replaced in place.
function core.fileName(time, name)
    return PREFIX .. time .. "." .. extension(name)
end

function core.isOurs(file)
    return file:match("^" .. PREFIX:gsub("%-", "%%-") .. "%d+%.%w+$") ~= nil
end

function core.is4k(width, height)
    return width ~= nil and height ~= nil and width >= 3840 and height >= 2160
end

function core.pixels(sipsOutput)
    local width = tonumber(sipsOutput:match("pixelWidth: (%d+)"))
    local height = tonumber(sipsOutput:match("pixelHeight: (%d+)"))
    if width and height then return width, height end
    return nil
end

return core
