---
name: audiobook-download
description: |
  Finds and downloads free, legally available audiobooks — public-domain
  recordings from LibriVox and the Internet Archive — via curl + jq, no
  API key needed. Saves into /Volumes/SanDisk/Audiobooks/ (syncs to
  phone) when mounted, else the current topic folder, and sends the
  file(s) via the bot MCP `send_document`. Does not touch piracy sites
  that host copyrighted commercial audiobooks without a license — that's
  out of scope.

  Use when: "скачай аудиокнигу", "найди бесплатную аудиокнигу", "скачай
  книгу в аудио", "где послушать книгу бесплатно", "хочу аудиокнигу",
  "download an audiobook", "find a free audiobook", "get me the audio
  version of [book]"
---

# Audiobook Download

Downloads audiobooks that are actually free to distribute: public-domain
works read by volunteers (LibriVox) or hosted with permission on the
Internet Archive. Both are queryable with plain `curl` + `jq` — no
account, no key.

This skill will not scrape sites that redistribute copyrighted commercial
audiobooks without a license — that's piracy, not "free," and creates
legal exposure for whoever hosts and shares the file. If a requested book
is a modern bestseller still under copyright, read
[legal-sources.md](references/legal-sources.md) for library-lending and
other legitimate free routes to offer instead.

## Workflow

1. **Search the Internet Archive.** LibriVox uploads every recording to
   archive.org already split into chapter-level MP3s, so one API covers
   search + file listing:

   ```bash
   curl -s "https://archive.org/advancedsearch.php?q=title:(BOOK+TITLE)+AND+collection:(librivoxaudio)&fl[]=identifier&fl[]=title&fl[]=creator&fl[]=downloads&rows=10&output=json" \
     | jq '.response.docs'
   ```

   No hits in `librivoxaudio`? Broaden to any public-domain audio item:

   ```bash
   curl -s "https://archive.org/advancedsearch.php?q=title:(BOOK+TITLE)+AND+mediatype:(audio)&fl[]=identifier&fl[]=title&fl[]=creator&fl[]=downloads&rows=10&output=json" \
     | jq '.response.docs'
   ```

   Pick the best match by title/creator; if several editions/readers show
   up, prefer the one with the highest `downloads` and confirm with the
   user if it's ambiguous.

2. **List the item's files** with the Metadata API:

   ```bash
   curl -s "https://archive.org/metadata/${IDENTIFIER}" \
     | jq '.files[] | select(.name | test("_64kb\\.mp3$|\\.m4b$")) | {name, format, size}'
   ```

   You'll typically see a single-file `.m4b` (whole book, chapters
   embedded) and a set of per-chapter `_64kb.mp3` files (smallest
   bitrate offered — pick these over the plain/`_128kb` MP3s or `.ogg`).

3. **Download.** Telegram documents cap around 50 MB — check `size`
   first. The `.m4b` is usually way over that for a full-length book, so
   default to per-chapter 64kbps MP3s:

   ```bash
   curl -sL "https://archive.org/download/${IDENTIFIER}/${FILENAME}" -o "${FILENAME}"
   ```

   Where to save: if `/Volumes/SanDisk/Audiobooks/` is mounted (check
   with `ls` first), save there in a `Автор - Название/` subfolder,
   matching the existing library's naming convention — that drive syncs
   to the user's phone. If it's not mounted, fall back to the current
   topic folder and say so, so the user knows to move the files later.

4. **Send the file(s)** via the bot MCP `send_document`, one message per
   file, regardless of where they were saved — so the user has an
   immediate copy in chat even before the drive syncs. For multi-chapter
   books, send a short caption first (title, author, reader, chapter
   count) so the user knows what's coming, then the files.

5. **Not found anywhere on archive.org** (usually means it's still under
   copyright, e.g. a recent bestseller) → tell the user directly that
   there's no legal free copy, and offer the library-lending and other
   legitimate options from [legal-sources.md](references/legal-sources.md)
   instead.

## Notes

- No auth, no rate-limit headers documented for either endpoint — keep
  request volume reasonable (a handful of calls per search, not loops).
- `advancedsearch.php` treats spaces in `q` as AND between terms inside
  the parens; wrap multi-word titles/authors in parens as shown above.
- Non-English public-domain audiobooks exist on archive.org too, but
  coverage is thin outside English — a `creator:(Tolstoy)` search mostly
  returns English/French/Spanish translations, with only a handful of
  actual Russian-language recordings. Check the item's language/title
  before downloading, and set expectations with the user accordingly:
  classic authors dead 70+ years may have a Russian recording, but often
  don't, and living/modern authors won't have one anywhere legally.
- If the user just wants to browse rather than have Claude fetch a
  specific title, [legal-sources.md](references/legal-sources.md) also
  lists sites worth pointing them to directly.
