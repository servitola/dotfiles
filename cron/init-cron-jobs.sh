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

# Merge all .cron files: environment first, then cron_jobs alphabetically
merge_cron_files() {
    # Process environment.cron first
    if [[ -f "${ENV_FILE}" ]]; then
        cat "${ENV_FILE}"
        echo ""
    fi

    # Then process all .cron files in cron_jobs alphabetically
    for file in "${CRON_DIR}"/*.cron; do
        if [[ -f "${file}" ]]; then
            cat "${file}"
            echo ""  # Add blank line between files
        fi
    done
}

# Install merged crontab
merge_cron_files | crontab -
echo "✓ Crontab installed successfully"
