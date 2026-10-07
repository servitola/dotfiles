# Changelog

## 0.2.0

- No GitHub token needed: the file list of a collection is fetched once and cached for `cacheDays` (7), so a change makes no API request. Before, every change made two or three.
- A picture is picked from the whole collection, not from one random category.
- A renamed repository keeps working; `Nix3l/gruvbox-bgs` is `Nix3l/wallpapers` now.

## 0.1.0

First release. Random 4K wallpaper from GitHub collections on every start and once a day; history, a blocklist for small pictures, one file on disk.
