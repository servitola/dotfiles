#!/bin/bash
# Pre-commit shell lint, dispatched by dialect (shellcheck can't parse zsh):
#   #!...zsh shebang        → zsh -n        (syntax check; no zsh linter exists)
#   #!...sh/bash/dash/ksh   → shellcheck    (warnings and above)
#   no shebang              → zsh -n        (sourced zsh fragment: aliases.sh etc.)
#   other interpreter       → skipped       (python scripts in zsh/bin, etc.)
#
# Receives staged filenames from pre-commit. Kept /bin/bash-3.2-compatible.
set -o pipefail

rc=0
for f in "$@"; do
    [ -f "$f" ] || continue              # deleted / broken symlink — skip
    first_line=$(head -n 1 "$f")
    case "$first_line" in
        '#!'*zsh*) zsh -n "$f" || rc=1 ;;
        '#!'*sh*)  shellcheck --severity=warning "$f" || rc=1 ;;
        '#!'*)     ;;
        *)         zsh -n "$f" || rc=1 ;;
    esac
done
exit $rc
