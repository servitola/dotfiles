#!/bin/zsh
# Bind file types to apps via LaunchServices. Applies after the next login.
set -e
echo 'Setting default applications'

python3 <<'PYEOF'
import os, plistlib, subprocess, sys, time

HANDLERS = {
    'com.microsoft.VSCode': {  # VS Code
        'utis': ['com.netscape.javascript-source', 'net.daringfireball.markdown', 'public.css', 'public.json', 'public.php-script', 'public.plain-text', 'public.python-script', 'public.ruby-script', 'public.shell-script', 'public.source-code', 'public.text', 'public.unix-executable', 'public.xml'],
        'exts': ['applescript', 'c', 'conf', 'config', 'cpp', 'css', 'csv', 'h', 'hpp',
                 'ini', 'java', 'js', 'json', 'key', 'log', 'm', 'markdown', 'md', 'php',
                 'pl', 'plist', 'proto', 'py', 'r', 'rb', 'sh', 'svg', 'swift', 'toml', 'ts',
                 'tsv', 'tsx', 'txt', 'xml', 'yaml', 'yml', 'zsh', 'keylayout', 'patch',
                 'html', 'mjs', 'cfg', 'mk', 'diff', 'mm', 'metal', 'mod', 'strings',
                 'entitlements', 'storyboard', 'pem', 'crt', 'asc', 'bashrc', 'bat', 'bib',
                 'cake', 'coffee', 'dart', 'dat', 'eslintrc', 'gitconfig', 'gitignore', 'go',
                 'gradle', 'hs', 'jl', 'jsx', 'kt', 'kts', 'less', 'lock', 'lua', 'mdx',
                 'phpt', 'pom', 'prettierrc', 'properties', 'rs', 'sass', 'scss', 'srt',
                 'stub', 'tex', 'tf', 'vue', 'v', 'wkt', 'wxml', 'wxss', 'zshrc', 'settings',
                 'opml', 'cron', 'cs', 'csproj', 'props', 'resx', 'runsettings',
                 'dotsettings', 'xaml', 'cmake', 'env', 'jsonl', 'groovy', 'ps1', 'cu',
                 'cuh', 'nix', 'sum', 'ipynb'],
    },
    'com.colliderli.iina': {  # IINA
        'utis': ['public.audio', 'public.movie'],
        'exts': ['3gp', 'avi', 'flac', 'flv', 'm4a', 'm4v', 'mka', 'mkv', 'mov', 'mp3',
                 'mpeg', 'mpg', 'mp4', 'ogg', 'ogm', 'ogv', 'opus', 'wav', 'webm', 'wmv',
                 'aac', 'aif', 'mid', 'mks'],
    },
    'cc.ffitch.shottr': {  # Shottr
        'utis': ['public.image'],
        'exts': ['bmp', 'gif', 'jpg', 'jpeg', 'png', 'tif', 'tiff', 'heic', 'avif', 'ico',
                 'icns'],
    },
    'com.apple.Preview': {
        'utis': [],
        'exts': ['pdf'],
    },
    'com.apple.Pages': {
        'utis': [],
        'exts': ['doc', 'docx'],
    },
    'com.firmshell.djvureader': {  # DjVu Reader
        'utis': [],
        'exts': ['djvu'],
    },
    'com.apple.iBooksX': {  # Books
        'utis': [],
        'exts': ['epub'],
    },
    'com.jetbrains.rider': {  # Rider
        'utis': [],
        'exts': ['sln', 'slnx'],
    },
    'com.ableton.live': {  # Ableton Live
        'utis': [],
        'exts': ['alp', 'als'],
    },
}

# A handler pointing at a bundle id no app carries is worse than no handler:
# LaunchServices falls back to whatever else claims the type, and Finder starts
# asking which app to use. So an absent app is skipped, not fatal: a fresh Mac
# with only the minimum brewfile has most of them missing, and the next
# `make` after installing one binds it.
def installed_bundle_ids():
    ids = set()
    for root in ('/Applications', '/System/Applications', os.path.expanduser('~/Applications')):
        for dirpath, dirnames, _ in os.walk(root):
            for d in list(dirnames):
                if not d.endswith('.app'):
                    continue
                dirnames.remove(d)
                try:
                    with open(os.path.join(dirpath, d, 'Contents', 'Info.plist'), 'rb') as fh:
                        bid = plistlib.load(fh).get('CFBundleIdentifier')
                except Exception:
                    continue
                if bid:
                    ids.add(bid.lower())
    return ids

present = installed_bundle_ids()
unknown = [app for app in HANDLERS if app.lower() not in present]
if unknown:
    print(f'  skipped, not installed: {", ".join(unknown)}')
    for app in unknown:
        del HANDLERS[app]

DOMAIN = 'com.apple.LaunchServices/com.apple.launchservices.secure'
prefs = plistlib.loads(subprocess.run(['defaults', 'export', DOMAIN, '-'],
                                      capture_output=True, check=True).stdout)
lshandlers = prefs.setdefault('LSHandlers', [])

by_uti = {e['LSHandlerContentType']: e for e in lshandlers if 'LSHandlerContentType' in e}
by_ext = {e['LSHandlerContentTag']: e for e in lshandlers
          if e.get('LSHandlerContentTagClass') == 'public.filename-extension'}
stamp = int(time.time() - 978307200)   # LaunchServices epoch is 2001-01-01
added = retargeted = unchanged = 0
taken_by = {}   # app that had grabbed a binding -> how many

def bind(index, key, template, app):
    global added, retargeted, unchanged
    entry = index.get(key)
    if entry is None:
        entry = {**template, 'LSHandlerRoleAll': app,
                 'LSHandlerPreferredVersions': {'LSHandlerRoleAll': '-'},
                 'LSHandlerModificationDate': stamp}
        lshandlers.append(entry); index[key] = entry
        added += 1
    # LaunchServices lowercases the ids it writes back, so 'com.microsoft.vscode'
    # already is 'com.microsoft.VSCode'.
    elif entry.get('LSHandlerRoleAll', '').lower() != app.lower():
        previous = entry.get('LSHandlerRoleAll', '?')
        taken_by[previous] = taken_by.get(previous, 0) + 1
        entry['LSHandlerRoleAll'] = app
        entry['LSHandlerModificationDate'] = stamp
        retargeted += 1
    else:
        unchanged += 1

for app, types in HANDLERS.items():
    for uti in types['utis']:
        bind(by_uti, uti, {'LSHandlerContentType': uti}, app)
    for ext in types['exts']:
        bind(by_ext, ext, {'LSHandlerContentTag': ext,
                           'LSHandlerContentTagClass': 'public.filename-extension'}, app)

if added or retargeted:
    # Through cfprefsd — it holds this domain in memory and flushes its own copy
    # over a raw write to the .plist, silently dropping what was just added.
    subprocess.run(['defaults', 'import', DOMAIN, '-'],
                   input=plistlib.dumps(prefs), check=True)
print(f'  added {added}, retargeted {retargeted}, unchanged {unchanged}')
for previous, count in sorted(taken_by.items(), key=lambda item: -item[1]):
    print(f'    {count} taken back from {previous}')
PYEOF

echo '  done (applies after next login)'
