---
name: gif-search
description: |
  Search and download GIFs via curl + jq (KLIPY primary, GIPHY fallback).

  Use when: "найди гифку", "скачай gif", "поищи реакшн-гифку", "find a gif", "search a reaction gif", "download a gif"
---

# GIF Search

Search and download GIFs from the terminal via curl + jq.

> **Tenor is dead.** Google deprecated the Tenor GIF API on 2026-01-13 (no new
> keys) with full shutdown 2026-06-30. This skill uses **KLIPY** (free lifetime
> tier, Tenor-compatible, what WhatsApp moved to) as primary, with **GIPHY**
> (free beta key, 100 req/hour) as a fallback.

## Prerequisites

- `curl` and `jq` (standard on macOS/Linux)
- At least one free API key in `~/.config/openai_key.sh`:
  ```bash
  export KLIPY_API_KEY=...   # primary — get it at https://klipy.com/developers
  export GIPHY_API_KEY=...   # fallback — get a beta key at https://developers.giphy.com
  ```
- Prefer KLIPY (lifetime free, no rate cap on the free tier). Use GIPHY only if
  KLIPY isn't set up — its beta key is limited to 100 calls/hour.

## KLIPY (primary)

Base URL: `https://api.klipy.com/api/v1/${KLIPY_API_KEY}/` — the key goes in the
**path**, not a header/query.

```bash
# Search → full-size (HD) GIF URLs  [verified path]
curl -s "https://api.klipy.com/api/v1/${KLIPY_API_KEY}/gifs/search?q=thumbs+up&per_page=5&page=1" \
  | jq -r '.data.data[].file.hd.gif.url'

# Small preview GIFs (lighter for chat) — sm, fall back to xs
curl -s "https://api.klipy.com/api/v1/${KLIPY_API_KEY}/gifs/search?q=nice+work&per_page=3" \
  | jq -r '.data.data[].file.sm.gif.url // .data.data[].file.xs.gif.url'

# Trending
curl -s "https://api.klipy.com/api/v1/${KLIPY_API_KEY}/gifs/trending?per_page=5" \
  | jq -r '.data.data[].file.hd.gif.url'
```

Response shape (confirmed): results live under `.data.data[]`; each item has
`.file.<size>.<format>.url` where **size** ∈ `hd | md | sm | xs` and **format**
∈ `gif | webp | jpg | mp4 | webm` (note: size comes before format). `result:true`
at the top level means the call succeeded.

Params: `q` (URL-encode spaces as `+`), `per_page`, `page`, `customer_id` (optional, for personalization).

## GIPHY (fallback — stable, well-documented)

Base URL: `https://api.giphy.com/v1/gifs` — key as `api_key` query param.

```bash
# Search → full-size GIF URLs
curl -s "https://api.giphy.com/v1/gifs/search?api_key=${GIPHY_API_KEY}&q=thumbs+up&limit=5" \
  | jq -r '.data[].images.original.url'

# Small/preview versions (lighter for chat)
curl -s "https://api.giphy.com/v1/gifs/search?api_key=${GIPHY_API_KEY}&q=nice+work&limit=3" \
  | jq -r '.data[].images.fixed_height_small.url'

# Trending
curl -s "https://api.giphy.com/v1/gifs/trending?api_key=${GIPHY_API_KEY}&limit=5" \
  | jq -r '.data[].images.original.url'
```

Params: `q`, `limit` (default 25), `rating` (`g`/`pg`/`pg-13`/`r`), `lang` (`en`/`es`/`ru`/...).

GIPHY image variants under `.data[].images.*`: `original`, `fixed_height_small`
(preview), `downsized` (smaller), `preview_gif` (tiny). Each has a `.url`.

## Download a GIF

```bash
# KLIPY
URL=$(curl -s "https://api.klipy.com/api/v1/${KLIPY_API_KEY}/gifs/search?q=celebration&per_page=1" | jq -r '.data.data[0].file.hd.gif.url')
# or GIPHY
URL=$(curl -s "https://api.giphy.com/v1/gifs/search?api_key=${GIPHY_API_KEY}&q=celebration&limit=1" | jq -r '.data[0].images.original.url')

curl -sL "$URL" -o celebration.gif
```

## Notes

- URL-encode queries: spaces as `+`, special chars as `%XX`.
- For sending in chat, prefer the small/preview variants (lighter).
- GIF URLs work directly in markdown: `![alt](url)`.
- Other Tenor-compatible options if needed later: KLIPY also serves stickers,
  memes, and short clips on the same key.
