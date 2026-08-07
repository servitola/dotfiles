#!/usr/bin/env bash
# PostToolUse(Edit|Write|MultiEdit): type-check the file that was just written.
# Reads the hook payload on stdin.
FILE=$(jq -r '.tool_input.file_path')

if [[ $FILE == *.go ]]; then
    cd "$(git rev-parse --show-toplevel)" && go vet ./...
elif [[ $FILE == *.ts ]]; then
    rtk tsc --noEmit
fi
