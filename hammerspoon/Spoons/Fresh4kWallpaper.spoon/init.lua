--- === Fresh4kWallpaper ===
---
--- A new 4K wallpaper every time Hammerspoon starts. One file on disk, ever.
local obj = {}
obj.__index = obj

obj.name = "Fresh4kWallpaper"
obj.version = "0.2.0"
obj.author = "servitola"
obj.homepage = "https://github.com/servitola/Fresh4kWallpaper.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

local core = dofile(hs.spoons.scriptPath() .. "core.lua")
local log = hs.logger.new("Fresh4kWallpaper", "info")

--- Fresh4kWallpaper.sources
--- Variable
--- GitHub collections: `"owner/repo"` for every picture in a repository, `"owner/repo/path"`
--- for one folder of it, subfolders included.
obj.sources = {
    "AngelJumbo/gruvbox-wallpapers/wallpapers",
    "Nix3l/wallpapers",
    "dharmx/walls",
    "makccr/wallpapers/wallpapers",
    "Ajaymanikandan0x/hyprland_wallpapers",
}

--- Fresh4kWallpaper.dir
--- Variable
--- Where the current wallpaper, `history.log`, `blocklist.txt` and the cached file lists live.
--- Only files this Spoon wrote (`Fresh4kWallpaper-<time>.<ext>`) are ever deleted from it.
obj.dir = os.getenv("HOME") .. "/Pictures/Fresh4kWallpaper"

--- Fresh4kWallpaper.only4k
--- Variable
--- `true`: a picture smaller than 3840×2160 is skipped and never tried again. `false`: any size.
obj.only4k = true

--- Fresh4kWallpaper.interval
--- Variable
--- Seconds between changes while Hammerspoon keeps running. Default: a day.
obj.interval = 24 * 60 * 60

--- Fresh4kWallpaper.changeOnStart
--- Variable
--- `true`: `start()` changes the wallpaper right away. `false`: only the timer does.
obj.changeOnStart = true

--- Fresh4kWallpaper.historySize
--- Variable
--- How many recent pictures are not shown again.
obj.historySize = 100

--- Fresh4kWallpaper.cacheDays
--- Variable
--- How long the list of a collection's files is reused before GitHub is asked again.
obj.cacheDays = 7

--- Fresh4kWallpaper.token
--- Variable
--- Optional GitHub token. Not needed in normal use: one request per collection per `cacheDays`
--- stays far below the 60 an hour GitHub allows without one.
obj.token = nil

-- Collections tried per change (an exhausted one asks for another) and downloads per collection.
local MAX_SOURCES = 10
local MAX_DOWNLOADS = 10

local function readAll(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local text = file:read("a")
    file:close()
    return text
end

local function writeAll(path, text)
    local file = assert(io.open(path, "w"))
    file:write(text)
    file:close()
end

local function readLines(path)
    local lines = {}
    local file = io.open(path, "r")
    if not file then return lines end
    for line in file:lines() do
        if line ~= "" then lines[#lines + 1] = line end
    end
    file:close()
    return lines
end

local function writeLines(path, lines)
    local file = assert(io.open(path, "w"))
    for _, line in ipairs(lines) do file:write(line, "\n") end
    file:close()
end

local function appendLine(path, line)
    local file = assert(io.open(path, "a"))
    file:write(line, "\n")
    file:close()
end

function obj:_path(name) return self.dir .. "/" .. name end

function obj:_seen()
    local seen = {}
    for _, file in ipairs({ "history.log", "blocklist.txt" }) do
        for _, name in ipairs(readLines(self:_path(file))) do seen[name] = true end
    end
    return seen
end

function obj:_current(run) return run == self._run end

-- done(collection) with { repo, paths }, read from the cache while it is fresh.
function obj:_collection(run, repo, done)
    local file = self:_path("cache/" .. core.cacheName(repo))
    local cached = core.parse(readAll(file))
    if cached and not core.isStale(hs.fs.attributes(file, "modification"), os.time(), self.cacheDays) then
        return done(cached)
    end
    local headers = self.token and { Authorization = "Bearer " .. self.token } or nil
    hs.http.asyncGet(core.treeURL(repo), headers, function(status, body)
        if not self:_current(run) then return end
        local answer = hs.json.decode(body or "")
        if status ~= 200 or type(answer) ~= "table" or not answer.tree then
            local reason = type(answer) == "table" and answer.message or ("HTTP " .. tostring(status))
            log.w(repo .. ": " .. tostring(reason))
            -- An old list still finds pictures. Without one the change stops here: the usual
            -- cause is the rate limit, and asking another collection only extends it.
            if cached then done(cached) end
            return
        end
        local fresh = { repo = core.canonicalRepo(answer.url) or repo, paths = core.images(answer.tree) }
        writeAll(file, core.serialize(fresh.repo, fresh.paths))
        done(fresh)
    end)
end

function obj:_pick(run, attempt)
    if attempt > MAX_SOURCES then
        log.w("no usable picture after " .. MAX_SOURCES .. " tries, keeping the current wallpaper")
        return
    end
    local source = core.parseSource(self.sources[math.random(#self.sources)])
    self:_collection(run, source.repo, function(collection)
        local paths = core.unseen(core.under(collection.paths, source.path), self:_seen())
        self:_try(run, attempt, collection.repo, core.shuffle(paths, math.random), 1)
    end)
end

function obj:_try(run, attempt, repo, paths, index)
    local picture = paths[index]
    if not picture or index > MAX_DOWNLOADS then return self:_pick(run, attempt + 1) end
    local function nextCandidate() self:_try(run, attempt, repo, paths, index + 1) end

    hs.http.asyncGet(core.rawURL(repo, picture, hs.http.encodeForQuery), nil, function(status, body)
        if not self:_current(run) then return end
        if status ~= 200 or not body or #body == 0 then
            log.d(picture .. ": download failed (HTTP " .. tostring(status) .. ")")
            return nextCandidate()
        end
        local download = self:_path(".download")
        local file = assert(io.open(download, "wb"))
        file:write(body)
        file:close()
        if not self.only4k then return self:_apply(picture, download) end

        -- sips, not hs.image: NSImage reports points, so a 144 dpi picture reads as half its size.
        self._task = hs.task.new("/usr/bin/sips", function(_, output)
            self._task = nil
            if not self:_current(run) then return end
            local width, height = core.pixels(output or "")
            if core.is4k(width, height) then return self:_apply(picture, download) end
            os.remove(download)
            if width then
                appendLine(self:_path("blocklist.txt"), core.key(picture))
                log.d(picture .. ": " .. width .. "×" .. height .. ", below 4K")
            else
                log.d(picture .. ": not a readable picture")
            end
            nextCandidate()
        end, { "-g", "pixelWidth", "-g", "pixelHeight", download })
        self._task:start()
    end)
end

function obj:_apply(picture, download)
    local previous = {}
    for file in hs.fs.dir(self.dir) do
        if core.isOurs(file) then previous[#previous + 1] = file end
    end
    for _, file in ipairs(previous) do os.remove(self:_path(file)) end
    local wallpaper = self:_path(core.fileName(os.time(), picture))
    assert(os.rename(download, wallpaper))
    hs.screen.mainScreen():desktopImageURL("file://" .. wallpaper)

    local history = readLines(self:_path("history.log"))
    history[#history + 1] = core.key(picture)
    writeLines(self:_path("history.log"), core.tail(history, self.historySize))
    log.i(picture)
end

--- Fresh4kWallpaper:next() -> self
--- Method
--- Changes the wallpaper now. A change still in flight is abandoned.
function obj:next()
    self._run = self._run + 1
    hs.fs.mkdir(self.dir)
    hs.fs.mkdir(self:_path("cache"))
    os.remove(self:_path(".download"))
    self:_pick(self._run, 1)
    return self
end

--- Fresh4kWallpaper:start() -> self
--- Method
--- Changes the wallpaper (unless `changeOnStart` is `false`) and then once every `interval`.
function obj:start()
    self:stop()
    if self.changeOnStart then self:next() end
    self._timer = hs.timer.doEvery(self.interval, function() self:next() end)
    return self
end

--- Fresh4kWallpaper:stop() -> self
--- Method
--- Stops the timer and abandons a change in flight. The wallpaper stays.
function obj:stop()
    if self._timer then self._timer:stop() self._timer = nil end
    self._run = self._run + 1
    return self
end

--- Fresh4kWallpaper:bindHotkeys(mapping) -> self
--- Method
--- `mapping.next` — a hotkey for `next()`, e.g. `{ next = { { "ctrl", "alt", "cmd" }, "w" } }`.
function obj:bindHotkeys(mapping)
    hs.spoons.bindHotkeysToSpec({ next = function() self:next() end }, mapping)
    return self
end

function obj:init()
    self._run = 0
    math.randomseed(os.time())
    return self
end

return obj
