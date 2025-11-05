#!/bin/bash
if [ -f "$1" ]; then
    cat "$@" | pbcopy
fi
