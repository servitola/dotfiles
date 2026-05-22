"""Shared regex for parsing 5-column ASCII chord rows in layout/60%/*.lua.

Format: `-- chord │ karabiner │ en | ru | el │ G │ description`
Used by parse_comments and parse_descriptions to avoid duplication.
"""
import re

# Five-column row matcher: chord │ karabiner │ birman │ global │ description
CHORD_ROW = re.compile(
    r'--\s+((?:[⇪⇧⌃⌥⌘]*)(?:[a-zA-Z0-9⇥⎋\[\]←→↑↓,\.;\'/\\`~\-=]|F\d+|num\d+|␣)+)'
    r'\s+│([^│]*)│([^│]*)│[^│]*│\s*(.*?)\s*$'
)

# Full 5-column variant exposing the global column for parse_full_entries
CHORD_ROW_FULL = re.compile(
    r'--\s+((?:[⇪⇧⌃⌥⌘]*)(?:[a-zA-Z0-9⇥⎋\[\]←→↑↓,\.;\'/\\`~\-=]|F\d+|num\d+|␣)+)'
    r'(?:\s*→\s*[^\s│]+)?'
    r'\s+│([^│]*)│([^│]*)│([^│]*)│\s*(.*?)\s*$'
)

# Description-row variant (used by parse_descriptions): same as CHORD_ROW but
# captures the karabiner column position separately so descriptions can be
# extracted from continuation rows.
CHORD_ROW_DESC = re.compile(
    r'--\s+((?:[⇪⇧⌃⌥⌘]*)(?:[a-zA-Z0-9⇥⎋\[\]←→↑↓,\.;\'/\\`~\-=]|F\d+|num\d+|␣)+)'
    r'\s+│[^│]*│[^│]*│[^│]*│\s*(.*?)\s*$'
)
