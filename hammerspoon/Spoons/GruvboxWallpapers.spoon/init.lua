--- === GruvboxWallpapers ===
---
--- Set random wallpaper from gruvbox collection daily
---

local obj = {}
obj.__index = obj

obj.wallpapers_dir = os.getenv("HOME") .. "/projects/gruvbox-wallpapers/wallpapers/irl"
obj.current_wallpaper = nil

function obj:getWallpapers()
    local files = {}
    local dir = io.popen('ls "' .. self.wallpapers_dir .. '"/*.{jpg,jpeg,png,JPG,JPEG,PNG} 2>/dev/null')
    if dir then
        for file in dir:lines() do
            table.insert(files, file)
        end
        dir:close()
    end
    return files
end

function obj:setRandomWallpaper()
    local wallpapers = self:getWallpapers()
    if #wallpapers > 0 then
        local new_wallpaper
        repeat
            new_wallpaper = wallpapers[math.random(#wallpapers)]
        until new_wallpaper ~= self.current_wallpaper or #wallpapers == 1

        self.current_wallpaper = new_wallpaper
        hs.screen.mainScreen():desktopImageURL("file://" .. self.current_wallpaper)
    end
end

function obj:init()
    math.randomseed(os.time())
    self:setRandomWallpaper()
    if self.timer then
        self.timer:stop()
    end
    self.timer = hs.timer.doEvery(24*60*60, function() self:setRandomWallpaper() end)
end

return obj
