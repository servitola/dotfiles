---
name: rutracker-download
description: |
  Download a torrent from a rutracker.org topic into the local Transmission.app
  by building a magnet from the topic's infohash and opening it. No login
  required — the actual download uses DHT/PEX, not the rutracker tracker.

  Use when: "скачай с рутрекера", "качни торрент", "rutracker download",
  "скачай рутрекер топик", "поставь на закачку с рутрекера", a rutracker.org
  URL is pasted with intent to download. Also works when the user gives only
  a title ("скачай Морtal Kombat 2") — no URL required.

  Do NOT use for: private trackers that require a passkey, magnet links the
  user already has (just `open` them directly).
---

# rutracker-download

Downloads a torrent into the local Transmission.app GUI. Two entry points:

- **User gives a rutracker URL** → extract infohash from that page (Step 1A).
- **User gives only a title** → Rutracker search requires auth; go straight to
  the 1337x fallback (Step 1B) to get a magnet, then jump to Step 3.

The rest of the flow is identical either way: hand the magnet to Transmission,
verify it landed.

## Step 1A — rutracker URL given: fetch page and extract hash + name

```bash
TOPIC_URL='https://rutracker.org/forum/viewtopic.php?t=6416983'   # or whatever
/usr/bin/curl -s --max-time 15 -A "Mozilla/5.0" "$TOPIC_URL" -o /tmp/rut.html
```

If `curl` times out, report it plainly and stop — don't reach for proxies.

The page is **windows-1251**, not UTF-8. Decode explicitly:

```bash
/usr/bin/python3 - <<'PY'
import re, html
data = open('/tmp/rut.html','rb').read().decode('windows-1251','replace')

m = re.search(r'<h1[^>]*class="maintitle"[^>]*>(.*?)</h1>', data, re.S)
name = html.unescape(re.sub(r'<[^>]+>','',m.group(1))).strip() if m else None

# Infohash is in the page (DOM element with class 'infohash', or in the
# magnet anchor). 40 hex chars.
m = re.search(r'class="\s*med\s+magnet-link[^"]*"[^>]*href="magnet:\?xt=urn:btih:([0-9A-Fa-f]{40})', data)
if not m:
    m = re.search(r'>([0-9A-Fa-f]{40})<', data)
infohash = m.group(1).upper() if m else None

print(name)
print(infohash)
PY
```

If `infohash` is `None`, the page hit the login wall — fall through to
**Step 1B** (1337x fallback) instead of stopping.

## Step 1B — title only (or login wall): 1337x fallback

Rutracker search at `tracker.php?nm=...` returns only service pages for guests
(`IS_GUEST: !!'1'` in the HTML) — **do not waste time trying to search
rutracker without a topic URL**. Go straight to 1337x.

### 1. Find the 1337x collection page via WebSearch

```
WebSearch: rutracker "<title>" <year> torrent topic
```

Or, if that yields nothing, search 1337x directly:

```
WebSearch: site:1377x.to "<title>" <year>
```

Look for a URL like `https://www.1377x.to/movie/NNNNNN/Title-Year/`.

### 2. Fetch the collection page and pick the best release

```bash
/usr/bin/curl -s --max-time 15 -L \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "https://www.1377x.to/movie/NNNNNN/Title-Year/" \
  -o /tmp/1337x_list.html
```

Parse for individual torrent links:

```bash
/usr/bin/python3 - <<'PY'
import re
data = open('/tmp/1337x_list.html','rb').read().decode('utf-8','replace')
links = re.findall(r'href=["\'](/torrent/\d+/[^"\']+)["\']', data)
for l in links[:10]:
    print(l)
PY
```

Prefer **1080p WEBRip/BluRay** over DCPRip (DCPRip files are often 8-10 GB vs
1.5-2 GB for WEBRip). Pick the first matching release.

### 3. Fetch the individual torrent page and extract the magnet

```bash
/usr/bin/curl -s --max-time 15 -L \
  -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36" \
  "https://www.1377x.to/torrent/NNNNNN/Name/" \
  -o /tmp/1337x_t.html
```

```bash
/usr/bin/python3 - <<'PY'
import re
data = open('/tmp/1337x_t.html','rb').read().decode('utf-8','replace')
mg = re.findall(r'magnet:\?[^\s"\'<>]+', data)
print(mg[0] if mg else 'NOT FOUND')
PY
```

Save the magnet to `/tmp/magnet.txt` and jump to **Step 3**.

## Step 2 — build the magnet (rutracker path only)

Use rutracker's four bt trackers with the `?magnet` suffix (their convention for
unauthenticated announces) plus the user-facing name. DHT does the real work,
but having trackers listed lets Transmission show them in the inspector.

```bash
/usr/bin/python3 - <<PY > /tmp/magnet.txt
import urllib.parse
h = "$INFOHASH"
n = """$NAME"""
trs = [f'http://bt{i}.t-ru.org/ann?magnet' if i else 'http://bt.t-ru.org/ann?magnet'
       for i in [0,2,3,4]]
tr = '&'.join('tr=' + urllib.parse.quote(t, safe='') for t in trs)
print(f'magnet:?xt=urn:btih:{h}&dn={urllib.parse.quote(n)}&{tr}')
PY
```

## Step 3 — hand to Transmission

```bash
/usr/bin/open -a Transmission   # ensure GUI is running
/usr/bin/open "$(cat /tmp/magnet.txt)"
```

`MagnetOpenAsk=false` in the user's prefs, so no confirmation dialog.

## Step 4 — verify it landed

Wait ~5 seconds for metadata, then read the transfer list via AppleScript:

```bash
/usr/bin/osascript <<'EOF'
tell application "System Events"
    tell process "Transmission"
        tell window 1
            set out to ""
            repeat with r in rows of outline 1 of scroll area 1
                set txts to value of every static text of UI element 1 of r
                set out to out & (item 1 of txts) & " || " & (item 2 of txts) & " || " & (item 3 of txts) & linefeed
            end repeat
            return out
        end tell
    end tell
end tell
EOF
```

Look for a row containing the expected name with non-zero peer count or known
total size (metadata received). Report progress + ETA to the user in one line.

If after 30 seconds the row says `0 of 0 peers` and 0% — DHT bootstrap is slow.
Wait another 30s before reporting trouble.

## Handling stale state (the trap that bit us once)

Transmission keeps `~/Library/Application Support/Transmission/Resume/*.resume`
and `Transfers.plist` for every torrent ever added. If the user added the same
topic before and the data was deleted from disk, the existing entry shows
**"Error: No data found! ... use 'Verify Local Data'"** and is paused.

**Before adding the magnet**, check for an existing entry with the same hash:

```bash
ls ~/Library/Application\ Support/Transmission/Resume/<HASH-lowercase>.resume 2>/dev/null
```

If it exists, **do not** open the magnet (it would just re-attach to the same
broken row). Instead, in the Transmission UI:

1. Select that specific row (by name match, **not** Select All — Resume All
   will wake up every other "intentionally paused" torrent the user has).
2. Trigger menu `Transfers → Verify Local Data`, wait 2 seconds.
3. Trigger menu `Transfers → Resume Selected`.

AppleScript skeleton (replace `NEEDLE` with a substring of the name):

```bash
/usr/bin/osascript <<'EOF'
tell application "Transmission" to activate
delay 0.5
tell application "System Events"
    tell process "Transmission"
        set frontmost to true
        delay 0.3
        tell window 1
            set rs to rows of outline 1 of scroll area 1
            set idx to 0
            set i to 1
            repeat with r in rs
                set t to (item 1 of (value of every static text of UI element 1 of r)) as text
                if t contains "NEEDLE" then set idx to i
                set i to i + 1
            end repeat
            if idx = 0 then return "not found"
            select row idx of outline 1 of scroll area 1
        end tell
        delay 0.3
        click menu item "Verify Local Data" of menu "Transfers" of menu bar 1
        delay 2
        click menu item "Resume Selected" of menu "Transfers" of menu bar 1
    end tell
end tell
EOF
```

## What this skill does NOT do

- Does **not** log in to rutracker, scrape `dl.php`, or extract Yandex Browser
  cookies. The magnet from the infohash is enough; auth flows are out of scope.
- Does **not** try to search rutracker without a topic URL — the search page
  requires auth and returns only service pages for guests. Use 1337x instead.
- Does **not** Select All + Resume All. That wakes up every paused torrent in
  the queue and surfaces "No data found" errors on unrelated stale rows. Always
  select the specific row by name match.
- Does **not** delete torrents — that's a separate user action.
- Does **not** seed-and-forget — leave Transmission's seeding behavior alone.
  The user manages that themselves.

## Quick reference: where Transmission keeps state

| File | What |
|------|------|
| `~/Library/Application Support/Transmission/Torrents/<hash>.torrent` | torrent metadata |
| `~/Library/Application Support/Transmission/Resume/<hash>.resume` | per-torrent state (bencoded), incl. `paused`, `destination`, `name` |
| `~/Library/Application Support/Transmission/Transfers.plist` | top-level list of all known transfers |
| Pref `DownloadFolder` | completed location (`/Users/servitola/Desktop`) |
| Pref `IncompleteDownloadFolder` | in-progress location (`Users/servitola/Documents/Torrents`) |
| `~/Downloads` | TCC-protected; `ls` from agent shell fails with `Operation not permitted`. Use `mdfind -onlyin ~/Downloads kind:torrent` or `osascript`+Finder if you must inspect it |

## Telling the user what changed

One line, after step 4: name, size, %, MB/s, ETA. If the swarm is dead and DHT
found no peers in 60s, say so explicitly — don't keep watching silently.
