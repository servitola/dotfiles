#!/bin/bash

current_branch=$(git symbolic-ref --short HEAD)

if [ "$current_branch" = "Development" ]; then
    echo "Already on Development branch. Nothing to rebase."
    exit 0
fi

echo "Fetching latest changes..."
git fetch origin

echo "Stashing any uncommitted changes..."
git stash

echo "Updating Development branch..."
git checkout Development
git pull origin Development

echo "Checking out back to $current_branch..."
git checkout "$current_branch"

echo "Rebasing $current_branch onto Development..."
git rebase Development

if [ "$(git stash list)" != "" ]; then
    echo "Restoring stashed changes..."
    git stash pop
fi

echo "Rebase complete! Current branch '$current_branch' is now based on latest Development."
