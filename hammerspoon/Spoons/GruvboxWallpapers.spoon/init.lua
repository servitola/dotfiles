--- === GruvboxWallpapers ===
---
--- Download and set a random wallpaper from gruvbox collection daily
--- Downloads one random filtered wallpaper instead of syncing all locally
---

local obj = {}
obj.__index = obj

obj.wallpapers_dir = os.getenv("HOME") .. "/Pictures/Wallpapers/GruvBox"
obj.current_wallpaper = nil
obj.dotfiles_path = os.getenv("HOME") .. "/projects/dotfiles"

-- Fetch a random wallpaper URL from available gruvbox repositories
function obj:fetchRandomWallpaperURL()
    local script_path = self.dotfiles_path .. "/macos/helpers/fetch_wallpaper_url.sh"
    local cmd = string.format('zsh "%s" 2>&1', script_path)
    local handle = io.popen(cmd)
    if not handle then
        return nil, "Failed to execute fetch script"
    end

    local result = handle:read("*a")
    local success, exit_type, exit_code = handle:close()

    if exit_type == "exit" and exit_code ~= 0 then
        return nil, "Fetch script failed: " .. result:gsub("%s+", " ")
    end

    -- Parse JSON output: {"name": "...", "url": "..."}
    local name = result:match('"name"%:%s*"([^"]+)"')
    local url = result:match('"url"%:%s*"([^"]+)"')

    if not name or not url then
        return nil, "Failed to parse wallpaper URL from: " .. result
    end

    return {name = name, url = url}, nil
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
        -- Check if it was a resolution failure (wallpaper was blocklisted)
        if result:match("BLOCKLIST:") then
            return "BLOCKLIST", name
        end
        return false, "Download failed: " .. result:gsub("%s+", " ")
    end

    return true, output_path
end

function obj:setRandomWallpaper()
    local MAX_RETRIES = 10
    local attempts = 0
    local blocked_names = {}

    while attempts < MAX_RETRIES do
        attempts = attempts + 1

        -- Fetch random wallpaper URL
        local wallpaper_info, err = self:fetchRandomWallpaperURL()
        if not wallpaper_info then
            return
        end

        -- Skip if we already blocked this one in this session
        if blocked_names[wallpaper_info.name] then
            -- Try again
        else
            -- Download to temp file
            local temp_name = "temp_" .. os.time() .. "_" .. math.random(1000) .. ".jpg"
            local temp_path = self.wallpapers_dir .. "/" .. temp_name

            -- Download
            local success, result = self:downloadWallpaper(wallpaper_info.url, temp_path, wallpaper_info.name)

            if success == "BLOCKLIST" then
                -- Resolution too low, wallpaper was blocklisted, try again
                blocked_names[wallpaper_info.name] = true
                -- Try again
            elseif not success then
                return
            else
                -- Remove old wallpaper if exists
                if self.current_wallpaper and self.current_wallpaper ~= temp_path then
                    os.remove(self.current_wallpaper)
                end

                -- Clean up any other files in the directory (previous downloads)
                local cmd = string.format('find "%s" -type f ! -name "%s" -delete 2>/dev/null', self.wallpapers_dir, temp_name)
                os.execute(cmd)

                -- Move new wallpaper to final location
                local final_path = self.wallpapers_dir .. "/" .. wallpaper_info.name
                os.rename(temp_path, final_path)

                -- Set as desktop wallpaper
                self.current_wallpaper = final_path
                hs.screen.mainScreen():desktopImageURL("file://" .. self.current_wallpaper)
                return
            end
        end
    end
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
