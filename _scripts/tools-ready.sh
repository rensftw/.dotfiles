#!/usr/bin/env bash

if command -v lolcat >/dev/null 2>&1; then
    lolcat --spread=1.0 _scripts/ascii/tools-ready-ascii.txt
else
    cat _scripts/ascii/tools-ready-ascii.txt
fi
