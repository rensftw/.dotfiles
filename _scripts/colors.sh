#!/usr/bin/env bash

# Tput escape codes for colors
RED_BACKGROUND=$(tput setab 1; tput setaf 0)
CYAN_BACKGROUND=$(tput setab 6; tput setaf 0)
MAGENTA_BACKGROUND=$(tput setab 5; tput setaf 0)
YELLOW_BACKGROUND=$(tput setab 3; tput setaf 0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
MAGENTA=$(tput setaf 5)
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
NC=$(tput sgr0)

export RED_BACKGROUND
export CYAN_BACKGROUND
export MAGENTA_BACKGROUND
export YELLOW_BACKGROUND
export RED
export GREEN
export CYAN
export MAGENTA
export BOLD
export NORMAL
export NC
