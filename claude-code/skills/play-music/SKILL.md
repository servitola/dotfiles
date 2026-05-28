---
name: play-music
description: |
  Play music on macOS in Apple Music (Music.app) via AppleScript: find a
  song/album by lyric, title, or artist; play it from the user's library;
  fall back to the Apple Music store search if missing. Also pause/resume,
  skip, set volume.

  The user is on Apple Music — never open Spotify, YouTube, or web players
  for music requests unless they explicitly ask.

  Use when: "включи песню", "поставь песню", "включи музыку", "включи альбом",
  "поставь <artist>", "play song", "play music", "play album", "pause music",
  "следующий трек", "next track", "сделай погромче", "volume up", a lyric
  fragment is quoted with "включи" / "поставь" / "play".
---

# Play Music

Default music app is **Music.app** (Apple Music). Drive it via AppleScript through `osascript`. Never substitute Spotify or a web player.

## Identifying the track

The user often gives a lyric ("где курт кобейн поет but I don't have a gun"), an artist + vague title, or just a title. Resolve to `artist` + `track title` before searching:

- Lyric → recall the song from training knowledge (Nirvana — "Come As You Are").
- Ambiguous title → pick the most likely match for the named artist.
- Unknown lyric → ask the user, don't guess wildly.

Then search the library first; fall back to Apple Music store search only if absent.

## Play from library (preferred)

Use `every track of playlist "Library" whose name contains … and artist contains …` — this is the only reliable AppleScript filter. Title and artist matches are case-insensitive and substring-based, so use the shortest unambiguous fragment.

**Default to the canonical studio version.** Unless the user explicitly asks for a remix / live / demo / dub / edit / instrumental / acoustic version, filter those out. The Library often has 10+ variants of the same song and `item 1` is frequently a remix from an EP.

```bash
osascript <<'EOF'
tell application "Music"
  activate
  set candidates to (every track of playlist "Library" whose name contains "Come As You Are" and artist contains "Nirvana")
  set chosen to missing value
  repeat with t in candidates
    set nm to name of t
    set al to album of t
    if nm does not contain "Remix" and nm does not contain "remix" and nm does not contain "Mix" and nm does not contain "Dub" and nm does not contain "Edit" and nm does not contain "Version" and nm does not contain "Live" and nm does not contain "Demo" and nm does not contain "Instrumental" and nm does not contain "Acoustic" and nm does not contain "Reprise" and al does not contain "Remix" and al does not contain "Remixes" and al does not contain "Demo" and al does not contain "Live" then
      set chosen to t
      exit repeat
    end if
  end repeat
  if chosen is missing value and (count of candidates) > 0 then
    set chosen to item 1 of candidates
  end if
  if chosen is not missing value then
    play chosen
    return "Playing: " & (name of chosen) & " — " & (artist of chosen) & " [" & (album of chosen) & "]"
  else
    return "NOT_IN_LIBRARY"
  end if
end tell
EOF
```

Returns the played track on success, the literal string `NOT_IN_LIBRARY` otherwise. Branch on that.

If the user explicitly asks for a specific variant ("включи ремикс gesaffelstein", "поставь акустику"), invert the filter — match on that keyword instead of excluding it.

### Why this works
- `playlist "Library"` is the catch-all playlist that always exists.
- `play t` queues *and* plays — no separate `start` call.
- `activate` brings Music.app forward (some Macs won't start playback if it's frozen in background).

### Multiple matches
The Library has multiple copies (live, remaster, compilation) — `item 1` is usually the canonical studio track, but if the user complains, list candidates:

```applescript
repeat with t in foundTracks
  log (name of t) & " — " & (artist of t) & " [" & (album of t) & "]"
end repeat
```

## Play an album

```bash
osascript <<'EOF'
tell application "Music"
  activate
  set albumTracks to (every track of playlist "Library" whose album contains "Nevermind" and artist contains "Nirvana")
  if (count of albumTracks) > 0 then
    play (item 1 of albumTracks)
    return "Playing album: Nevermind — Nirvana"
  else
    return "NOT_IN_LIBRARY"
  end if
end tell
EOF
```

Music will continue to the next album track automatically when "Up Next" is empty.

## Fallback: Apple Music store search

If `NOT_IN_LIBRARY`, open the in-app search (not the web). The `music://` URL scheme launches Music.app directly:

```bash
open "music://music.apple.com/search?term=Nirvana%20Come%20As%20You%20Are"
```

Tell the user the track isn't in their library and that you opened the store search — they tap the result to play. Don't attempt to subscribe / purchase / download on their behalf.

## Playback control

All idempotent — safe to call regardless of current state.

```bash
osascript -e 'tell application "Music" to playpause'   # toggle
osascript -e 'tell application "Music" to pause'
osascript -e 'tell application "Music" to play'        # resume current track
osascript -e 'tell application "Music" to next track'
osascript -e 'tell application "Music" to previous track'
```

Get current track (useful when the user asks "что играет?"):

```bash
osascript -e 'tell application "Music"
  if player state is playing then
    return (name of current track) & " — " & (artist of current track)
  else
    return "not playing"
  end if
end tell'
```

## Volume

Music has its own app-level volume (0–100), separate from system volume.

```bash
osascript -e 'tell application "Music" to set sound volume to 70'
osascript -e 'tell application "Music" to get sound volume'
```

For system-wide volume (the user might mean either — ask if ambiguous):

```bash
osascript -e 'set volume output volume 70'
```

## Reporting back

One short line: what's playing (track — artist), or what changed (paused, volume 70, next track). If you fell back to store search, say so explicitly so the user knows to tap. Don't paste the AppleScript unless asked.
