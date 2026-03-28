--- === GruvboxWallpapers ===
---
--- Download and set a random wallpaper from configured collections daily
--- Uses async hs.task to avoid blocking Hammerspoon's main thread
---

local obj = {}
obj.__index = obj

local log = hs.logger.new('GruvboxWallpapers', 'info')

obj.wallpapers_dir = os.getenv("HOME") .. "/Pictures/Wallpapers/GruvBox"
obj.current_wallpaper = nil
obj.dotfiles_path = os.getenv("HOME") .. "/projects/dotfiles"
obj._task = nil  -- prevent GC of long-running hs.task

-- Parse candidates JSON from fetch script output
local function parseCandidates(output)
    local candidates = {}
    for name, url in output:gmatch('"name"%s*:%s*"([^"]+)"%s*,%s*"url"%s*:%s*"([^"]+)"') do
        table.insert(candidates, {name = name, url = url})
    end
    return candidates
end

-- Stream callback: drain pipe buffer to prevent blocking, accumulate output
local function makeStreamCallback(buf)
    return function(_, stdout, stderr)
        if stdout then buf.out = buf.out .. stdout end
        if stderr then buf.err = buf.err .. stderr end
        return true
    end
end

-- Try downloading candidate at index i, then set wallpaper or try next
function obj:tryCandidate(candidates, i, maxTries, fetchAttempt)
    if i > maxTries then
        log.d("all candidates failed, re-fetching...")
        self:setRandomWallpaper(fetchAttempt)
        return
    end

    local candidate = candidates[i]
    local temp_name = "temp_" .. os.time() .. "_" .. math.random(1000) .. ".jpg"
    local temp_path = self.wallpapers_dir .. "/" .. temp_name
    local script_path = self.dotfiles_path .. "/hammerspoon/Spoons/GruvboxWallpapers.spoon/download_wallpaper.sh"
    local buf = {out = "", err = ""}

    if self._task then self._task:terminate() end
    self._task = hs.task.new("/bin/zsh", function(exitCode)
        self._task = nil
        if exitCode ~= 0 then
            if buf.out:match("BLOCKLIST:") then
                log.d("skipping " .. candidate.name .. " (low resolution)")
            else
                log.d("download failed for " .. candidate.name .. ", trying next")
            end
            self:tryCandidate(candidates, i + 1, maxTries, fetchAttempt)
            return
        end

        -- Extract extension from original name
        local ext = candidate.name:match("%.([^%.]+)$") or "jpg"
        local final_name = "current_wallpaper." .. ext
        local final_path = self.wallpapers_dir .. "/" .. final_name

        -- Clean up all previous wallpapers in the directory
        for file in hs.fs.dir(self.wallpapers_dir) do
            if file ~= "." and file ~= ".." and file ~= temp_name then
                os.remove(self.wallpapers_dir .. "/" .. file)
            end
        end

        os.rename(temp_path, final_path)
        self.current_wallpaper = final_path
        hs.screen.mainScreen():desktopImageURL("file://" .. final_path)
        log.i("set " .. candidate.name .. " as " .. final_name)
    end, makeStreamCallback(buf), {script_path, candidate.url, temp_path, candidate.name})
    self._task:start()
end

local MAX_FETCH_ATTEMPTS = 10

function obj:setRandomWallpaper(attempt)
    attempt = attempt or 1
    if attempt > MAX_FETCH_ATTEMPTS then
        log.w("giving up after " .. MAX_FETCH_ATTEMPTS .. " fetch attempts")
        return
    end

    local script_path = self.dotfiles_path .. "/hammerspoon/Spoons/GruvboxWallpapers.spoon/fetch_wallpaper_url.sh"
    local buf = {out = "", err = ""}

    if self._task then self._task:terminate() end
    self._task = hs.task.new("/bin/zsh", function(exitCode)
        self._task = nil
        if exitCode ~= 0 then
            log.w("fetch failed: " .. (buf.err ~= "" and buf.err or "unknown error"))
            return
        end

        local candidates = parseCandidates(buf.out)
        if #candidates == 0 then
            log.d("no candidates, re-fetching (attempt " .. attempt .. ")...")
            self:setRandomWallpaper(attempt + 1)
            return
        end

        log.d(#candidates .. " candidates, trying in order...")
        local maxTries = math.min(#candidates, 10)
        self:tryCandidate(candidates, 1, maxTries, attempt + 1)
    end, makeStreamCallback(buf), {script_path})
    self._task:start()
end

function obj:init()
    math.randomseed(os.time())
    hs.fs.mkdir(self.wallpapers_dir)

    self:setRandomWallpaper()
    if self.timer then
        self.timer:stop()
    end
    self.timer = hs.timer.doEvery(24*60*60, function() self:setRandomWallpaper() end)
end

return obj
