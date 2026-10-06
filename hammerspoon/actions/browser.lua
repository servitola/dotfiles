local browserSearch = require("actions.lib.browser_search")

return function(register)
    local function tab(pattern, url, options)
        return function() spoon.BrowserTabOpener:open(pattern, url, options) end
    end
    register("browser_git", tab("github.com", "https://github.com"))
    register("browser_git_dotfiles", tab("github.com/servitola/dotfiles", "https://github.com/servitola/dotfiles"))
    register("browser_youtube", tab("youtube.com", "https://youtube.com"))
    register("browser_youtube_playing", tab("youtube.com/watch", "https://youtube.com", { prefer = spoon.BrowserTabOpener.videoPlaying }))
    register("browser_search_selected", function() browserSearch.searchSelectedText() end)
end
