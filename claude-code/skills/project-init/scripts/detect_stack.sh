#!/usr/bin/env bash
# Detect which language stacks live in a project directory, by manifest files
# first (authoritative) and source-file extensions second (fallback for a bare
# proof-of-concept with no build file yet). Prints one stack token per line:
#   python typescript javascript dotnet kotlin swift go rust
# Usage: detect_stack.sh [DIR]   (defaults to .)
set -euo pipefail

ROOT="${1:-.}"
declare -a found=()

has() { [[ -n "$(find "$ROOT" -maxdepth 3 -name "$1" -not -path '*/node_modules/*' -not -path '*/.git/*' -print -quit 2>/dev/null)" ]]; }
ext() { [[ -n "$(find "$ROOT" -maxdepth 4 -name "$1" -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' -print -quit 2>/dev/null)" ]]; }
add() { found+=("$1"); }

# --- manifests (authoritative) ---
{ has pyproject.toml || has setup.py || has requirements.txt; } && add python
{ has tsconfig.json || has "*.ts" && ext "*.ts"; } && add typescript
{ has package.json && ! has tsconfig.json; } && add javascript
{ has "*.csproj" || has "*.sln" || has "*.fsproj" || has Directory.Build.props; } && add dotnet
{ has build.gradle.kts || has build.gradle || has settings.gradle.kts; } && add kotlin
{ has Package.swift || has "*.xcodeproj" || has "*.xcworkspace"; } && add swift
has go.mod && add go
has Cargo.toml && add rust

# --- extension fallback (bare PoC without a manifest) ---
if [[ ${#found[@]} -eq 0 ]]; then
    ext "*.py"    && add python
    ext "*.tsx"   && add typescript
    ext "*.ts"    && add typescript
    ext "*.jsx"   && add javascript
    ext "*.js"    && add javascript
    ext "*.cs"    && add dotnet
    ext "*.kt"    && add kotlin
    ext "*.swift" && add swift
    ext "*.go"    && add go
    ext "*.rs"    && add rust
fi

# de-dupe, preserving order
printf '%s\n' "${found[@]}" | awk '!seen[$0]++'
