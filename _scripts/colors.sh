#!/usr/bin/env bash

# Plain ANSI escape codes for colors.
# Keep this file cheap to source; it is loaded during interactive zsh startup.
RED_BACKGROUND=$'\033[41;30m'
CYAN_BACKGROUND=$'\033[46;30m'
MAGENTA_BACKGROUND=$'\033[45;30m'
YELLOW_BACKGROUND=$'\033[43;30m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
CYAN=$'\033[36m'
MAGENTA=$'\033[35m'
BOLD=$'\033[1m'
NORMAL=$'\033[0m'
NC=$'\033[0m'

export RED_BACKGROUND
export CYAN_BACKGROUND
export MAGENTA_BACKGROUND
export YELLOW_BACKGROUND
export RED
export YELLOW
export GREEN
export CYAN
export MAGENTA
export BOLD
export NORMAL
export NC
