#!/bin/bash
# =============================================================================
# Crontab Merger Script
# =============================================================================
# Usage: ./init-cron-jobs.sh
# Merges all .cron files and installs them to crontab
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/environment.cron"
CRON_DIR="${SCRIPT_DIR}/cron_jobs"
PRIVATE_CRON_DIR="${DOTFILES_PRIVATE:-$HOME/projects/dotfiles_private}/cron/cron_jobs"

# Merge all .cron files: environment first, then cron_jobs alphabetically
merge_cron_files() {
    # Process environment.cron first
    if [[ -f "${ENV_FILE}" ]]; then
        cat "${ENV_FILE}"
        echo ""
    fi

    # Collect fragments from both dirs, sort by basename, then cat in order
    {
        for file in "${CRON_DIR}"/*.cron "${PRIVATE_CRON_DIR}"/*.cron; do
            [[ -f "${file}" ]] && printf '%s\t%s\n' "$(basename "${file}")" "${file}"
        done
    } | LC_ALL=en_US.UTF-8 sort | while IFS=$'\t' read -r _ file; do
        cat "${file}"
        echo ""  # Add blank line between files
    done
}

# Install merged crontab
merge_cron_files | crontab -
echo "✓ Crontab installed successfully"
