--- === GruvboxWallpapers ===
---
--- Download and set a random wallpaper from configured collections daily
--- Fetches all candidates once, then tries them in shuffled order
---

local obj = {}
obj.__index = obj

obj.wallpapers_dir = os.getenv("HOME") .. "/Pictures/Wallpapers/GruvBox"
obj.current_wallpaper = nil
obj.dotfiles_path = os.getenv("HOME") .. "/projects/dotfiles"

-- Fetch all wallpaper candidates (one API scan, returns shuffled JSON array)
function obj:fetchAllCandidates()
    local script_path = self.dotfiles_path .. "/macos/helpers/fetch_wallpaper_url.sh"
    local cmd = string.format('zsh "%s" 2>/dev/null', script_path)
    local handle = io.popen(cmd)
    if not handle then
        return nil, "Failed to execute fetch script"
    end

    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()

    if exit_type == "exit" and exit_code ~= 0 then
        return nil, "Fetch script failed: " .. result:gsub("%s+", " ")
    end

    -- Parse JSON array: [{"name":"...", "url":"..."}, ...]
    local candidates = {}
    for name, url in result:gmatch('"name"%s*:%s*"([^"]+)"%s*,%s*"url"%s*:%s*"([^"]+)"') do
        table.insert(candidates, {name = name, url = url})
    end

    if #candidates == 0 then
        return nil, "No wallpaper candidates found"
    end

    return candidates, nil
end

-- Download wallpaper from URL to local path
function obj:downloadWallpaper(url, output_path, name)
    local script_path = self.dotfiles_path .. "/macos/helpers/download_wallpaper.sh"
    local cmd = string.format('zsh "%s" "%s" "%s" "%s" 2>&1', script_path, url, output_path, name)
    local handle = io.popen(cmd)
    if not handle then
        return false, "Failed to execute download script"
    end

    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()

    if exit_type == "exit" and exit_code ~= 0 then
        if result:match("BLOCKLIST:") then
            return "BLOCKLIST", name
        end
        return false, "Download failed: " .. result:gsub("%s+", " ")
    end

    return true, output_path
end

function obj:setRandomWallpaper()
    -- Single API scan: get all candidates shuffled
    local candidates, err = self:fetchAllCandidates()
    if not candidates then
        print("GruvboxWallpapers: " .. (err or "unknown error"))
        return
    end

    print("GruvboxWallpapers: " .. #candidates .. " candidates, trying in order...")

    -- Try candidates one by one (already shuffled, no re-scanning)
    local MAX_TRIES = math.min(#candidates, 10)
    for i = 1, MAX_TRIES do
        local candidate = candidates[i]

        local temp_name = "temp_" .. os.time() .. "_" .. math.random(1000) .. ".jpg"
        local temp_path = self.wallpapers_dir .. "/" .. temp_name

        local success, result = self:downloadWallpaper(candidate.url, temp_path, candidate.name)

        if success == "BLOCKLIST" then
            -- Resolution too low, try next candidate
            print("GruvboxWallpapers: skipping " .. candidate.name .. " (low resolution)")
        elseif not success then
            print("GruvboxWallpapers: download failed for " .. candidate.name .. ", trying next")
        else
            -- Clean up old wallpapers
            if self.current_wallpaper then
                os.remove(self.current_wallpaper)
            end
            local cmd = string.format('find "%s" -type f ! -name "%s" -delete 2>/dev/null', self.wallpapers_dir, temp_name)
            os.execute(cmd)

            -- Move to final location and set
            local final_path = self.wallpapers_dir .. "/" .. candidate.name
            os.rename(temp_path, final_path)
            self.current_wallpaper = final_path
            hs.screen.mainScreen():desktopImageURL("file://" .. self.current_wallpaper:gsub(" ", "%%20"))
            print("GruvboxWallpapers: set " .. candidate.name)
            return
        end
    end

    print("GruvboxWallpapers: failed to set wallpaper after " .. MAX_TRIES .. " tries")
end

function obj:init()
    math.randomseed(os.time())

    -- Ensure wallpapers directory exists
    os.execute(string.format('mkdir -p "%s"', self.wallpapers_dir))

    self:setRandomWallpaper()
    if self.timer then
        self.timer:stop()
    end
    self.timer = hs.timer.doEvery(24*60*60, function() self:setRandomWallpaper() end)
end

return obj
