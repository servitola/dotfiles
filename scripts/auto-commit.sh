#!/bin/bash

# Auto-commit script for dotfiles
# This script watches the dotfiles directory for changes and automatically commits them

DOTFILES_DIR="/Users/servitola/projects/dotfiles"
LOG_FILE="$DOTFILES_DIR/scripts/auto-commit.log"

# Function to log messages
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Function to commit changes
commit_changes() {
    cd "$DOTFILES_DIR" || exit 1
    
    # Check if there are any changes
    if [[ -n $(git status --porcelain) ]]; then
        # Add all changes
        git add .
        
        # Create a commit message with timestamp and changed files
        changed_files=$(git diff --cached --name-only | head -5 | tr '\n' ' ')
        if [[ ${#changed_files} -gt 100 ]]; then
            commit_msg="Auto-commit: Updated multiple files at $(date '+%Y-%m-%d %H:%M:%S')"
        else
            commit_msg="Auto-commit: Updated $changed_files at $(date '+%Y-%m-%d %H:%M:%S')"
        fi
        
        # Commit the changes
        if git commit -m "$commit_msg"; then
            log_message "Successfully committed changes: $commit_msg"
        else
            log_message "Failed to commit changes"
        fi
    else
        log_message "No changes detected, skipping commit"
    fi
}

# Function to handle cleanup on script exit
cleanup() {
    log_message "Auto-commit script stopped"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

log_message "Starting auto-commit watcher for $DOTFILES_DIR"

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null; then
    log_message "ERROR: fswatch is not installed. Please install it with: brew install fswatch"
    exit 1
fi

# Watch for file changes and commit them
# Exclude .git directory, log files, and other temporary files
fswatch \
    --exclude='\.git/' \
    --exclude='\.DS_Store' \
    --exclude='\.log$' \
    --exclude='scripts/auto-commit\.log' \
    --one-per-batch \
    --latency=2 \
    "$DOTFILES_DIR" | while read -r event; do
    
    log_message "File change detected: $event"
    
    # Wait a moment for any additional writes to complete
    sleep 1
    
    # Commit the changes
    commit_changes
done