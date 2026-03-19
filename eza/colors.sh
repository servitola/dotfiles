#!/bin/zsh
# Gruvbox Dark colors for eza (per-extension overrides, theme.yml handles the rest)
export EZA_COLORS="
*.md=93:    # markdown files (yellow)
*.yml=33:   # yaml files
*.json=33:  # json files
*.sh=32:    # shell scripts (green)
*.rs=31:    # rust files (red)
*.py=34:    # python files (blue)
*.js=33:    # javascript files (yellow)
*.ts=34:    # typescript files (blue)
*.jsx=33:   # react files
*.tsx=34:   # react typescript files
*.css=36:   # css files (cyan)
*.html=33:  # html files
*.zip=35:   # zip files (magenta)
*.tar=35:   # tar files
*.gz=35:    # gzip files
*.7z=35:    # 7z files
"
