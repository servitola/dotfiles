"""SVG <defs>: Apple Magic Keyboard aesthetic + media/android symbols."""
from colors import PALETTE as P

_APPLE = ('M11.182.008C11.148-.03 9.923.023 8.857 1.18c-1.066 1.156-.902 2.482-.878 '
    '2.516s1.52.087 2.475-1.258.762-2.391.728-2.43m3.314 11.733c-.048-.096-2.325-1.234'
    '-2.113-3.422s1.675-2.789 1.698-2.854-.597-.79-1.254-1.157a3.7 3.7 0 0 0-1.563-.43'
    '4c-.108-.003-.483-.095-1.254.116-.508.139-1.653.589-1.968.607-.316.018-1.256-.522-2'
    '.267-.665-.647-.125-1.333.131-1.824.328-.49.196-1.422.754-2.074 2.237-.652 1.482-.3'
    '11 3.83-.067 4.56s.625 1.924 1.273 2.796c.576.984 1.34 1.667 1.659 1.899s1.219.386'
    ' 1.843.067c.502-.308 1.408-.485 1.766-.472.357.013 1.061.154 1.782.539.571.197 1.11'
    '1.115 1.652-.105.541-.221 1.324-1.059 2.238-2.758q.52-1.185.473-1.282')
_SPK = 'M7 3L3.5 6H1v4h2.5L7 13V3z'  # speaker base path

def svg_defs():
    return f'''<defs>
  <filter id="shadow" x="-6%" y="-6%" width="112%" height="120%">
    <feDropShadow dx="0" dy="0.5" stdDeviation="1" flood-color="#000" flood-opacity="0.06"/></filter>
  <filter id="shadow-bound" x="-6%" y="-6%" width="112%" height="120%">
    <feDropShadow dx="0" dy="0.5" stdDeviation="1.5" flood-color="#000" flood-opacity="0.08"/>
    <feDropShadow dx="0" dy="2" stdDeviation="4" flood-color="#000" flood-opacity="0.03"/></filter>
  <filter id="shadow-card" x="-4%" y="-4%" width="108%" height="116%">
    <feDropShadow dx="0" dy="1" stdDeviation="6" flood-color="#000" flood-opacity="0.06"/></filter>
  <symbol id="apple" viewBox="0 0 16 16"><path d="{_APPLE}"/></symbol>
  <symbol id="win-icon" viewBox="0 0 16 16"><rect x="1" y="2" width="9" height="7" rx="1" fill="none" stroke-width="1.3"/>
    <rect x="6" y="7" width="9" height="7" rx="1" fill="none" stroke-width="1.3"/></symbol>
  <symbol id="birman" viewBox="0 0 16 16"><rect x="1" y="3" width="14" height="10" rx="2" fill="none" stroke-width="1"/>
    <text x="8" y="11.5" text-anchor="middle" font-size="8" font-weight="600">Б</text></symbol>
  <symbol id="vol-up" viewBox="0 0 16 16"><path d="{_SPK}" fill="none" stroke-width="1.2"/><path d="M10 5.5a3 3 0 010 5M12.5 3a7 7 0 010 10" fill="none" stroke-width="1.1"/></symbol>
  <symbol id="vol-dn" viewBox="0 0 16 16"><path d="{_SPK}" fill="none" stroke-width="1.2"/><path d="M10 6a2.5 2.5 0 010 4" fill="none" stroke-width="1.2"/></symbol>
  <symbol id="track-prev" viewBox="0 0 16 16"><rect x="1" y="4" width="1.5" height="8" rx=".5"/><polygon points="4,8 11,3.5 11,12.5"/></symbol>
  <symbol id="track-next" viewBox="0 0 16 16"><polygon points="5,3.5 5,12.5 12,8"/><rect x="13.5" y="4" width="1.5" height="8" rx=".5"/></symbol>
  <symbol id="play-pause" viewBox="0 0 16 16"><polygon points="1,3 1,13 7,8"/><rect x="9" y="3" width="2.5" height="10" rx=".5"/><rect x="13" y="3" width="2.5" height="10" rx=".5"/></symbol>
  <symbol id="android" viewBox="0 0 16 16"><rect x="3" y="7" width="10" height="7" rx="2"/><circle cx="6" cy="10" r="1"/><circle cx="10" cy="10" r="1"/>
    <line x1="5" y1="3.5" x2="3.5" y2="6" stroke-width="1.2" stroke-linecap="round"/><line x1="11" y1="3.5" x2="12.5" y2="6" stroke-width="1.2" stroke-linecap="round"/></symbol>
  <symbol id="arr-up" viewBox="0 0 24 24"><path d="M12 4L4 14h5v6h6v-6h5z"/></symbol>
  <symbol id="arr-dn" viewBox="0 0 24 24"><path d="M12 20L4 10h5V4h6v6h5z"/></symbol>
  <symbol id="arr-l" viewBox="0 0 24 24"><path d="M4 12L14 4v5h6v6h-6v5z"/></symbol>
  <symbol id="arr-r" viewBox="0 0 24 24"><path d="M20 12L10 4v5H4v6h6v5z"/></symbol>
  <style>
    text {{ font-family: -apple-system, "SF Pro Display", system-ui, sans-serif; fill: {P["text"]}; }}
    .key-label {{ font-size: 8px; fill: {P["key_text_dim"]}; letter-spacing: 0.02em; }}
    .bind-label {{ font-size: 10px; font-weight: 500; letter-spacing: -0.01em; }}
    .title {{ font-size: 15px; font-weight: 600; fill: {P["text"]}; letter-spacing: -0.01em; }}
    .legend-text {{ font-size: 10px; fill: {P["text_dim"]}; font-weight: 400; }}
    .key-group {{ cursor: default; }}
    .key-group:hover > rect:first-child {{ stroke: #007aff !important; stroke-width: 1.5px !important; }}
    .key-tip {{ transition: opacity 0.15s ease; }}
    .key-group:hover .key-tip {{ opacity: 1 !important; pointer-events: auto !important; }}
  </style>
</defs>'''
