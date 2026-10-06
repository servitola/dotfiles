return function(register)
    register("musicapp.play_pause", function() hs.itunes.playpause() end)
    register("youtube_stream", function() spoon.YouTubeStream:toggle() end)
end
