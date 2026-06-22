#!/usr/bin/env bash

if command -v figlet >/dev/null 2>&1 && command -v lolcat >/dev/null 2>&1; then
    figlet -f 'big' 'Bye!' | lolcat --spread '1.0'
else
    printf '%s\n' 'Bye!'
fi
