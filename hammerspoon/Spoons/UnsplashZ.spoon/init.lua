local obj={}

user_agent_str = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_5) AppleWebKit/603.2.4 (KHTML, like Gecko) Version/10.1.1 Safari/603.2.4"
url = [[ /usr/bin/curl 'https://source.unsplash.com/1792x1120/?nature' |  perl -ne ' print "$1" if /href="([^"]+)"/ ' ]]

local function curl_callback(exitCode, stdOut)
    if exitCode == 0 then
        local localpath = os.getenv("HOME") .. "/.Trash/" .. hs.http.urlParts(obj.pic_url).lastPathComponent
        hs.screen.mainScreen():desktopImageURL("file://" .. localpath)
    end
end

function obj:init()
    obj.pic_url = hs.execute(url)
    local localpath = os.getenv("HOME") .. "/.Trash/" .. hs.http.urlParts(obj.pic_url).lastPathComponent
    hs.task.new("/usr/bin/curl", curl_callback, {"-A", user_agent_str, obj.pic_url, "-o", localpath})
        :start()
end

return obj
