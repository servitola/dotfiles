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

## Run tests

    uv run --with yt-dlp --with pytest python -m pytest tests/ -v

## Known limitations

- No subtitles (site uses a custom in-page dictionary widget, not plain
  `.vtt`/`.srt`).
