#!/bin/zsh
#
# Fetch and display random ASCII art from asciiartfarts.com
#
# Usage: Just run the script

echo

curl -s "http://www.asciiartfarts.com/random.cgi" |
    sed -n '/<pre>/,/<\/pre>/p' |
    sed 's/<[^>]*>//g' |
    sed "s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g; s/&quot;/\"/g; s/&#39;/'/g; s/&nbsp;/ /g" |
    sed '/^$/d' |
    tail -n +7
