#!/usr/bin/env bash

current=$(git rev-parse --abbrev-ref HEAD)
git switch Development && git merge --no-ff "$current"
