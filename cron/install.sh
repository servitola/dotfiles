#!/bin/bash
# Usage: cron/install.sh [--print]
# Merges environment.cron with every .cron fragment under $DIR_CRON_JOBS and
# installs the result as the user's crontab; --print only shows the result.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${HERE}/environment.cron"
JOBS_DIR="${DIR_CRON_JOBS:?set DIR_CRON_JOBS in constants.env (see cron/AGENTS.md)}"
# find's error inside the process substitution below would be swallowed, and an
# empty crontab installed in place of the real one.
[[ -d "${JOBS_DIR}" ]] || { echo "no ${JOBS_DIR}: clone the cron repository there first" >&2; exit 1; }

merge_cron_files() {
    cat "${ENV_FILE}"
    echo ""
    # Sort fragments by basename, not path, so a theme subfolder never
    # changes the merge order.
    {
        while IFS= read -r -d '' file; do
            printf '%s\t%s\n' "$(basename "${file}")" "${file}"
        done < <(find "${JOBS_DIR}" -name '*.cron' -print0)
    } | LC_ALL=en_US.UTF-8 sort | while IFS=$'\t' read -r _ file; do
        cat "${file}"
        echo ""
    done
}

if [[ "${1:-}" == "--print" ]]; then
    merge_cron_files
    exit 0
fi

merge_cron_files | crontab -
echo "✓ crontab installed from ${JOBS_DIR}"
