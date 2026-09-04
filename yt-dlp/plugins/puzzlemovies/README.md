# puzzle-movies.com yt-dlp plugin

Personal-use yt-dlp plugin for downloading from puzzle-movies.com (requires an active paid subscription to browse the catalog, but the plugin itself does not need cookies)

**This is private. Do not publish or share this plugin.**

## Install

Lives at `$DOTFILES/yt-dlp/plugins/puzzlemovies` and is symlinked to
`~/.config/yt-dlp/plugins/puzzlemovies` by `install/07-config-links.sh` —
already wired up as part of the normal dotfiles install (`up`). No manual
step needed.

## Usage

    # one episode
    yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1e2"

    # one season
    yt-dlp "https://puzzle-movies.com/the-mentalist#the-mentalist-s1"

    # whole series
    yt-dlp "https://puzzle-movies.com/the-mentalist"

    # a film
    yt-dlp "https://puzzle-movies.com/films/only-the-brave-2017"

Films and series are separate records with separate CDN layouts, and the
`/films/` prefix is what tells them apart — `/films/the-mentalist` is a movie
(id 2322), `/the-mentalist` the series. The extractor confirms the page it got
by reading `var media_type` before choosing a layout:

    series: /<bucket>/series/video/<slug>/s<S>e<E>/video_hd.mp4/master.m3u8
    films:  /<bucket>/movies/<slug>/video_hd.mp4/master.m3u8

Films come in one quality only (720p HD); there is no `video_sd` sibling.

## Run tests

    uv run --with yt-dlp --with pytest python -m pytest tests/ -v

## Known limitations

- No subtitles (site uses a custom in-page dictionary widget, not plain
  `.vtt`/`.srt`).
