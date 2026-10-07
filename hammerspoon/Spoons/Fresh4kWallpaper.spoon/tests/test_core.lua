local core = require "core"

local source = core.parseSource("AngelJumbo/gruvbox-wallpapers/wallpapers")
eq(source.repo, "AngelJumbo/gruvbox-wallpapers", "source: repo")
eq(source.path, "wallpapers", "source: path")
eq(core.parseSource("Nix3l/wallpapers").path, "", "source: no path")
eq(core.parseSource("a/b/c/d e/").path, "c/d e", "source: deep path, trailing slash dropped")
eq(pcall(core.parseSource, "just-a-name"), false, "source: owner/repo is required")
eq(pcall(core.parseSource, 42), false, "source: must be a string")

local function upper(text) return text:upper() end
eq(core.treeURL("a/b"), "https://api.github.com/repos/a/b/git/trees/HEAD?recursive=1", "tree url")
eq(core.rawURL("a/b", "c d/e.png", upper), "https://raw.githubusercontent.com/a/b/HEAD/C D/E.PNG", "raw url: path goes through the encoder")
eq(core.canonicalRepo("https://api.github.com/repos/Nix3l/wallpapers/git/trees/abc123"), "Nix3l/wallpapers", "canonical repo: from the tree url")
eq(core.canonicalRepo(nil), nil, "canonical repo: no url")
eq(core.cacheName("Nix3l/wallpapers"), "Nix3l__wallpapers.txt", "cache name: one flat file per repo")

local tree = {
    { type = "blob", path = "one.PNG" },
    { type = "blob", path = "wallpapers/anime/_two.jpg" },
    { type = "blob", path = "README.md" },
    { type = "blob", path = "wallpapers/three.webp" },
    { type = "tree", path = "wallpapers/folder.png" },
    { type = "blob", path = ".github/preview.png" },
    { type = "blob", path = "wallpapers/.thumbs/small.jpg" },
}
local images = core.images(tree)
eq(#images, 3, "images: blobs with picture extensions, nothing from hidden folders")
eq(images[2], "wallpapers/anime/_two.jpg", "images: full path kept")
eq(#core.images(nil), 0, "images: no tree")

eq(#core.under(images, ""), 3, "under: empty path is the whole repo")
eq(#core.under(images, "wallpapers"), 2, "under: only that folder")
eq(#core.under({ "wallpapers-old/a.png" }, "wallpapers"), 0, "under: a folder, not a name prefix")
eq(#core.under({ "a+b/c.png" }, "a+b"), 1, "under: the path is plain text, not a pattern")

eq(core.key("wallpapers/anime/_two.jpg"), "two.jpg", "key: file name, leading underscore dropped")
eq(core.key("two.jpg"), "two.jpg", "key: plain")

local fresh = core.unseen(images, { ["two.jpg"] = true, ["three.webp"] = true })
eq(#fresh, 1, "unseen: seen keys removed")
eq(fresh[1], "one.PNG", "unseen: the rest kept")

local text = core.serialize("Nix3l/wallpapers", { "a.png", "b/c d.jpg" })
eq(text, "Nix3l/wallpapers\na.png\nb/c d.jpg\n", "cache: repo on the first line, then paths")
local cache = core.parse(text)
eq(cache.repo, "Nix3l/wallpapers", "cache: repo read back")
eq(#cache.paths, 2, "cache: paths read back")
eq(cache.paths[2], "b/c d.jpg", "cache: path with a space")
eq(core.parse(""), nil, "cache: empty file")
eq(core.parse(nil), nil, "cache: no file")

eq(core.isStale(1000, 1000 + 6 * 86400, 7), false, "stale: six days old, a week allowed")
eq(core.isStale(1000, 1000 + 8 * 86400, 7), true, "stale: eight days old")
eq(core.isStale(nil, 1000, 7), true, "stale: never fetched")

local order = { 1, 2, 3, 4 }
local picks = { 1, 1, 1 }
core.shuffle(order, function() return table.remove(picks, 1) end)
eq(table.concat(order, ""), "2341", "shuffle: Fisher-Yates with the given random")

eq(table.concat(core.tail({ "a", "b", "c" }, 2), ""), "bc", "tail: last two")
eq(table.concat(core.tail({ "a" }, 2), ""), "a", "tail: shorter than the limit")

eq(core.fileName(1700000000, "art/Some Art.PNG"), "Fresh4kWallpaper-1700000000.png", "fileName: timestamp and lowercase extension")
eq(core.isOurs("Fresh4kWallpaper-1700000000.png"), true, "isOurs: our file")
eq(core.isOurs("holiday.png"), false, "isOurs: somebody's picture")
eq(core.isOurs("Fresh4kWallpaper-notes.txt"), false, "isOurs: only the exact shape")
eq(core.isOurs("history.log"), false, "isOurs: state file")

eq(core.is4k(3840, 2160), true, "4k: exactly")
eq(core.is4k(5120, 2880), true, "4k: larger")
eq(core.is4k(3840, 2159), false, "4k: too short")
eq(core.is4k(2560, 2160), false, "4k: too narrow")
eq(core.is4k(nil, nil), false, "4k: unreadable image")

local w, h = core.pixels("  pixelWidth: 3840\n  pixelHeight: 2160\n")
eq(w, 3840, "pixels: width"); eq(h, 2160, "pixels: height")
eq(core.pixels("Error 4: not an image"), nil, "pixels: no numbers")
