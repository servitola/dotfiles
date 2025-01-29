#!/bin/bash

# Function to install extension if not already installed
install_if_missing() {
    local extension="$1"
    if ! windsurf --list-extensions | grep -q "^$extension$"; then
        echo "Installing $extension..."
        windsurf --install-extension "$extension" || echo "Failed to install $extension"
    else
        echo "Extension $extension is already installed"
    fi
}

# Docker & DevOps
install_if_missing "ms-azuretools.vscode-docker"
install_if_missing "ms-kubernetes-tools.vscode-kubernetes-tools"

# Git & Source Control
install_if_missing "eamodio.gitlens"
install_if_missing "mhutchie.git-graph"
install_if_missing "github.vscode-pull-request-github"

# UI/UX & Testing
install_if_missing "hbenl.vscode-test-explorer"
install_if_missing "ms-playwright.playwright"

# General Development
install_if_missing "redhat.vscode-yaml"
install_if_missing "redhat.vscode-xml"
install_if_missing "ms-vscode.powershell"
install_if_missing "streetsidesoftware.code-spell-checker"
install_if_missing "ms-vscode.hexeditor"
install_if_missing "ms-vscode.references-view"
install_if_missing "ms-vscode.makefile-tools"
install_if_missing "ms-vscode.cmake-tools"

# Formatting & Linting
install_if_missing "dbaeumer.vscode-eslint"
install_if_missing "editorconfig.editorconfig"
install_if_missing "davidanson.vscode-markdownlint"
