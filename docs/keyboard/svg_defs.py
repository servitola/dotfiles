"""SVG <defs> block: filters, styles, category icons."""
from colors import PALETTE

_APPLE = ('M11.182.008C11.148-.03 9.923.023 8.857 1.18c-1.066 1.156-.902 2.482-.878 '
    '2.516s1.52.087 2.475-1.258.762-2.391.728-2.43m3.314 11.733c-.048-.096-2.325-1.234'
    '-2.113-3.422s1.675-2.789 1.698-2.854-.597-.79-1.254-1.157a3.7 3.7 0 0 0-1.563-.43'
    '4c-.108-.003-.483-.095-1.254.116-.508.139-1.653.589-1.968.607-.316.018-1.256-.522-2'
    '.267-.665-.647-.125-1.333.131-1.824.328-.49.196-1.422.754-2.074 2.237-.652 1.482-.3'
    '11 3.83-.067 4.56s.625 1.924 1.273 2.796c.576.984 1.34 1.667 1.659 1.899s1.219.386'
    ' 1.843.067c.502-.308 1.408-.485 1.766-.472.357.013 1.061.154 1.782.539.571.197 1.11'
    '1.115 1.652-.105.541-.221 1.324-1.059 2.238-2.758q.52-1.185.473-1.282')


def svg_defs():
    return f'''<defs>
  <filter id="shadow" x="-4%" y="-4%" width="108%" height="116%">
    <feDropShadow dx="0" dy="1" stdDeviation="2" flood-color="#000" flood-opacity="0.07"/></filter>
  <filter id="shadow-bound" x="-4%" y="-4%" width="108%" height="116%">
    <feDropShadow dx="0" dy="1.5" stdDeviation="2.5" flood-color="#000" flood-opacity="0.12"/></filter>
  <symbol id="apple" viewBox="0 0 16 16"><path d="{_APPLE}"/></symbol>
  <symbol id="win-icon" viewBox="0 0 16 16">
    <rect x="1" y="2" width="9" height="7" rx="1" fill="none" stroke-width="1.3"/>
    <rect x="6" y="7" width="9" height="7" rx="1" fill="none" stroke-width="1.3"/></symbol>
  <symbol id="audio-icon" viewBox="0 0 16 16">
    <path d="M7 3L3.5 6H1v4h2.5L7 13V3z" stroke-width="1.2" fill="none"/>
    <path d="M10 5.5a3 3 0 010 5M12 3.5a6 6 0 010 9" fill="none" stroke-width="1.2"/></symbol>
  <symbol id="birman" viewBox="0 0 16 16">
    <rect x="1" y="3" width="14" height="10" rx="2" fill="none" stroke-width="1"/>
    <text x="8" y="11.5" text-anchor="middle" font-size="8" font-weight="600">Б</text></symbol>
  <style>
    text {{ font-family: -apple-system, "SF Pro Text", "Helvetica Neue", sans-serif;
           fill: {PALETTE["text"]}; }}
    .key-label {{ font-size: 9px; fill: {PALETTE["text_dim"]}; }}
    .bind-label {{ font-size: 10px; font-weight: 500; }}
    .title {{ font-size: 18px; font-weight: 600; fill: {PALETTE["text"]}; }}
    .legend-text {{ font-size: 10px; fill: {PALETTE["text"]}; }}
  </style>
</defs>'''
